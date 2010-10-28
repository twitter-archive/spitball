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
# FIXME: stop using jeweler when I get smarter.
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "spitball"
    gem.summary = "get a bundle"
    gem.description = "Use bundler to generate gem tarball packages."
    gem.email = "freels@twitter.com"
    gem.homepage = "http://github.com/freels/spitball"
    gem.authors = ["Matt Freels", "Brandon Mitchell", "Joshua Hull"]

    gem.add_dependency 'sinatra', '>= 1.0'
    gem.add_development_dependency 'rspec'
    gem.add_development_dependency 'rr'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
