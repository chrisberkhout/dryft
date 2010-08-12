require 'rubygems'
SPEC = Gem::Specification.new do |s|
  s.name                = "dryft"
  s.description         = "Don't Repeat Yoursef Factoring Tool for WinAutomation"
  s.summary             = "Define WinAutomation procedures that can be included elsewhere without consistency issues."
  s.version             = "1.0.0"
  s.rubyforge_project   = "nowarning"
  s.author              = "Chris Berkhout"
  s.email               = "chrisberkhout@gmail.com"
  s.homepage            = "http://chrisberkhout.com"
  s.executables         = ["dryft"]
  s.default_executable  = "dryft"
  candidates            = Dir.glob("{bin,docs,lib,tests}/**/*")
  s.files               = candidates.delete_if { |i| i.include?(".git") }
  s.require_path        = "lib"
  s.has_rdoc            = true
  s.extra_rdoc_files    = ["README.rdoc"]
  s.platform            = Gem::Platform::RUBY
  s.add_dependency("sqlite3-ruby", ">= 1.3.1")
  s.add_dependency("nokogiri", ">= 1.4.3.1")
end
