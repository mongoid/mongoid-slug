# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'mongoid/slug/version'

Gem::Specification.new do |s|
  s.name        = 'mongoid_slug'
  s.version     = Mongoid::Slug::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hakan Ensari']
  s.email       = ['hakan.ensari@papercavalier.com']
  s.homepage    = 'http://github.com/hakanensari/mongoid-slug'
  s.summary     = 'Mongoid URL slugs'
  s.description = 'Mongoid URL slug or permalink generator'

  s.rubyforge_project = 'mongoid_slug'

  s.add_dependency 'mongoid',  '~> 3.0'
  s.add_dependency 'stringex', '~> 1.4'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'

  s.files         = Dir.glob('lib/**/*') + %w(LICENSE README.md)
  s.test_files    = Dir.glob('spec/**/*')
  s.require_paths = ['lib']
end
