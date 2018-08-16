source 'https://rubygems.org'

gemspec name: 'mongoid-slug'

case version = ENV['MONGOID_VERSION'] || '7'
when 'HEAD'
  gem 'mongoid', github: 'mongodb/mongoid'
when /^7/
  gem 'mongoid', '~> 7'
when /^6/
  gem 'mongoid', '~> 6'
when /^5/
  gem 'mongoid', '~> 5'
when /^4/
  gem 'mongoid', '~> 4'
when /^3/
  gem 'mongoid', '~> 3'
else
  gem 'mongoid', version
end

group :test do
  gem 'mongoid-danger', '~> 0.1.0', require: false
  gem 'rubocop', '0.58.2'
end
