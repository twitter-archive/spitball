# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "spitball/version"

Gem::Specification.new do |s|
  s.name        = "spitball"
  s.version     = Spitball::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Freels", "Brandon Mitchell", "Joshua Hull"]
  s.email       = "freels@twitter.com"
  s.homepage    = "http://rubygems.org/gems/spitball"
  s.summary     = %q{Use bundler to generate gem tarball packages.}
  s.description = %q{Use bundler to generate gem tarball packages.}

  s.rubyforge_project = "spitball"

  s.add_dependency 'sinatra', '>= 1.0'
  s.add_development_dependency 'rspec', "~> 1.3.0"
  s.add_development_dependency 'rr'
  s.add_development_dependency 'rake'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- spec/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [ "README.md" ]
  s.require_paths    = ["lib"]
end

Gem::Specification.new do |s|
  s.name = %q{spitball}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Freels", "Brandon Mitchell", "Joshua Hull"]
  s.date = %q{2010-10-27}
  s.description = %q{Use bundler to generate gem tarball packages.}
  s.email = %q{freels@twitter.com}
  s.executables = ["spitball", "spitball-cache-cleanup", "spitball-server"]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    ".gitignore",
     "README.md",
     "Rakefile",
     "VERSION",
     "bin/spitball",
     "bin/spitball-cache-cleanup",
     "bin/spitball-server",
     "lib/ext/bundler_fake_dsl.rb",
     "lib/ext/bundler_lockfile_parser.rb",
     "lib/spitball.rb",
     "lib/spitball/digest.rb",
     "lib/spitball/file_lock.rb",
     "lib/spitball/remote.rb",
     "lib/spitball/repo.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/spitball_spec.rb",
     "spitball.gemspec"
  ]
  s.homepage = %q{http://github.com/freels/spitball}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{get a bundle}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/spitball_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<sinatra>, ["~> 1.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<sinatra>, ["~> 1.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<sinatra>, ["~> 1.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
  end
end

