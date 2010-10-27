require 'fileutils'
require 'bundler'

class Spitball
  require 'spitball/digest'
  require 'spitball/repo'
  require 'spitball/file_lock'
  require 'spitball/remote'

  class ServerFailure < StandardError; end
  class ClientError < StandardError; end
  class BundleCreationFailure < StandardError; end

  VERSION = '1.0'

  include Spitball::Digest

  attr_reader :gemfile, :gemfile_lock, :without, :options

  def initialize(gemfile, gemfile_lock, options = {})
    @gemfile      = gemfile
    @gemfile_lock = gemfile_lock
    @options      = options
    @without      = options[:without] || ''
  end

  def copy_to(dest)
    cache!
    FileUtils.cp(tarball_path, dest)
  end

  def cached?
    File.exist? tarball_path
  end

  def cache!(sync = true)
    Spitball::Repo.make_cache_dirs
    unless cached?
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
  end

  def create_bundle
    Spitball::Repo.make_cache_dirs
    FileUtils.mkdir_p bundle_path
    definition = nil
    Dir.chdir(bundle_path) {
      File.open(gemfile_path, 'w') {|f| f.write gemfile }
      File.open(gemfile_lock_path, 'w') {|f| f.write gemfile_lock }
      Bundler.settings.without = without.split(/\s*,\s*/).map{|w| w.to_sym}
      definition = Bundler.definition(true)
    }

    Dir.chdir(Repo.gemcache_path) do
      definition.requested_specs.each do |spec|
        install_gem(spec)
      end
      `cp -nR #{bundle_path}/cache/*.gem .` unless Dir["#{bundle_path}/cache/*.gem"].to_a.empty?
    end

    Dir.chdir(bundle_path) do
      File.open(gemfile_path, 'w') {|f| f.write gemfile }
      File.open(gemfile_lock_path, 'w') {|f| f.write gemfile_lock }

      # rewrite bang lines to #!/usr/bin/env ruby
      # in serious lameness, OS X sed (more posix compliant?) requires
      # a slightly different sed incantation for in place editing
      if Dir["#{bundle_path}/bin/*"].length > 0
        if RUBY_PLATFORM =~ /linux/
          `find bin/* -exec sed -i'' '1,1 s|^#!/.*/ruby[ ]*|#!/usr/bin/env ruby|' {} \\;`
        else
          `find bin/* -exec sed -i '' '1,1 s|^#!/.*/ruby[ ]*|#!/usr/bin/env ruby|' {} \\;`
        end
      end
    end

    system "tar czf #{tarball_path}.#{Process.pid} -C #{bundle_path} ."
    system "mv #{tarball_path}.#{Process.pid} #{tarball_path}"
    FileUtils.rm_rf bundle_path
  end

  def install_gem(spec)
    puts `gem install #{spec.name} -v'#{spec.version}' --no-rdoc --no-ri --ignore-dependencies -i#{bundle_path}`
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
