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
Bundler::GemHelper.install_tasks

namespace :version do
  def update_version
    source = File.read(VERSION_FILE)
    new_v = nil
    File.open(VERSION_FILE, 'w') do |f|
      f.write source.gsub(/\d+\.\d+\.\d+/) {|v|
        new_v = yield(*v.split(".").map {|i| i.to_i}).join(".")
      }
    end
    new_v
  end

  def commit_version(v)
    system "git add #{VERSION_FILE} && git c -m 'release version #{v}' && git tag #{v}"
  end

  task :incr_major do
    new_v = update_version {|m,_,_| [m+1, 0, 0] }
    commit_version(new_v)
  end

  task :incr_minor do
    new_v = update_version {|ma,mi,_| [ma, mi+1, 0] }
    commit_version(new_v)
  end

  task :incr_patch do
    new_v = update_version {|ma,mi,p| [ma, mi, p+1] }
    commit_version(new_v)
  end
end
