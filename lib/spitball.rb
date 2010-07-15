require 'fileutils'

class Spitball
  require 'spitball/digest'
  require 'spitball/repo'
  require 'spitball/file_lock'
  require 'spitball/remote'

  VERSION = '1.0'

  include Spitball::Digest
  include Spitball::FileLock

  attr_reader :gemfile

  def initialize(gemfile)
    @gemfile = gemfile
  end

  def copy_to(dest)
    cache!
    FileUtils.cp(tarball_path, dest)
  end

  def cached?
    File.exist? tarball_path
  end

  def cache!(sync = true)
    Spitball::Repo.make_cache_dir

    unless cached?
      if acquire_lock bundle_path('lock')
        begin
          create_bundle
        ensure
          release_lock bundle_path('lock')
        end
      elsif sync
        sleep 0.1 until cached?
      end
    end
  end

  def create_bundle
    File.open(gemfile_path, 'w') {|f| f.write gemfile }
    FileUtils.mkdir_p bundle_path

    if system "bundle install #{bundle_path} --gemfile=#{gemfile_path} --disable-shared-gems > /dev/null"
      FileUtils.rm_rf File.join(bundle_path, "cache")

      system "tar czf #{tarball_path}.#{Process.pid} -C #{bundle_path} ."
      system "mv #{tarball_path}.#{Process.pid} #{tarball_path}"

    else
      FileUtils.rm_rf gemfile_path
      raise "Bundle build failure."
    end

    FileUtils.rm_rf bundle_path
  end

  # Paths

  def bundle_path(extension = nil)
    Repo.path(digest, extension)
  end

  def gemfile_path
    Repo.path(digest, 'gemfile')
  end

  def tarball_path
    Repo.path(digest, 'tgz')
  end
end
