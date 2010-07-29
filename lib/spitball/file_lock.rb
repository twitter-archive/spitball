require 'fileutils'

class Spitball::FileLock

  attr_reader :path

  def initialize(path)
    @path = path
  end

  def acquire_lock

    File.open(pre_lock_path, 'w') {|f| f.write Process.pid }

    system "ln #{pre_lock_path} #{path} > /dev/null 2>&1"
    File.read(path).to_i == Process.pid
  ensure
    FileUtils.rm_f pre_lock_path
  end

  # seems silly to lock to release lock
  def release_lock
    FileUtils.rm_f path if acquire_lock
  end

  private

  def pre_lock_path
    "#{path}_pre_#{Process.pid}"
  end
end
