require 'rubygems'
require 'bundler/setup'

require 'pry'
require 'rspec'

require File.expand_path('../../lib/mongoid_slug', __FILE__)

Mongoid.configure do |config|
  name = 'mongoid_slug_test'
  config.connect_to(name)
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/models/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.before :each do
    Mongoid.purge!
    Mongoid::IdentityMap.clear
  end
end
