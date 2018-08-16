require 'spec_helper'
require 'rake'

describe 'mongoid_slug:set' do
  before :all do
    load File.expand_path('../../lib/tasks/mongoid_slug.rake', __dir__)
    Rake::Task.define_task(:environment)
  end

  context 'when models parameter is passed' do
    before :all do
      UninitalizedSlugFirst = Class.new do
        include Mongoid::Document
        field :name, type: String
        store_in collection: 'uninitalized_slug_first'
      end
      UninitalizedSlugSecond = Class.new do
        include Mongoid::Document
        field :name, type: String
        store_in collection: 'uninitalized_slug_second'
      end
    end

    it 'goes though all documents of passed models and sets slug if not already set' do
      uninitalized_slug1 = UninitalizedSlugFirst.create(name: 'uninitalized-slug1')
      uninitalized_slug2 = UninitalizedSlugSecond.create(name: 'uninitalized-slug2')

      UninitalizedSlugFirst.class_eval do
        include Mongoid::Slug
        slug :name
      end
      UninitalizedSlugSecond.class_eval do
        include Mongoid::Slug
        slug :name
      end

      expect(uninitalized_slug1.slugs).to be_nil
      expect(uninitalized_slug2.slugs).to be_nil

      Rake::Task['mongoid_slug:set'].reenable
      Rake::Task['mongoid_slug:set'].invoke('UninitalizedSlugFirst')

      expect(uninitalized_slug1.reload.slugs).to eq(['uninitalized-slug1'])
      expect(uninitalized_slug2.reload.slugs).to be nil
    end
  end

  context 'when models parameter is not passed' do
    before :all do
      UninitalizedSlugThird = Class.new do
        include Mongoid::Document
        field :name, type: String
        store_in collection: 'uninitalized_slug_third'
      end
    end

    it 'goes though all documents and sets slug if not already set' do
      uninitalized_slug3 = UninitalizedSlugThird.create(name: 'uninitalized-slug3')

      UninitalizedSlugThird.class_eval do
        include Mongoid::Slug
        slug :name
      end

      expect(uninitalized_slug3.slugs).to be_nil

      Rake::Task['mongoid_slug:set'].reenable
      Rake::Task['mongoid_slug:set'].invoke

      expect(uninitalized_slug3.reload.slugs).to eq(['uninitalized-slug3'])
    end
  end
end
