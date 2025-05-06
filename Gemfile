# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'mongoid-slug'

case (version = ENV['MONGOID_VERSION'])&.downcase
when 'head'
  gem 'mongoid', github: 'mongodb/mongoid'
when /\A\d+(?:\.\d+)?\z/
  gem 'mongoid', "~> #{version}.0"
when String
  gem 'mongoid', version
end

gem 'rake'
gem 'rspec'
gem 'rspec-its'
gem 'rubocop'
gem 'rubocop-rspec'
gem 'uuid'
