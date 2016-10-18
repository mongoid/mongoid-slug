source 'https://rubygems.org'

gemspec name: 'mongoid-slug'

case version = ENV['MONGOID_VERSION'] || '6'
when 'HEAD'
  gem 'mongoid', github: 'mongodb/mongoid'
  gem 'mongoid_paranoia', github: 'simi/mongoid_paranoia'
  gem 'mongoid-observers'
  gem 'rails-observers', github: 'rails/rails-observers'
when /^6/
  gem 'mongoid', '~> 6.0.0'
when /^5/
  gem 'mongoid', '~> 5.0'
  gem 'mongoid_paranoia'
  gem 'mongoid-observers'
when /^4/
  gem 'mongoid', '~> 4.0'
  gem 'mongoid_paranoia'
  gem 'mongoid-observers'
when /^3/
  gem 'mongoid', '~> 3.1'
else
  gem 'mongoid', version
end

group :test do
  gem 'rubocop', '0.42.0'
  gem 'mongoid-danger', '~> 0.1.0', require: false
end
