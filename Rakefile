ROOT_DIR = File.expand_path(File.dirname(__FILE__))

require 'rubygems' rescue nil
require 'rake'
require 'spec/rake/spectask'

task :default => :spec

desc "Run all specs in spec directory."
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{ROOT_DIR}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

# gemification with jeweler
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "spitball"
    gemspec.summary = "get a bundle"
    gemspec.description = "Use bundler to generate gem tarball packages."
    gemspec.email = "freels@twitter.com"
    gemspec.homepage = "http://twitter.com"
    gemspec.authors = ["Matt Freels", "Brandon Mitchell"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
