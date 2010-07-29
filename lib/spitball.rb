require 'fileutils'

class Spitball
  require 'spitball/digest'
  require 'spitball/repo'
  require 'spitball/file_lock'
  require 'spitball/remote'

  class SpitballServerFailure < StandardError; end
  class SpitballClientFailure < StandardError; end
  class BundleCreationFailure < StandardError; end

  VERSION = '1.0'

  include Spitball::Digest
  include Spitball::FileLock

  attr_reader :gemfile, :options

  def initialize(gemfile, options = {})
    @gemfile = gemfile
    @options = options
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
    FileUtils.mkdir_p bundle_path

    File.open(gemfile_path, 'w') {|f| f.write gemfile }

    if system "cd #{bundle_path} && bundle install #{bundle_path} --disable-shared-gems #{without_clause}"
      system "tar czf #{tarball_path}.#{Process.pid} -C #{bundle_path} ."
      system "mv #{tarball_path}.#{Process.pid} #{tarball_path}"
    else
      raise BundleCreationFailure, "Bundle build failure."
    end

    FileUtils.rm_rf bundle_path
  end

  def without_clause
    without = Array(options[:without] || [])
    return '' if without.empty?

    "--without=#{without.join(',')}"
  end

  # Paths

  def bundle_path(extension = nil)
    Repo.path(digest, extension)
  end

  def gemfile_path
    File.expand_path('Gemfile', bundle_path)
  end

  def tarball_path
    Repo.path(digest, 'tgz')
  end
end
