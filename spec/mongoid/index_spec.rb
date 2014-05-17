#encoding: utf-8
require "spec_helper"

describe Mongoid::Slug::Index do

  let(:scope_key)     { nil }
  let(:by_model_type) { false }
  subject { Mongoid::Slug::Index.build_index(scope_key, by_model_type) }

  context "when scope_key is set" do
    let(:scope_key) { :foo }

    context "when by_model_type is true" do
      let(:by_model_type) { true }
      it { should eq [{:_slugs=>1, :foo=>1, :_type=>1}, {}] }
    end

    context "when by_model_type is false" do
      it { should eq [{:_slugs=>1, :foo=>1}, {:unique=>true, :sparse=>true}] }
    end
  end

  context "when scope_key is not set" do

    context "when by_model_type is true" do
      let(:by_model_type) { true }
      it { should eq [{:_slugs=>1, :_type=>1}, {}] }
    end

    context "when by_model_type is false" do
      it { should eq [{:_slugs=>1}, {:unique=>true, :sparse=>true}] }
    end
  end
end
