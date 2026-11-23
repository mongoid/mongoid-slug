# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'mongoid-slug'

case (version = ENV['MONGOID_VERSION'] || '8')
when 'HEAD'
  gem 'mongoid', github: 'mongodb/mongoid'
when /\A\d+\z/
  gem 'mongoid', "~> #{version}.0"
else
  gem 'mongoid', version
end

if %w[jruby truffleruby].include?(RUBY_ENGINE)
  # BSON 5.2.0 constructs the now-abstract JRuby RubyFixnum and retains unsafe native array pointers.
  # Pin the upstream fixes until they are released: mongodb/bson-ruby#377 and #371.
  gem 'bson', github: 'mongodb/bson-ruby', ref: 'e6e788b3f88d81b219da7daf67577f8372081ebe'
end

gem 'danger', require: false
gem 'danger-changelog', require: false
gem 'danger-pr-comment', require: false
gem 'ostruct'
gem 'railties', '>= 6.1', '< 7.3'
gem 'rake'
gem 'rspec'
gem 'rspec-its'
gem 'simplecov', '~> 0.22' if ENV['COVERAGE'] == 'true'
gem 'tsort'
gem 'uuid'

group :development, :test do
  if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
    gem 'commonmarker', '~> 2.10', require: false
    gem 'rubocop', '~> 1.92'
    gem 'rubocop-md', '~> 3.0', require: false
    gem 'rubocop-prose', '~> 0.2', require: false
    gem 'rubocop-rake', '~> 0.7', require: false
    gem 'rubocop-rspec', '~> 3.10', require: false
    gem 'rubocop-spellcheck', '~> 0.2', require: false
    gem 'rubocop-yaml', '~> 0.1.0', require: false
    gem 'ruby-gem-release', '0.9.0', require: false
  end
end
