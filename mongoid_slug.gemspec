# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid/slug/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_slug"
  s.version     = Mongoid::Slug::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Hakan Ensari"]
  s.email       = ["hakan.ensari@papercavalier.com"]
  s.homepage    = "http://github.com/hakanensari/mongoid-slug"
  s.summary     = "Generates a URL slug in a Mongoid model"
  s.description = <<-DESC.strip.gsub /\w\w+/, ' '
    Mongoid Slug enerates a URL slug or permalink based on one or more fields
    in a Mongoid model.
  DESC

  s.rubyforge_project = "mongoid_slug"

  s.add_dependency("mongoid", ">= 2.0")
  s.add_dependency("stringex", "~> 1.3")
  s.add_development_dependency("bson_ext", "~> 1.6")
  s.add_development_dependency("pry", "~> 0.9")
  s.add_development_dependency("rake", "~> 0.9")
  s.add_development_dependency("rspec", "~> 2.8")

  s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.md)
  s.test_files    = Dir.glob("spec/**/*")
  s.require_paths = ["lib"]
end
