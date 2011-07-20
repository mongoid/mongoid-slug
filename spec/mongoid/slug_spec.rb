#encoding: utf-8
require "spec_helper"

module Mongoid
  describe Slug do
    let(:book) do
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
        15.times{ |x|
          dup = Book.create(:title => book.title)
          dup.to_param.should eql "a-thousand-plateaus-#{x+1}"
        }
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

        dup2 = Author.create(
          :first_name => author.first_name,
          :last_name  => author.last_name)

        dup.save
        dup2.to_param.should eql 'gilles-deleuze-2'
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

    context "when :as is passed as an argument" do
      let!(:person) do
        Person.create(:name => "John Doe")
      end

      it "sets an alternative slug field name" do
        person.should respond_to(:permalink)
        person.permalink.should eql "john-doe"
      end

      it "finds by slug" do
        Person.find_by_permalink("john-doe").should eql person
      end
    end

    context "when :permanent is passed as an argument" do
      let(:person) do
        Person.create(:name => "John Doe")
      end

      it "does not update the slug when the slugged fields change" do
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

    context "when :slug is given a block" do
      let(:caption) do
        Caption.create(:identity => 'Edward Hopper (American, 1882-1967)',
                       :title    => 'Soir Bleu, 1914',
                       :medium   => 'Oil on Canvas')
      end

      it "generates a slug" do
        caption.to_param.should eql 'edward-hopper-soir-bleu-1914'
      end

      it "updates the slug" do
        caption.title = 'Road in Maine, 1914'
        caption.save
        caption.to_param.should eql "edward-hopper-road-in-maine-1914"
      end

      it "does not change slug if slugged fields have changed but generated slug is identical" do
        caption.identity = 'Edward Hopper'
        caption.save
        caption.to_param.should eql 'edward-hopper-soir-bleu-1914'
      end

      it "finds by slug" do
        Caption.find_by_slug(caption.to_param).should eql caption
      end
    end

    context "when slugged field contains non-ASCII characters" do
      it "slugs Cyrillic characters" do
        book.title = "Капитал"
        book.save
        book.to_param.should eql "kapital"
      end

      it "slugs Greek characters" do
        book.title = "Ελλάδα"
        book.save
        book.to_param.should eql "ellada"
      end

      it "slugs Chinese characters" do
        book.title = "中文"
        book.save
        book.to_param.should eql 'zhong-wen'
      end

      it "slugs non-ASCII Latin characters" do
        book.title = 'Paul Cézanne'
        book.save
        book.to_param.should eql 'paul-cezanne'
      end
    end

    context "when :index is passed as an argument" do
      before do
        Book.collection.drop_indexes
        Author.collection.drop_indexes
      end

      it "defines an index on the slug in top-level objects" do
        Book.create_indexes
        Book.collection.index_information.should have_key "slug_1"
      end

      context "when slug is scoped by a reference association" do
        it "defines a non-unique index" do
          Author.create_indexes
          Author.index_information["slug_1"]["unique"].should be_false
        end
      end

      context "when slug is not scoped by a reference association" do
        it "defines a unique index" do
          Book.create_indexes
          Book.index_information["slug_1"]["unique"].should be_true
        end
      end
    end

    context "when :index is not passed as an argument" do
      it "does not define an index on the slug" do
        Person.create_indexes
        Person.collection.index_information.should_not have_key "permalink_1"
      end
    end

    context "when the object has STI" do
      it "scopes by the superclass" do
        book = Book.create(:title => "Anti Oedipus")
        comic_book = ComicBook.create(:title => "Anti Oedipus")
        comic_book.slug.should_not eql(book.slug)
      end
    end

    describe ".find_by_slug" do
      let!(:book) { Book.create(:title => "A Thousand Plateaus") }

      it "returns nil if no document is found" do
        Book.find_by_slug(:title => "Anti Oedipus").should be_nil
      end

      it "returns the document if it is found" do
        Book.find_by_slug(book.slug).should == book
      end
    end

    describe ".find_by_slug!" do
      let!(:book) { Book.create(:title => "A Thousand Plateaus") }

      it "raises a Mongoid::Errors::DocumentNotFound error if no document is found" do
        lambda {
          Book.find_by_slug!(:title => "Anti Oedipus")
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "returns the document when it is found" do
        Book.find_by_slug!(book.slug).should == book
      end
    end
  end
end
