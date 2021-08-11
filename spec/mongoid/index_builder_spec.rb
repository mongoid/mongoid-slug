require 'spec_helper'

describe Mongoid::Slug::IndexBuilder do
  let(:doc) { Class.new.include(Mongoid::Document) }
  let(:scope_key) { nil }
  let(:by_model_type) { false }
  let(:default_locale) { :en }
  let(:locales) { nil }
  subject { doc.index_specifications.map { |spec| [spec.key, spec.options] } }

  before do
    allow(I18n).to receive(:default_locale).and_return(default_locale)
    Mongoid::Slug::IndexBuilder.build_indexes(doc, scope_key, by_model_type, locales)
  end

  context 'when scope_key is set' do
    let(:scope_key) { :foo }

    context 'when by_model_type is true' do
      let(:by_model_type) { true }

      it { is_expected.to eq [[{ _slugs: 1, foo: 1, _type: 1 }, {}]] }
    end

    context 'when by_model_type is false' do
      it { is_expected.to eq [[{ _slugs: 1, foo: 1 }, {}]] }
    end

    context 'when locale is set' do
      let(:default_locale) { :de }
      let(:locales) { true }

      it { is_expected.to eq [[{ :'_slugs.de' => 1, foo: 1 }, {}]] }
    end

    context 'when locale is not set' do
      it { is_expected.to eq [[{ _slugs: 1, foo: 1 }, {}]] }
    end

    context 'when locales is an Array' do
      let(:locales) { %i[es de fr] }

      it do
        is_expected.to eq [[{ :'_slugs.es' => 1, foo: 1 }, {}],
                           [{ :'_slugs.de' => 1, foo: 1 }, {}],
                           [{ :'_slugs.fr' => 1, foo: 1 }, {}]]
      end
    end
  end

  context 'when scope_key is not set' do
    context 'when by_model_type is true' do
      let(:by_model_type) { true }

      it { is_expected.to eq [[{ _slugs: 1, _type: 1 }, {}]] }
    end

    context 'when by_model_type is false' do
      it { is_expected.to eq [[{ _slugs: 1 }, { unique: true, sparse: true }]] }
    end

    context 'when locales is true' do
      let(:locales) { true }

      it { is_expected.to eq [[{ :'_slugs.en' => 1 }, { unique: true, sparse: true }]] }
    end

    context 'when locales is a String' do
      let(:locales) { 'de' }

      it { is_expected.to eq [[{ :'_slugs.de' => 1 }, { unique: true, sparse: true }]] }
    end

    context 'when locales is a Symbol' do
      let(:locales) { :de }

      it { is_expected.to eq [[{ :'_slugs.de' => 1 }, { unique: true, sparse: true }]] }
    end

    context 'when locales is an Array' do
      let(:locales) { %i[es de fr] }

      it do
        is_expected.to eq [[{ :'_slugs.es' => 1 }, { unique: true, sparse: true }],
                           [{ :'_slugs.de' => 1 }, { unique: true, sparse: true }],
                           [{ :'_slugs.fr' => 1 }, { unique: true, sparse: true }]]
      end
    end

    context 'when locale is set and by_model_type is true' do
      let(:locales) { true }
      let(:default_locale) { :fr }
      let(:by_model_type) { true }

      it { is_expected.to eq [[{ :'_slugs.fr' => 1, _type: 1 }, {}]] }
    end
  end
end
