require 'fileutils'
require 'digest/md5'
require 'ext/bundler_lockfile_parser'
require 'ext/bundler_fake_dsl'

class Spitball
  require 'spitball/client_common'
  require 'spitball/digest'
  require 'spitball/repo'
  require 'spitball/file_lock'
  require 'spitball/remote'
  require 'spitball/version'

  class ServerFailure < StandardError; end
  class ClientError < StandardError; end
  class BundleCreationFailure < StandardError; end

  PROTOCOL_VERSION = '1'
  PROTOCOL_HEADER = "X-Spitball-Protocol"
  WITHOUT_HEADER = "X-Spitball-Without"

  include Spitball::Digest
  include Spitball::ClientCommon

  attr_reader :gemfile, :gemfile_lock, :without, :options

  def initialize(gemfile, gemfile_lock, options = {})
    Spitball::Repo.make_cache_dirs
    @gemfile      = gemfile
    @gemfile_lock = gemfile_lock
    @options      = options
    @without      = (options[:without] || []).map{|w| w.to_sym}
    @parsed_lockfile, @dsl = Bundler::FakeLockfileParser.new(gemfile_lock), Bundler::FakeDsl.new(gemfile)
    raise "You need to run bundle install before you can use spitball" unless (@parsed_lockfile.dependencies.map{|d| d.name}.uniq.sort == @dsl.__gem_names.uniq.sort)
    @groups_to_install = @dsl.__groups.keys - @without
  end

  def cached?
    File.exist? tarball_path
  end

  def cache!(sync = true)
    return if cached?
    lock = Spitball::FileLock.new(bundle_path('lock'))
    if lock.acquire_lock
      begin
       create_bundle
      ensure
        lock.release_lock
      end
    elsif sync
      sleep 0.1 until cached?
    end
  end

  private

  def copy_tarball_data(dest)
    cache!
    FileUtils.cp(tarball_path, dest)
  end

  def create_bundle
    Spitball::Repo.make_cache_dirs
    FileUtils.mkdir_p bundle_path

    # save gemfile and lock file for future reference.
    File.open(gemfile_path, 'w') {|f| f.write gemfile }
    File.open(gemfile_lock_path, 'w') {|f| f.write gemfile_lock }

    Dir.chdir(Repo.gemcache_path) do
      @dsl.__gem_names.each do |spec_name|
        if @groups_to_install.any?{|group| @dsl.__groups[group].include?(spec_name)}
          install_gem(@parsed_lockfile.specs.find {|spec| spec.name == spec_name})
        end
      end
    end

    Dir.chdir(bundle_path) do
      Dir["#{bundle_path}/bin/**"].each do |file|
        contents = File.read(file)
        contents.gsub!(/^#!.*?\n/, "#!/usr/bin/env ruby\n")
        File.open(file, 'w') {|f| f << contents}
      end
    end

    system "rm -rf #{bundle_path}/cache"
    system "tar czf #{tarball_path}.#{Process.pid} -C #{bundle_path} ."
    system "mv #{tarball_path}.#{Process.pid} #{tarball_path}"
    FileUtils.rm_rf bundle_path
  end

  def install_gem(spec)
    install_and_copy_spec(spec)
    spec.dependencies.each do |dep|
      install_gem(@parsed_lockfile.specs.find {|spec| spec.name == dep.name})
    end
  end

  def gem_cmd
    ENV['GEM_CMD'] || 'cmd'
  end

  def install_and_copy_spec(spec)
    cache_dir = File.join(Repo.gemcache_path, "#{spec.name}-#{::Digest::MD5.hexdigest([spec.name, spec.version, sources_opt(@parsed_lockfile.sources)].join('/'))}")
    unless File.exist?(cache_dir)
      FileUtils.mkdir_p(cache_dir)
      out = `#{gem_cmd} install #{spec.name} -v'#{spec.version}' --no-rdoc --no-ri --ignore-dependencies -i#{cache_dir} #{sources_opt(@parsed_lockfile.sources)} 2>&1`
      if $? == 0
        puts out
      else
        FileUtils.rm_rf(cache_dir)
        raise BundleCreationFailure, out
      end
    else
      puts "Using cached version of #{spec.name} (#{spec.version})"
    end
    `cp -R #{cache_dir}/* #{bundle_path}`
  end

  def sources_opt(sources)
    sources.
      map{|s| s.remotes}.flatten.
      map{|s| s.to_s}.
      sort.
      map{|s| %w{gemcutter rubygems rubyforge}.include?(s) ? "http://rubygems.org" : s}.
      map{|s| "--source #{s}"}.
      join(' ')
  end

  # Paths

  def bundle_path(extension = nil)
    Repo.bundle_path(digest, extension)
  end

  def gemfile_lock_path
    File.expand_path('Gemfile.lock', bundle_path)
  end

  def gemfile_path
    File.expand_path('Gemfile', bundle_path)
  end

  def tarball_path
    Repo.bundle_path(digest, 'tgz')
  end
end