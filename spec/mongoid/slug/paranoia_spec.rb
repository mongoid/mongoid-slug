# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'

describe Mongoid::Slug::Paranoia, :aggregate_failures do
  # Includes this module into Mongoid::Paranoia in a separate Ruby process, because that cannot be undone, and
  # reports whether models defined before and after include it and its callbacks.
  let(:enable_for_all_paranoid_models) do
    <<~RUBY
      require 'mongoid'
      require 'mongoid/paranoia'
      require 'mongoid/slug'

      class Earlier
        include Mongoid::Document
        include Mongoid::Paranoia
        include Mongoid::Slug

        field :title
        slug :title
      end

      Mongoid::Paranoia.include Mongoid::Slug::Paranoia

      class Later
        include Mongoid::Document
        include Mongoid::Paranoia
        include Mongoid::Slug

        field :title
        slug :title
      end

      print [
        Earlier.slug_paranoia?,
        Later.slug_paranoia?,
        Later._destroy_callbacks.map(&:filter).include?(:unset_slug!),
        Later._restore_callbacks.map(&:filter).include?(:set_slug!)
      ].inspect
    RUBY
  end

  def stored(doc)
    doc.class.unscoped.collection.find(_id: doc._id).first
  end

  def soft_deleted(klass, value)
    klass.create!(klass.slugged_attributes.first => value).tap(&:destroy)
  end

  def define_model(name, &block)
    stub_const(name, Class.new)
    Object.const_get(name).tap { |klass| klass.class_eval(&block) }
  end

  def define_model_without_paranoia
    define_model('Leaflet') do
      include Mongoid::Document
      include Mongoid::Slug
      include Mongoid::Slug::Paranoia

      field :title
      slug :title
    end
  end

  # Includes the module after calling slug.
  def define_model_including_it_last
    klass = define_model('Memo') do
      include Mongoid::Document
      include Mongoid::Paranoia
      include Mongoid::Slug

      store_in collection: 'memos'
      field :title
      slug :title
    end
    klass.include(described_class)
    klass
  end

  it 'is not enabled for models that do not include it' do
    expect(Book.slug_paranoia?).to be false
    Book.create!(title: 'Spy').destroy
    expect(Book.create!(title: 'Spy').slug).to eq 'spy'
  end

  it 'raises when included in a model without Mongoid::Paranoia' do
    expect { define_model_without_paranoia }.to raise_error(
      ArgumentError, /Leaflet includes Mongoid::Slug::Paranoia without Mongoid::Paranoia/
    )
  end

  next unless defined?(Mongoid::Paranoia)

  it 'keeps the slugs of soft-deleted documents in paranoid models that do not include it' do
    expect(ParanoidNote.slug_paranoia?).to be false
    doc = soft_deleted(ParanoidNote, 'Spy')
    expect(stored(doc)['_slugs']).to eq ['spy']
    expect(ParanoidNote.create!(title: 'Spy').slug).to eq 'spy-1'
  end

  it 'keeps the standard slug save callback' do
    expect(ParanoidPost._save_callbacks.map(&:filter)).to include(:build_slug)
    expect(ParanoidPost.create!(title: 'Spy').slug).to eq 'spy'
  end

  it 'installs its callbacks when included after slug' do
    klass = define_model_including_it_last
    expect(klass.slug_paranoia?).to be true
    expect(stored(soft_deleted(klass, 'Spy'))).not_to have_key('_slugs')
  end

  it 'is enabled for every paranoid model defined after it is included into Mongoid::Paranoia' do
    lib = File.expand_path('../../../lib', __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, '-I', lib, '-e', enable_for_all_paranoid_models)
    expect(status).to be_success, output
    expect(output).to eq '[false, true, true, true]'
  end

  [ParanoidAgent, ParanoidPost].each do |klass|
    context "with #{klass.name}" do
      let(:field) { klass.slugged_attributes.first }

      before { klass.create_indexes }

      it 'removes the slug of a soft-deleted document and releases it' do
        doc = soft_deleted(klass, 'Spy')
        expect(stored(doc)).not_to have_key('_slugs')
        expect(klass.unscoped.find(doc._id).slug).to eq doc._id.to_s
        expect(klass.create!(field => 'Spy').slug).to eq 'spy'
      end

      it 'gives a restored document its slug back' do
        doc = soft_deleted(klass, 'Spy').tap(&:restore)
        expect(stored(doc)['_slugs']).to eq ['spy']
      end

      it 'gives a restored document a unique slug when another document took it' do
        doc = soft_deleted(klass, 'Spy')
        klass.create!(field => 'Spy')
        expect(doc.tap(&:restore).slug).to eq 'spy-1'
      end

      it 'keeps the slug removed when a soft-deleted document is saved' do
        doc = klass.create!(field => 'Spy', deleted_at: Time.now)
        expect(stored(doc)).not_to have_key('_slugs')
        doc.update!(field => 'Mole')
        expect(stored(doc)).not_to have_key('_slugs')
      end

      it 'builds a slug again when deleted_at is cleared and the document is saved' do
        doc = klass.unscoped.find(soft_deleted(klass, 'Spy')._id)
        doc.update!(deleted_at: nil)
        expect(stored(doc)['_slugs']).to eq ['spy']
      end

      it 'lets soft-deleted documents share a source value under the unique index' do
        2.times { soft_deleted(klass, 'Spy') }
        expect(klass.unscoped.where(:deleted_at.ne => nil).count).to eq 2
        expect(klass.create!(field => 'Spy').slug).to eq 'spy'
      end

      it 'hard-destroys active and soft-deleted documents' do
        deleted = klass.unscoped.find(soft_deleted(klass, 'Mole')._id)
        expect { klass.create!(field => 'Spy').destroy! }.not_to raise_error
        expect { deleted.destroy! }.not_to raise_error
        expect(klass.unscoped.count).to eq 0
      end
    end
  end

  it 'releases the slugs of documents soft-deleted before a model included it' do
    doc = soft_deleted(ParanoidNote, 'Spy')
    expect(stored(doc)['_slugs']).to eq ['spy']
    ParanoidNote.unscoped.where(:deleted_at.ne => nil).each(&:unset_slug!)
    expect(stored(doc)).not_to have_key('_slugs')
  end
end
