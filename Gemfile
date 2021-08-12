# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'mongoid-slug'

case version = ENV['MONGOID_VERSION'] || '7'
when 'HEAD'
  gem 'mongoid', github: 'mongodb/mongoid'
when /^7/
  gem 'mongoid', '~> 7'
else
  gem 'mongoid', version
end

group :test do
  gem 'mongoid-danger', '~> 0.1.0', require: false
  gem 'rubocop', '~> 1.18.4'
  gem 'rubocop-rspec'
end
