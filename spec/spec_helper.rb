require 'bundler/setup'

require 'rspec'
require 'uuid'
require 'awesome_print'
require 'active_support'
require 'active_support/deprecation'
require 'mongoid'
require 'mongoid/paranoia'
require 'rspec/its'
require 'mongoid-compatibility'

require File.expand_path '../../lib/mongoid/slug', __FILE__

module Mongoid
  module Slug
    module UuidIdStrategy
      def self.call(id)
        id =~ /\A([0-9a-fA-F]){8}-(([0-9a-fA-F]){4}-){3}([0-9a-fA-F]){12}\z/
      end
    end
  end
end

def database_id
  ENV['CI'] ? "mongoid_slug_#{Process.pid}" : 'mongoid_slug_test'
end

Mongoid.configure do |config|
  config.connect_to database_id
end

%w(models shared).each do |dir|
  Dir["./spec/#{dir}/*.rb"].each { |f| require f }
end

I18n.available_locales = [:en, :nl]

RSpec.configure do |c|
  c.raise_errors_for_deprecations!

  c.before :all do
    Mongoid.logger.level = Logger::INFO
    Mongo::Logger.logger.level = Logger::INFO if Mongoid::Compatibility::Version.mongoid5?
  end

  c.before(:each) do
    Mongoid.purge!
    Mongoid::IdentityMap.clear if defined?(Mongoid::IdentityMap)
  end
end
