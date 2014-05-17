#encoding: utf-8
require "spec_helper"

describe "Mongoid::Paranoia with Mongoid::Slug" do

  let(:paranoid_doc)    { ParanoidDocument.create!(:title => "slug") }
  let(:paranoid_doc_2)  { ParanoidDocument.create!(:title => "slug") }
  let(:non_paranoid_doc){ Article.create!(:title => "slug") }
  subject{ paranoid_doc }

  describe ".paranoid?" do

    context "when Mongoid::Paranoia is included" do
      subject { paranoid_doc.class }
      its(:paranoid?){ should be_true }
    end

    context "when Mongoid::Paranoia not included" do
      subject { non_paranoid_doc.class }
      its(:paranoid?){ should be_false }
    end
  end

  describe "restore callbacks" do

    context "when Mongoid::Paranoia is included" do
      subject { paranoid_doc.class }
      it { should respond_to(:before_restore) }
      it { should respond_to(:after_restore) }
    end

    context "when Mongoid::Paranoia not included" do
      it { should_not respond_to(:before_restore) }
      it { should_not respond_to(:after_restore) }
    end
  end

  describe "index" do
    before  { ParanoidDocument.create_indexes }
    after   { ParanoidDocument.remove_indexes }
    subject { ParanoidDocument }

    it_should_behave_like "has an index", { _slugs: 1 }, { unique: true, sparse: true }
  end

  context "querying" do

    it "returns paranoid_doc for correct slug" do
      ParanoidDocument.find(subject.slug).should eq(subject)
    end
  end

  context "delete (callbacks not fired)" do

    before { subject.delete }

    it "retains slug value" do
      subject.slug.should eq "slug"
      ParanoidDocument.unscoped.find("slug").should eq subject
    end
  end

  context "destroy" do

    before { subject.destroy }

    it "unsets slug value when destroyed" do
      subject._slugs.should eq []
      subject.slug.should be_nil
    end

    it "persists the removed slug" do
      subject.reload._slugs.should eq []
      subject.reload.slug.should be_nil
    end

    it "persists the removed slug in the database" do
      ParanoidDocument.unscoped.exists(_slugs: false).first.should eq subject
      expect{ParanoidDocument.unscoped.find("slug")}.to raise_error(Mongoid::Errors::DocumentNotFound)
    end

    context "when saving the doc again" do

      before { subject.save }

      it "the slug remains unset in the database" do
        ParanoidDocument.unscoped.exists(_slugs: false).first.should eq subject
        expect{ParanoidDocument.unscoped.find("slug")}.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  context "restore" do

    before do
      subject.destroy
      subject.restore
    end

    it "resets slug value when restored" do
      subject.slug.should eq "slug"
      subject.reload.slug.should eq "slug"
    end
  end

  context "multiple documents" do

    it "new documents should be able to use the slug of destroyed documents" do
      paranoid_doc.slug.should eq "slug"
      paranoid_doc.destroy
      paranoid_doc.reload.slug.should be_nil
      paranoid_doc_2.slug.should eq "slug"
      paranoid_doc.restore
      paranoid_doc.slug.should eq "slug-1"
      paranoid_doc.reload.slug.should eq "slug-1"
    end

    it "should allow multiple documents to be destroyed without index conflict" do
      paranoid_doc.slug.should eq "slug"
      paranoid_doc.destroy
      paranoid_doc.reload.slug.should be_nil
      paranoid_doc_2.slug.should eq "slug"
      paranoid_doc_2.destroy
      paranoid_doc_2.reload.slug.should be_nil
    end
  end
end
