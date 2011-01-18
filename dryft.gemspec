# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dryft/version"

Gem::Specification.new do |s|
  s.name        = "dryft"
  s.version     = Dryft::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Chris Berkhout"]
  s.email       = ["chrisberkhout@gmail.com"]
  s.homepage    = "http://github.com/chrisberkhout/dryft"
  s.summary     = %q{Don't Repeat Yoursef Factoring Tool for WinAutomation}
  s.description = %q{Define WinAutomation procedures that can be included elsewhere without consistency issues.}

  s.rubyforge_project = "dryft"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("sqlite3-ruby")
  s.add_dependency("nokogiri")
end
