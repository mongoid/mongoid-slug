# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Slug do
  it 'clears, restores and atomically unsets saved slugs' do
    book = Book.create!(title: 'Saved Slug')
    book.clear_slug!
    expect(book._slugs).to eq([])
    book.reset_slug!
    expect(book._slugs).to eq(['saved-slug'])

    book.unset_slug!
    expect(book._slugs).to eq([])
    expect(Book.collection.find(_id: book.id).first).not_to have_key('_slugs')
  end

  it 'loads the supported underscored require entry point' do
    require 'mongoid_slug'
    expect(Book.ancestors).to include(described_class)
  end

  it 'defines a semantic version' do
    expect(Mongoid::Slug::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it 'handles a model that includes the concern before declaring its slug field' do
    stub_const('UnconfiguredCoverageSlug', Class.new)
    UnconfiguredCoverageSlug.class_eval do
      include Mongoid::Document
      include Mongoid::Slug
    end

    expect(UnconfiguredCoverageSlug.new.send(:localized?)).to eq(false)
    criteria = Mongoid::Slug::Criteria.new(UnconfiguredCoverageSlug)
    expect(criteria.send(:for_slugs, ['missing']).selector)
      .to eq('_slugs' => { '$in' => ['missing'] })
  end
end

describe Mongoid::Slug::UniqueSlug do
  it 'suggests a unique slug for explicitly supplied text' do
    Book.create!(title: 'Suggested Title')
    expect(described_class.new(Book.new).find_unique('Suggested Title')).to eq('suggested-title-1')
  end

  it 'exposes existing and historical state without changing saved documents' do
    book = Book.create!(title: 'Coverage Title')
    book.update!(title: 'Coverage Other')
    Book.create!(title: 'Coverage Title')
    state = described_class::SlugState.new('coverage-title', Book.all, '^coverage-title(?:-(\d+))?$')

    expect(state.highest_existing_counter).to eq(1)
    expect(state.inspect).to include(
      slug: 'coverage-title',
      existing_slugs: %w[coverage-title coverage-title-1],
      existing_history_slugs: ['coverage-title'],
      last_entered_slug: ['coverage-title-1'],
      sorted_existing: [0, 1]
    )
    expect(book.reload._slugs).to eq(%w[coverage-title coverage-other])
  end
end
