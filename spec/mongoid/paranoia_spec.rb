# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Slug do
  context 'when paranoia support is not enabled' do
    let!(:doc) { Agent.create(name: 'Garbo') }

    it 'does not delete the slug when the document is destroyed' do
      expect(doc.slug).to eq 'garbo'
      doc.destroy
      expect(Agent.unscoped.find(doc._id).slug).to eq 'garbo'
    end
  end

  context 'when paranoia support is enabled' do
    let!(:doc) { SecretAgent.create(name: 'Alaric') }

    around do |example|
      Mongoid::Slug.use_paranoia = true
      example.run
    ensure
      Mongoid::Slug.use_paranoia = false
    end

    it 'deletes the slug when the document is destroyed' do
      expect(doc.slug).to eq 'alaric'
      doc.destroy
      # TODO: This case should be nil.
      expect(SecretAgent.unscoped.find(doc._id).slug).to eq doc._id.to_s
      doc.restore
      expect(SecretAgent.unscoped.find(doc._id).slug).to eq 'alaric'
    end

    it 'deletes the slug when deleted document is saved' do
      expect(doc.slug).to eq 'alaric'
      doc.deleted_at = Time.current
      doc.save!
      expect(SecretAgent.unscoped.find(doc._id).slug).to eq nil
      # TODO: This case should re-set the slug.
      doc.deleted_at = nil
      doc.save!
      expect(SecretAgent.unscoped.find(doc._id).slug).to eq nil
    end
  end
end
