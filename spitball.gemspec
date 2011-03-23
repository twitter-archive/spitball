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
  s.add_dependency 'json'
  s.add_development_dependency 'rspec', "~> 1.3.0"
  s.add_development_dependency 'rr'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'phocus'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- spec/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [ "README.md" ]
  s.require_paths    = ["lib"]
end
