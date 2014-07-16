require 'bundler/setup'

begin
  require 'pry'
rescue LoadError
end
require 'rspec'
require 'uuid'
require 'awesome_print'
require 'active_support'
require 'active_support/deprecation'
require 'mongoid'
require 'mongoid/paranoia'
require 'rspec/its'

require File.expand_path '../../lib/mongoid_slug', __FILE__

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

[ 'models', 'shared' ].each do |dir|
  Dir["./spec/#{dir}/*.rb"].each { |f| require f }
end

I18n.available_locales = [ :en, :nl ]

RSpec.configure do |c|
  c.before(:each) do
    Mongoid.purge!
    Mongoid::IdentityMap.clear if defined?(Mongoid::IdentityMap)
  end

  c.after(:suite) do
    Mongoid::Threaded.sessions[:default].drop if ENV['CI']
  end
end
