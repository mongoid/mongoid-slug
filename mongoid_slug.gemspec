# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid/slug/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_slug"
  s.version     = Mongoid::Slug::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Hakan Ensari", "Gerhard Lazu"]
  s.email       = ["code@papercavalier.com"]
  s.homepage    = "http://github.com/papercavalier/mongoid_slug"
  s.summary     = "Generates a URL slug or permalink"
  s.description = "Generates a URL slug or permalink based on fields in a Mongoid model."

  s.rubyforge_project = "mongoid_slug"

  s.add_dependency("mongoid", "~> 2.0.0.beta.19")
  s.add_development_dependency("bson_ext", "~> 1.1.1")
  s.add_development_dependency("database_cleaner", "~> 0.6.0")
  s.add_development_dependency("rspec", "~> 2.0.1")

  s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.md)
  s.test_files    = Dir.glob("spec/**/*")
  s.require_paths = ["lib"]
end
