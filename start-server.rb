#!/usr/bin/env ruby

prefix = File.expand_path(File.dirname(__FILE__))
shared_prefix = "/usr/local/spitball/shared"

spitball_pidfile = ENV['SPITBALL_PIDFILE'] || "#{shared_prefix}/server.pid"

if File.exist?(spitball_pidfile)
  begin
    old_pid = Integer(File.read(spitball_pidfile).strip)
    Process.kill("KILL", old_pid)
    Process.wait(old_pid)
  rescue Errno::ESRCH
    puts "Error killing #{old_pid} -> #{$!.message}"
  end
  File.unlink(spitball_pidfile)
end
pid = fork {
  cmd = "SOURCE_OVERRIDE=http://gems.local.twitter.com GEM_CMD=/opt/local/bin/gem GEM_PATH=#{prefix}/vendor PATH=#{prefix}/bin:#{prefix}/vendor/bin:#{prefix}/../shared/ruby/bin:$PATH SPITBALL_CACHE=#{shared_prefix}/cache ruby -rubygems -Ilib bin/spitball-server -p 1134 >> '#{shared_prefix}/spitball.log' 2>&1"
  exec(cmd)
}
File.open(spitball_pidfile, 'w') { |f| f << pid }
puts "Spitball started on #{pid}!"
Process.detach(pid)