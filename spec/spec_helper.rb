require "rubygems"
require "bundler/setup"

require "rspec"
require "database_cleaner"
require "mongoid"

Mongoid.configure do |config|
  name = "mongoid_slug_test"
  config.master = Mongo::Connection.new.db(name)
end

require File.expand_path("../../lib/mongoid_slug", __FILE__)
Dir["#{File.dirname(__FILE__)}/models/*.rb"].each { |f| require f }

DatabaseCleaner.orm = "mongoid"

Rspec.configure do |config|
  config.before(:all) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
