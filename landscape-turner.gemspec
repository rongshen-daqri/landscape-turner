# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'landscape-turner/version'

Gem::Specification.new do |spec|
  spec.name          = "landscape-turner"
  spec.version       = LandscapeTurner::VERSION
  spec.authors       = ["Justin Boisvert"]
  spec.email         = ["justin.boisvert@daqri.com"]

  spec.summary       = "Backup tool for the Landscape service"
  spec.description   = "A backup tool for the Landscape service that backs up the configuration files and the database related to the service."
  spec.homepage      = "http://www.daqri.com"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables << "landscape-turner-backup"
  spec.executables << "landscape-turner-restore"
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency     "trollop"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
