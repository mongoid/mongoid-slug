# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'mongoid-slug'

case (version = ENV['MONGOID_VERSION'] || '8')
when /\Ahead\z/i
  gem 'mongoid', github: 'mongodb/mongoid'
when /\A\d+\z/
  gem 'mongoid', "~> #{version}.0"
else
  gem 'mongoid', version
end

gem 'mongoid_paranoia', '>= 0.6'
gem 'rake'
gem 'rspec'
gem 'rspec-its'
gem 'rubocop'
gem 'rubocop-rspec'
gem 'uuid'
