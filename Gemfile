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
gem 'rake'
gem 'rspec'
gem 'rspec-its'
gem 'rubocop'
gem 'rubocop-rspec'
gem 'simplecov', '~> 0.22' if ENV['COVERAGE'] == 'true'
gem 'uuid'
