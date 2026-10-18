# frozen_string_literal: true

require 'spec_helper'
require 'i18n/backend/fallbacks'

describe 'Localized slug history with fallbacks' do
  around do |example|
    original_fallbacks = I18n.fallbacks
    I18n.fallbacks = I18n::Locale::Fallbacks.new(nl: :en)
    I18n.with_locale(:en) { example.run }
  ensure
    I18n.fallbacks = original_fallbacks
  end

  it 'preserves the default locale when adding the same title in another locale' do
    page = PageSlugLocalizedHistory.create!(title: 'Shared Title')

    I18n.with_locale(:nl) { page.update!(title: 'Shared Title') }

    expect(page.reload._slugs_translations).to eq(
      'en' => ['shared-title'], 'nl' => ['shared-title']
    )
  end

  it 'keeps independent histories without duplicate current slugs' do
    page = PageSlugLocalizedHistory.create!(title: 'Original Title')
    I18n.with_locale(:nl) { page.update!(title: 'Original Title') }
    I18n.with_locale(:nl) { page.update!(title: 'Dutch Title') }
    I18n.with_locale(:nl) { page.update!(title: 'Original Title') }

    expect(page.reload._slugs_translations).to eq(
      'en' => ['original-title'], 'nl' => %w[dutch-title original-title]
    )
  end
end
