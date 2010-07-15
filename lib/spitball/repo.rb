module Spitball::Repo
  extend self

  WORKING_DIR = ENV['SPITBALL_DIR'] || '/tmp/spitball'

  def path(digest, extension = nil)
    extension = ".#{extension}" unless extension.nil? or extension.empty?
    File.join WORKING_DIR, "bundle_#{digest}#{extension}"
  end

  def exist?(digest)
    File.exist? path(digest, 'tgz')
  end

  def gemfile(digest)
    File.read path(digest, 'gemfile')
  end

  def list_cached
    Dir[File.join(WORKING_DIR, 'bundle_*.tgz')].map do |path|
      path.match(/^bundle_.*?\.tgz$/)[1] rescue nil
    end.compact.uniq.sort
  end

  def make_cache_dir
    FileUtils.mkdir_p WORKING_DIR
  end
end
