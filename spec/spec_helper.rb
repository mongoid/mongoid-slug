require "rubygems"
require "bundler/setup"

require "rspec"

require File.expand_path("../../lib/mongoid/slug", __FILE__)

Mongoid.configure do |config|
  name = "mongoid_slug_test"
  config.master = Mongo::Connection.new.db(name)
end

Dir["#{File.dirname(__FILE__)}/models/*.rb"].each { |f| require f }

RSpec.configure do |c|
  c.before(:each) do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:remove)
  end
end
