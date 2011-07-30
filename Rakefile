ROOT_DIR = File.expand_path(File.dirname(__FILE__))
VERSION_FILE = File.expand_path("lib/spitball/version.rb", ROOT_DIR)

require 'rubygems' rescue nil
require 'rake'
require 'spec/rake/spectask'

task :default => :spec

desc "Run all specs in spec directory."
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{ROOT_DIR}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

require 'bundler'
namespace :spitball do
  Bundler::GemHelper.install_tasks(:name => 'spitball')
end

class NonTaggingGemHelper < Bundler::GemHelper
  def guard_already_tagged; end
  def tag_version; yield if block_given?; end
end

namespace :spitball_server do
  NonTaggingGemHelper.install_tasks(:name => 'spitball-server')
end

desc "build spitball/spitball-server"
task :build => [:'spitball:build', :'spitball_server:build']

desc "install spitball/spitball-server"
task :install => [:'spitball:install', :'spitball_server:install']

desc "release spitball/spitball-server"
task :release => [:'spitball:release', :'spitball_server:release']
