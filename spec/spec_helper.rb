SPEC_DIR = File.dirname(__FILE__)

SPITBALL_CACHE = ENV['SPITBALL_CACHE'] = File.expand_path('cache', SPEC_DIR)

$: << File.expand_path("../lib", SPEC_DIR)

require 'rubygems'
require 'fileutils'
require 'spec'
require 'spitball'


Spec::Runner.configure do |config|
  config.mock_with :rr
  config.before do
    purge_test_cache
  end

  config.after :all do
    purge_test_cache
  end
end


# helper methods

def purge_test_cache
  FileUtils.rm_rf SPITBALL_CACHE
end
