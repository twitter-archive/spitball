module Spitball::Repo
  extend self

  WORKING_DIR = ENV['SPITBALL_CACHE'] || '/tmp/spitball'

  def bundle_path(digest, extension = nil)
    extension = ".#{extension}" unless extension.nil? or extension.empty?
    File.join WORKING_DIR, "bundle_#{digest}#{extension}"
  end

  def gemcache_path
    File.join(WORKING_DIR, "gemcache")
  end

  def exist?(digest)
    File.exist? tarball(digest)
  end

  def tarball(digest)
    bundle_path(digest, 'tgz')
  end

  def cached_digests
    Dir[File.join(WORKING_DIR, 'bundle_*.tgz')].map do |path|
      path.match(/bundle_(.*?)\.tgz$/)[1]
    end.compact.uniq.sort
  end

  def make_cache_dirs
    FileUtils.mkdir_p File.join(WORKING_DIR, "gemcache")
  end

  def clean_up_unused(access_window)
    cutoff_time = Time.now - access_window

    cached_digests.each do |digest|
      stat = File.stat(tarball(digest))
      access_time = [stat.atime, stat.mtime].max

      if access_time < cutoff_time
        File.unlink(tarball(digest)) if File.exist? tarball(digest)
        File.unlink(gemfile(digest)) if File.exist? gemfile(digest)
      end
    end
  end
end
