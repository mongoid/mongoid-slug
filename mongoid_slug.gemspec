# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid/slug/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_slug"
  s.version     = Mongoid::Slug::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Paper Cavalier"]
  s.email       = ["code@papercavalier.com"]
  s.homepage    = "http://github.com/papercavalier/mongoid-slug"
  s.summary     = "Generates a URL slug"
  s.description = "Mongoid Slug generates a URL slug or permalink based on one or more fields in a Mongoid model."

  s.rubyforge_project = "mongoid_slug"

  s.add_dependency("mongoid", "~> 2.0.0")
  s.add_dependency("stringex", "~> 1.2.0")

  s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.md)
  s.test_files    = Dir.glob("spec/**/*")
  s.require_paths = ["lib"]
end
