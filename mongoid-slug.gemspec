# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'mongoid/slug/version'

Gem::Specification.new do |s|
  s.name        = 'mongoid-slug'
  s.version     = Mongoid::Slug::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Andreas Saebjoernsen']
  s.email       = ['andy@cosemble.com']
  s.homepage    = 'https://github.com/mongoid/mongoid-slug'
  s.summary     = 'Mongoid URL slugs'
  s.description = 'Mongoid URL slug or permalink generator'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.7'

  s.add_dependency 'mongoid', '>= 7.0'
  s.add_dependency 'stringex', '~> 2.0'

  s.files         = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  s.require_paths = ['lib']
  s.metadata['rubygems_mfa_required'] = 'true'
end
