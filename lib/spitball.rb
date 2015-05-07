require 'fileutils'
require 'tempfile'
require 'digest/md5'
require 'ext/bundler_lockfile_parser'
require 'ext/bundler_fake_dsl'
require 'sem_ver'

$pwd = Dir.pwd

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

  def self.gem_cmd
    ENV['GEM_CMD'] || 'gem'
  end

  PROTOCOL_VERSION = '1'
  PROTOCOL_HEADER = "X-Spitball-Protocol"
  WITHOUT_HEADER = "X-Spitball-Without"
  BUNDLE_CONFIG_ENV = 'BUNDLE_CONFIG'

  include Spitball::Digest
  include Spitball::ClientCommon

  attr_reader :gemfile, :gemfile_lock, :without, :options

  def initialize(gemfile, gemfile_lock, options = {})
    Spitball::Repo.make_cache_dirs
    @gemfile      = gemfile
    @gemfile_lock = gemfile_lock
    @options      = options
    @without      = options[:without].is_a?(Enumerable) ? options[:without].map(&:to_sym) : (options[:without] ? [options[:without].to_sym] : [])
    @parsed_lockfile, @dsl = Bundler::FakeLockfileParser.new(gemfile_lock), Bundler::FakeDsl.new(gemfile)

    use_bundle_config(options[:bundle_config]) if options[:bundle_config]

    raise "You need to run bundle install before you can use spitball" unless (@parsed_lockfile.dependencies.map{|d| d.name}.uniq.sort == @dsl.__gem_names.uniq.sort)
    @groups_to_install = @dsl.__groups.keys - @without
  end

  def use_bundle_config(bundle_config)
    tempfile = Tempfile.new('bundle_config')
    File.open(tempfile.path, 'w') { |f| f.write options[:bundle_config] }
    original_config_path = ENV[BUNDLE_CONFIG_ENV]
    ENV[BUNDLE_CONFIG_ENV] = tempfile.path
    @bundle_config = Bundler::Settings.new
    tempfile.close
    ENV[BUNDLE_CONFIG_ENV] = original_config_path
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
      @dsl.__gem_names.each do |spec|
        spec_name = spec
        if @groups_to_install.any?{|group| @dsl.__groups[group].include?(spec_name)}
          if found_spec = @parsed_lockfile.specs.find {|spec| spec.name == spec_name}
            install_gem(found_spec)
          elsif spec_name == 'bundler'
            install_and_copy_spec(spec_name, '>= 0')
          else
            raise "Cannot install #{spec * ' '}"
          end
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
    install_and_copy_spec(spec.name, spec.version)
    spec.dependencies.each do |dep|
      spec_name = dep.name
      if found_spec = @parsed_lockfile.specs.find {|spec| spec.name == spec_name}
        install_gem(found_spec)
      elsif spec_name == 'bundler'
        install_and_copy_spec(dep.name, dep.requirements_list.first || '> 0')
      else
        raise "Cannot install #{dep.inspect}"
      end
    end
  end

  def install_and_copy_spec(name, version)
    build_args = @bundle_config["build.#{name}"] if @bundle_config
    cache_dir = File.join(Repo.gemcache_path, "#{name}-#{::Digest::MD5.hexdigest([name, version, sources_opt(@parsed_lockfile.sources), build_args].join('/'))}")
    unless File.exist?(cache_dir)
      FileUtils.mkdir_p(cache_dir)
      out = ""
      Dir.chdir($pwd) do
        out = `#{Spitball.gem_cmd} install #{name} -v'#{version}' --no-rdoc --no-ri --ignore-dependencies -i#{cache_dir} #{sources_opt(@parsed_lockfile.sources)} #{generate_build_args(build_args)} 2>&1`
      end
      if $? == 0
        puts out
      else
        FileUtils.rm_rf(cache_dir)
        raise BundleCreationFailure, out
      end
    else
      puts "Using cached version of #{name} (#{version})"
    end
    `cp -R #{cache_dir}/* #{bundle_path}`
  end

  def generate_build_args(build_args)
    build_args ? "-- #{build_args}" : ''
  end

  def sources_opt(sources)
    Array(ENV['SOURCE_OVERRIDE'] ||
      sources.
        map{|s| s.remotes}.flatten.
        map{|s| s.to_s}.
        sort.
        map{|s| %w{gemcutter rubygems rubyforge}.include?(s) ? "http://rubygems.org" : s}).
        map{|s| "--source #{s}"}.
        map{|s| "#{"--clear-sources " if SemVer.parse(Gem::VERSION) >= SemVer.parse('1.4.0') }#{s}"}.
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
