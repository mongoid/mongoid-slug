#encoding: utf-8
require "spec_helper"

module Mongoid
  describe Slug do
    let!(:book) do
      Book.create(:title => "A Thousand Plateaus")
    end

    context "when the object is top-level" do
      it "generates a slug" do
        book.to_param.should eql "a-thousand-plateaus"
      end

      it "updates the slug" do
        book.title = "Anti Oedipus"
        book.save
        book.to_param.should eql "anti-oedipus"
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        dup = Book.create(:title => book.title)
        dup.to_param.should eql "a-thousand-plateaus-1"
      end

      it "does not update slug if slugged fields have not changed" do
        book.save
        book.to_param.should eql "a-thousand-plateaus"
      end

      it "does not change slug if slugged fields have changed but generated slug is identical" do
        book.title = "a thousand plateaus"
        book.save
        book.to_param.should eql "a-thousand-plateaus"
      end

      it "finds by slug" do
        Book.find_by_slug(book.to_param).should eql book
      end
    end

    context "when the object is embedded" do
      let(:subject) do
        book.subjects.create(:name => "Psychoanalysis")
      end

      it "generates a slug" do
        subject.to_param.should eql "psychoanalysis"
      end

      it "updates the slug" do
        subject.name = "Schizoanalysis"
        subject.save
        subject.to_param.should eql "schizoanalysis"
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        dup = book.subjects.create(:name => subject.name)
        dup.to_param.should eql 'psychoanalysis-1'
      end

      it "does not update slug if slugged fields have not changed" do
        subject.save
        subject.to_param.should eql "psychoanalysis"
      end

      it "does not change slug if slugged fields have changed but generated slug is identical" do
        subject.name = "PSYCHOANALYSIS"
        subject.to_param.should eql "psychoanalysis"
      end

      it "finds by slug" do
        book.subjects.find_by_slug(subject.to_param).should eql subject
      end
    end

    context "when the object is embedded in another embedded object" do
      let(:person) do
        Person.create(:name => "John Doe")
      end

      let(:relationship) do
        person.relationships.create(:name => "Engagement")
      end

      let(:partner) do
        relationship.partners.create(:name => "Jane Smith")
      end

      it "generates a slug" do
        partner.to_param.should eql "jane-smith"
      end

      it "updates the slug" do
        partner.name = "Jane Doe"
        partner.save
        partner.to_param.should eql "jane-doe"
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        dup = relationship.partners.create(:name => partner.name)
        dup.to_param.should eql "jane-smith-1"
      end

      it "does not update slug if slugged fields have not changed" do
        partner.save
        partner.to_param.should eql "jane-smith"
      end

      it "does not change slug if slugged fields have changed but generated slug is identical" do
        partner.name = "JANE SMITH"
        partner.to_param.should eql "jane-smith"
      end

      it "scopes by parent object" do
        affair = person.relationships.create(:name => "Affair")
        lover = affair.partners.create(:name => partner.name)
        lover.to_param.should eql partner.to_param
      end

      it "finds by slug" do
        relationship.partners.find_by_slug(partner.to_param).should eql partner
      end
    end

    context "when the slug is composed of multiple fields" do
      let!(:author) do
        Author.create(
          :first_name => "Gilles",
          :last_name  => "Deleuze")
      end

      it "generates a slug" do
        author.to_param.should eql "gilles-deleuze"
      end

      it "updates the slug" do
        author.first_name = "Félix"
        author.last_name  = "Guattari"
        author.save
        author.to_param.should eql "felix-guattari"
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        dup = Author.create(
          :first_name => author.first_name,
          :last_name  => author.last_name)
        dup.to_param.should eql 'gilles-deleuze-1'
      end

      it "does not update slug if slugged fields have changed but generated slug is identical" do
        author.last_name = "DELEUZE"
        author.save
        author.to_param.should eql 'gilles-deleuze'
      end

      it "finds by slug" do
        Author.find_by_slug("gilles-deleuze").should eql author
      end
    end

    context "when the field name for the slug is set with the :as option" do
      let(:person) do
        Person.create(:name => "John Doe")
      end

      it "sets the slug field name" do
        person.should respond_to(:permalink)
        person.permalink.should eql "john-doe"
      end
    end

    context "when slug is set to be permanent with the :permanent option" do
      let(:person) do
        Person.create(:name => "John Doe")
      end

      it "does not change the slug when the slugged fields are updated" do
        person.name = "Jane Doe"
        person.save
        person.to_param.should eql "john-doe"
      end
    end

    context "when slug is scoped by a reference association" do
      let(:author) do
        book.authors.create(:first_name => "Gilles", :last_name  => "Deleuze")
      end

      it "scopes by parent object" do
        book2 = Book.create(:title => "Anti Oedipus")
        dup = book2.authors.create(
          :first_name => author.first_name,
          :last_name => author.last_name
        )
        dup.to_param.should eql author.to_param
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        dup = book.authors.create(
          :first_name => author.first_name,
          :last_name  => author.last_name)
        dup.to_param.should eql 'gilles-deleuze-1'
      end

      context "with an irregular association name" do
        let(:character) do
          # well we've got to make up something... :-)
          author.characters.create(:name => "Oedipus")
        end

        let!(:author2) do
          Author.create(
            :first_name => "Sophocles",
            :last_name => "son of Sophilos"
          )
        end

        it "scopes by parent object provided that inverse_of is specified" do
          dup = author2.characters.create(:name => character.name)
          dup.to_param.should eql character.to_param
        end
      end
    end

    it "works with non-Latin characters" do
      book.title = "Капитал"
      book.save
      book.to_param.should eql "kapital"

      book.title = "Ελλάδα"
      book.save
      book.to_param.should eql "ellada"

      book.title = "中文"
      book.save
      book.to_param.should eql 'zhong-wen'
    end

    it "deprecates the :scoped option" do
      ActiveSupport::Deprecation.should_receive(:warn)
      class Oldie
        include Mongoid::Document
        include Mongoid::Slug
        field :name
        slug  :name, :scoped => true
      end
    end

    context "when :index is set to true" do
      before do
        Book.collection.drop_indexes
        Author.collection.drop_indexes
      end

      it "indexes slug in top-level objects" do
        Book.create_indexes
        Book.collection.index_information.should have_key "slug_1"
      end

      context "when slug is scoped by a reference association" do
        it "creates a non-unique index" do
          Author.create_indexes
          Author.index_information["slug_1"]["unique"].should be_false
        end
      end

      context "when slug is not scoped by a reference association" do
        it "creates a unique index" do
          Book.create_indexes
          Book.index_information["slug_1"]["unique"].should be_true
        end
      end

      it "does not index slug in embedded objects" do
        pending "Would such an option even make sense?"
      end
    end

    context "when :index is not set" do
      it "does not index slug" do
        Person.create_indexes
        Person.collection.index_information.should_not have_key "permalink_1"
      end
    end
  end
end
