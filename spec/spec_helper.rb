require "rubygems"
require "bundler/setup"

require "database_cleaner"
require "mongoid"
require "stringex"
require "rspec"

Mongoid.configure do |config|
  name = "mongoid_slug_test"
  config.master = Mongo::Connection.new.db(name)
end

require File.expand_path("../../lib/mongoid/slug", __FILE__)

Dir["#{File.dirname(__FILE__)}/models/*.rb"].each { |f| require f }

Rspec.configure do |c|
  c.before(:all)  { DatabaseCleaner.strategy = :truncation }
  c.before(:each) { DatabaseCleaner.start }
  c.after(:each)  { DatabaseCleaner.clean }
end
