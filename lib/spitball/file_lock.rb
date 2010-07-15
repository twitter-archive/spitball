require 'fileutils'

module Spitball::FileLock
  def acquire_lock(lock_path)
    pre_lock_path = "#{lock_path}_pre_#{Process.pid}"

    File.open(pre_lock_path, 'w') {|f| f.write Process.pid }

    # is this atomic?
    system "mv -n #{pre_lock_path} #{lock_path}"
    File.read(lock_path).to_i == Process.pid
  ensure
    FileUtils.rm_f pre_lock_path
  end

  # seems silly to lock to release lock
  def release_lock(lock_path)
    FileUtils.rm_f lock_path if acquire_lock lock_path
  end
end
