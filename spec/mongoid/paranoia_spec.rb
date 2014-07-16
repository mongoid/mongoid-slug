#encoding: utf-8
require "spec_helper"

describe "Mongoid::Paranoia with Mongoid::Slug" do

  let(:paranoid_doc)    { ParanoidDocument.create!(:title => "slug") }
  let(:paranoid_doc_2)  { ParanoidDocument.create!(:title => "slug") }
  let(:paranoid_perm)   { ParanoidPermanent.create!(:title => "slug") }
  let(:paranoid_perm_2) { ParanoidPermanent.create!(:title => "slug") }
  let(:non_paranoid_doc){ Article.create!(:title => "slug") }
  subject{ paranoid_doc }

  describe ".paranoid?" do

    context "when Mongoid::Paranoia is included" do
      subject { paranoid_doc.class }
      its(:is_paranoid_doc?){ should be_truthy }
    end

    context "when Mongoid::Paranoia not included" do
      subject { non_paranoid_doc.class }
      its(:is_paranoid_doc?){ should be_falsey }
    end
  end

  describe "#paranoid_deleted?" do

    context "when Mongoid::Paranoia is included" do

      context "when not destroyed" do
        its(:paranoid_deleted?){ should be_falsey }
      end

      context "when destroyed" do
        before { subject.destroy }
        its(:paranoid_deleted?){ should be_truthy }
      end
    end

    context "when Mongoid::Paranoia not included" do
      subject { non_paranoid_doc }
      its(:paranoid_deleted?){ should be_falsey }
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

  shared_examples_for "paranoid slugs" do

    context "querying" do

      it "returns paranoid_doc for correct slug" do
        subject.class.find(subject.slug).should eq(subject)
      end
    end

    context "delete (callbacks not fired)" do

      before { subject.delete }

      it "retains slug value" do
        subject.slug.should eq "slug"
        subject.class.unscoped.find("slug").should eq subject
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
        subject.class.unscoped.exists(_slugs: false).first.should eq subject
        expect{subject.class.unscoped.find("slug")}.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      context "when saving the doc again" do

        before { subject.save }

        it "should have the default slug value" do
          subject._slugs.should eq []
          subject.slug.should be_nil
        end

        it "the slug remains unset in the database" do
          subject.class.unscoped.exists(_slugs: false).first.should eq subject
          expect{subject.class.unscoped.find("slug")}.to raise_error(Mongoid::Errors::DocumentNotFound)
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
        subject.slug.should eq "slug"
        subject.destroy
        subject.reload.slug.should be_nil
        other_doc.slug.should eq "slug"
        subject.restore
        subject.slug.should eq "slug-1"
        subject.reload.slug.should eq "slug-1"
      end

      it "should allow multiple documents to be destroyed without index conflict" do
        subject.slug.should eq "slug"
        subject.destroy
        subject.reload.slug.should be_nil
        other_doc.slug.should eq "slug"
        other_doc.destroy
        other_doc.reload.slug.should be_nil
      end
    end
  end

  context "non-permanent slug" do
    subject { paranoid_doc }
    let(:other_doc) { paranoid_doc_2 }
    it_behaves_like "paranoid slugs"
  end

  context "permanent slug" do
    subject { paranoid_perm }
    let(:other_doc) { paranoid_perm_2 }
    it_behaves_like "paranoid slugs"
  end
end
