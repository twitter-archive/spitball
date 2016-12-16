SPEC_DIR = File.dirname(__FILE__)

SPEC_BIN_PATH = File.expand_path('bin', SPEC_DIR)

SPITBALL_CACHE = ENV['SPITBALL_CACHE'] = File.expand_path('cache', SPEC_DIR)

ENV['PATH'] = [SPEC_BIN_PATH, ENV['PATH']].join(':') unless ENV['PATH'].include? SPEC_BIN_PATH

$: << File.expand_path("../lib", SPEC_DIR)

require 'rubygems'
require 'fileutils'
require 'spitball'
require 'phocus'

RSpec.configure do |config|
  config.mock_with :rspec
  config.before do
    purge_test_cache
    purge_bin
  end

  config.after :all do
    purge_test_cache
    purge_bin
  end
end


# helper methods

def capture_stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = STDOUT
end

def purge_test_cache
  FileUtils.rm_rf SPITBALL_CACHE
end

def make_bundler
  bundle_path = File.expand_path('bundle', SPEC_BIN_PATH)
  FileUtils.mkdir_p SPEC_BIN_PATH
  File.open(bundle_path, 'w') { |f| yield f }
  FileUtils.chmod(0755, bundle_path)
end

def use_success_bundler
  make_bundler do |f|
    f.puts "#!/bin/sh"
    f.puts "mkdir -p $2/gems"
    f.puts "echo WIN > $2/gems/gem"
  end
end

def purge_bin
  FileUtils.rm_rf File.expand_path('bin', SPEC_DIR)
end
