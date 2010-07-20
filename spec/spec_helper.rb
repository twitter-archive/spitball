require 'rubygems'
require 'fileutils'
require 'spec'

spec_dir = File.dirname(__FILE__)

ENV['SPITBALL_CACHE'] = File.expand_path('cache', spec_dir)

$: << File.expand_path("../lib", spec_dir)

Spec::Runner.configure do |config|
  config.mock_with :rr
  config.before do
    purge_test_cache
  end

  config.after :all do
    purge_test_cache
  end
end

def purge_test_cache
  FileUtils.rm_rf ENV['SPITBALL_CACHE']
end
