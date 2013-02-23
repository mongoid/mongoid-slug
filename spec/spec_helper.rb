begin
  require 'pry'
rescue LoadError
end
require 'rspec'
require 'uuid'
require "awesome_print"

require File.expand_path '../../lib/mongoid_slug', __FILE__
require 'mongoid/paranoia'

module Mongoid::Slug::UuidIdStrategy
  def self.call id
    id =~ /\A([0-9a-fA-F]){8}-(([0-9a-fA-F]){4}-){3}([0-9a-fA-F]){12}\z/
  end
end

def database_id
    ENV['CI'] ? "mongoid_slug_#{Process.pid}" : 'mongoid_slug_test'
end

Mongoid.configure do |config|
  config.connect_to database_id
end

Dir['./spec/models/*.rb'].each { |f| require f }

RSpec.configure do |c|
  c.before(:each) do
    Mongoid.purge!
    Mongoid::IdentityMap.clear
  end

  c.after(:suite) do
    Mongoid::Threaded.sessions[:default].drop if ENV['CI']
  end
end
