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

      context "using find" do
        it "finds by slug" do
          Book.find(book.to_param).should eql book
        end

        it "finds by id as string" do
          Book.find(book.id.to_s).should eql book
        end

        it "finds by id as array of strings" do
          Book.find([book.id.to_s]).should eql [book]
        end

        it "finds by id as BSON::ObjectId" do
          Book.find(book.id).should eql book
        end

        it "finds by id as an array of BSON::ObjectIds" do
          Book.find([book.id]).should eql [book]
        end

        it "returns an empty array if given an empty array" do
          Book.find([]).should eql []
        end
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
        dup.to_param.should eql "psychoanalysis-1"
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

      context "using find" do
        it "finds by slug" do
          book.subjects.find(subject.to_param).should eql subject
        end

        it "finds by id as string" do
          book.subjects.find(subject.id.to_s).should eql subject
        end

        it "finds by id as array of strings" do
          book.subjects.find([subject.id.to_s]).should eql [subject]
        end

        it "finds by id as BSON::ObjectId" do
          book.subjects.find(subject.id).should eql subject
        end

        it "finds by id as an array of BSON::ObjectIds" do
          book.subjects.find([subject.id]).should eql [subject]
        end

        it "returns an empty array if given an empty array" do
          book.subjects.find([]).should eql []
        end
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

      context "using find" do
        it "finds by slug" do
          relationship.partners.find(partner.to_param).should eql partner
        end

        it "finds by id as string" do
          relationship.partners.find(partner.id.to_s).should eql partner
        end

        it "finds by id as array of strings" do
          relationship.partners.find([partner.id.to_s]).should eql [partner]
        end

        it "finds by id as BSON::ObjectId" do
          relationship.partners.find(partner.id).should eql partner
        end

        it "finds by id as an array of BSON::ObjectIds" do
          relationship.partners.find([partner.id]).should eql [partner]
        end

        it "returns an empty array if given an empty array" do
          relationship.partners.find([]).should eql []
        end
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
        dup.to_param.should eql "gilles-deleuze-1"

        dup2 = Author.create(
          :first_name => author.first_name,
          :last_name  => author.last_name)

        dup.save
        dup2.to_param.should eql "gilles-deleuze-2"
      end

      it "does not update slug if slugged fields have changed but generated slug is identical" do
        author.last_name = "DELEUZE"
        author.save
        author.to_param.should eql "gilles-deleuze"
      end

      it "finds by slug" do
        Author.find_by_slug("gilles-deleuze").should eql author
      end

      context "using find" do
        it "finds by slug" do
          Author.find("gilles-deleuze").should eql author
        end
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

    context "when :history is passed as an argument" do
      let(:book) do
        Book.create(:title => "Book Title")
      end

      before(:each) do
        book.title = "Other Book Title"
        book.save
      end

      it "saves the old slug in the owner's history" do
        book.slug_history.should include("book-title")
      end

      it "returns the document for the old slug" do
        Book.find_by_slug("book-title").should == book
      end

      it "returns the document for the new slug" do
        Book.find_by_slug("other-book-title").should == book
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        dup = Book.create(:title => "Book Title")
        dup.to_param.should eql "book-title-1"
      end

      it "ensures no duplicate values are stored in history" do
        book.update_attributes :title => 'Book Title'
        book.update_attributes :title => 'Foo'
        book.slug_history.find_all { |slug| slug == 'book-title' }.size.should eql 1
      end

      context "using find" do
        it "returns the document for the old slug" do
          Book.find("book-title").should == book
        end

        it "returns the document for the new slug" do
          Book.find("other-book-title").should == book
        end
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
        dup.to_param.should eql "gilles-deleuze-1"
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

      context "when using history and reusing a slug within the scope" do
        let!(:subject1) do
          book.subjects.create(:name => "A Subject")
        end
        let!(:subject2) do
          book.subjects.create(:name => "Another Subject")
        end

        before(:each) do
          subject1.name = "Something Else Entirely"
          subject1.save
          subject2.name = "A Subject"
          subject2.save
        end

        it "allows using the slug" do
          subject2.slug.should == "a-subject"
        end

        it "removes the slug from the old owner's history" do
          subject1.slug_history.should_not include("a-subject")
        end
      end
    end

    context "when slug is scoped by one of the class's own fields" do
      let!(:magazine) do
        Magazine.create(:title  => "Big Weekly", :publisher_id => "abc123")
      end

      it "should scope by local field" do
        magazine.to_param.should eql "big-weekly"
        magazine2 = Magazine.create(:title => "Big Weekly", :publisher_id => "def456")
        magazine2.to_param.should eql magazine.to_param
      end

      it "should generate a unique slug by appending a counter to duplicate text" do
        dup = Magazine.create(:title  => "Big Weekly", :publisher_id => "abc123")
        dup.to_param.should eql "big-weekly-1"
      end
    end

    context "when #slug is given a block" do
      let(:caption) do
        Caption.create(:identity => "Edward Hopper (American, 1882-1967)",
                       :title    => "Soir Bleu, 1914",
                       :medium   => "Oil on Canvas")
      end

      it "generates a slug" do
        caption.to_param.should eql "edward-hopper-soir-bleu-1914"
      end

      it "updates the slug" do
        caption.title = "Road in Maine, 1914"
        caption.save
        caption.to_param.should eql "edward-hopper-road-in-maine-1914"
      end

      it "does not change slug if slugged fields have changed but generated slug is identical" do
        caption.identity = "Edward Hopper"
        caption.save
        caption.to_param.should eql "edward-hopper-soir-bleu-1914"
      end

      it "finds by slug" do
        Caption.find_by_slug(caption.to_param).should eql caption
      end

      context "using find" do
        it "finds by slug" do
          Caption.find(caption.to_param).should eql caption
        end
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
        book.to_param.should eql "zhong-wen"
      end

      it "slugs non-ASCII Latin characters" do
        book.title = "Paul Cézanne"
        book.save
        book.to_param.should eql "paul-cezanne"
      end
    end

    context "when :index is passed as an argument" do
      before do
        Book.collection.drop_indexes
        Author.collection.drop_indexes
      end

      context "when slug is not scoped by a reference association" do
        it "defines an index on the slug" do
          Book.create_indexes
          Book.collection.index_information.should have_key "slug_1"
        end

        it "defines a unique index" do
          Book.create_indexes
          Book.index_information["slug_1"]["unique"].should be_true
        end
      end

      context "when slug is scoped by a reference association" do
        it "defines an index on the slug and the scope" do
          Author.create_indexes
          Author.collection.index_information.should have_key "slug_1_book_1"
        end

        it "defines a unique index" do
          Author.create_indexes
          Author.index_information["slug_1_book_1"]["unique"].should be_true
        end
      end
    end

    context "when :index is not passed as an argument" do
      it "does not define an index on the slug" do
        Person.create_indexes
        Person.collection.index_information.should_not have_key "permalink_1"
      end
    end

    context "when :reserve is passed" do
      it "does not use the the reserved slugs" do
        friend1 = Friend.create(:name => "foo")
        friend1.slug.should_not eql("foo")
        friend1.slug.should eql("foo-1")

        friend2 = Friend.create(:name => "bar")
        friend2.slug.should_not eql("bar")
        friend2.slug.should eql("bar-1")

        friend3 = Friend.create(:name => "en")
        friend3.slug.should_not eql("en")
        friend3.slug.should eql("en-1")
      end

      it "should start with concatenation -1" do
        friend1 = Friend.create(:name => "foo")
        friend1.slug.should eql("foo-1")
        friend2 = Friend.create(:name => "foo")
        friend2.slug.should eql("foo-2")
      end
    end

    context "when the object has STI" do
      it "scopes by the superclass" do
        book = Book.create(:title => "Anti Oedipus")
        comic_book = ComicBook.create(:title => "Anti Oedipus")
        comic_book.slug.should_not eql(book.slug)
      end
    end

    context "when slug defined on alias of field" do
      it "should use accessor, not alias" do
        pseudonim  = Alias.create(:author_name => "Max Stirner")
        pseudonim.slug.should eql("max-stirner")
      end
    end

    describe ".by_slug scope" do
      let!(:author) { book.authors.create(:first_name => "Gilles", :last_name  => "Deleuze") }

      it "returns an empty array if no document is found" do
        book.authors.by_slug("never-heard-of").should == []
      end

      it "returns an array containing the document if it is found" do
        book.authors.by_slug(author.slug).should == [author]
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

    describe ".find" do
      let!(:book) { Book.create(:title => "A Thousand Plateaus") }

      it "raises a Mongoid::Errors::DocumentNotFound error if no document is found" do
        lambda {
          Book.find(:title => "Anti Oedipus")
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "returns the document when it is found" do
        Book.find(book.slug).should == book
      end
    end

    context "when #to_param is called on an existing record with no slug" do
      before do
        Book.collection.insert(:title => "Proust and Signs")
      end

      it "generates the missing slug" do
        book = Book.first
        book.to_param
        book.reload.slug.should eql "proust-and-signs"
      end
    end

    describe ".for_unique_slug_for" do
      it "returns the unique slug" do
        Book.find_unique_slug_for("A Thousand Plateaus").should eq("a-thousand-plateaus")
      end

      it "returns the unique slug with a counter if necessary" do
        Book.create(:title => "A Thousand Plateaus")
        Book.find_unique_slug_for("A Thousand Plateaus").should eq("a-thousand-plateaus-1")
      end

      it "returns the unique slug as if it were the provided object" do
        book = Book.create(:title => "A Thousand Plateaus")
        Book.find_unique_slug_for("A Thousand Plateaus", :model => book).should eq("a-thousand-plateaus")
      end
    end

    describe "#find_unique_slug_for" do
      let!(:book) { Book.create(:title => "A Thousand Plateaus") }

      it "returns the unique slug" do
        book.find_unique_slug_for("Anti Oedipus").should eq("anti-oedipus")
      end

      it "returns the unique slug with a counter if necessary" do
        Book.create(:title => "Anti Oedipus")
        book.find_unique_slug_for("Anti Oedipus").should eq("anti-oedipus-1")
      end
    end

    context "when the slugged field is set manually" do
      context "when it set to a non-empty string" do
        it "respects the provided slug" do
          book = Book.create(:title => "A Thousand Plateaus", :slug => "not-what-you-expected")
          book.to_param.should eql "not-what-you-expected"
        end

        it "ensures uniqueness" do
          book1 = Book.create(:title => "A Thousand Plateaus", :slug => "not-what-you-expected")
          book2 = Book.create(:title => "A Thousand Plateaus", :slug => "not-what-you-expected")
          book2.to_param.should eql "not-what-you-expected-1"
        end

        it "updates the slug when a new one is passed in" do
          book = Book.create(:title => "A Thousand Plateaus", :slug => "not-what-you-expected")
          book.slug = "not-it-either"
          book.save
          book.to_param.should eql "not-it-either"
        end
      end

      context "when it is set to an empty string" do
        it "generate a new one" do
          book = Book.create(:title => "A Thousand Plateaus", :slug => "")
          book.to_param.should eql "a-thousand-plateaus"
        end
      end
    end
  end
end
