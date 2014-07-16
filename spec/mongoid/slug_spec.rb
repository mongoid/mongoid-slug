#encoding: utf-8
require "spec_helper"

module Mongoid
  describe Slug do
    let(:book) do
      Book.create(:title => "A Thousand Plateaus")
    end

    context "should not persist incorrect slugs" do
      it "slugs should not be generated from invalid documents" do

        #this will fail now
        x = IncorrectSlugPersistence.create!(name: "test")
        x.slug.should == 'test'

        #I believe this will now fail
        x.name = 'te'
        x.valid?
        x.slug.should_not == 'te'

        #I believe this will persist the 'te'
        x.name = 'testb'
        x.save!

      end

      it "doesn't persist blank strings" do
        book = Book.create!(:title => "")
        book.reload.slugs.should be_empty
      end

    end

    context "when option skip_id_check is used with UUID _id " do
      let(:entity0) do
        Entity.create(:_id => UUID.generate, :name => 'Pelham 1 2 3', :user_edited_variation => 'pelham-1-2-3')
      end
      let(:entity1) do
        Entity.create(:_id => UUID.generate, :name => 'Jackson 5', :user_edited_variation => 'jackson-5')
      end
      let(:entity2) do
        Entity.create(:_id => UUID.generate, :name => 'Jackson 5', :user_edited_variation => 'jackson-5')
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        entity0.to_param.should eql "pelham-1-2-3"

        5.times{ |x|
          dup = Entity.create(:_id => UUID.generate, :name => entity0.name, :user_edited_variation => entity0.user_edited_variation)
          dup.to_param.should eql "pelham-1-2-3-#{x.succ}"
        }
      end

      it "allows the user to edit the sluggable field" do
        entity1.to_param.should eql "jackson-5"
        entity2.to_param.should eql "jackson-5-1"
        entity2.user_edited_variation = "jackson-5-indiana"
        entity2.save
        entity2.to_param.should eql "jackson-5-indiana"
      end

      it "allows users to edit the sluggable field" do
        entity1.to_param.should eql "jackson-5"
        entity2.to_param.should eql "jackson-5-1"
        entity2.user_edited_variation = "jackson-5-indiana"
        entity2.save
        entity2.to_param.should eql "jackson-5-indiana"
      end

      it "it restores the slug if the editing user tries to use an existing slug" do
        entity1.to_param.should eql "jackson-5"
        entity2.to_param.should eql "jackson-5-1"
        entity2.user_edited_variation = "jackson-5"
        entity2.save
        entity2.to_param.should eql "jackson-5-1"
      end

      it "does not force an appended counter on a plain string" do
        entity = Entity.create(:_id => UUID.generate, :name => 'Adele', :user_edited_variation => 'adele')
        entity.to_param.should eql "adele"
      end
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

      it "does not allow a BSON::ObjectId as use for a slug" do
        bson_id = Mongoid::Slug.mongoid3? ? Moped::BSON::ObjectId.new.to_s : BSON::ObjectId.new.to_s
        bad = Book.create(:title => bson_id)
        bad.slugs.should_not include(bson_id)
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

      context "using find" do
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

      it "does not allow a BSON::ObjectId as use for a slug" do
        bad = book.subjects.create(:name => "4ea0389f0364313d79104fb3")
        bad.slugs.should_not eql "4ea0389f0364313d79104fb3"
      end

      it "does not update slug if slugged fields have not changed" do
        subject.save
        subject.to_param.should eql "psychoanalysis"
      end

      it "does not change slug if slugged fields have changed but generated slug is identical" do
        subject.name = "PSYCHOANALYSIS"
        subject.to_param.should eql "psychoanalysis"
      end

      context "using find" do
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

      it "does not allow a BSON::ObjectId as use for a slug" do
        bad = relationship.partners.create(:name => "4ea0389f0364313d79104fb3")
        bad.slugs.should_not eql "4ea0389f0364313d79104fb3"
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

      context "using find" do
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

      it "does not allow a BSON::ObjectId as use for a slug" do
        bad = Author.create(:first_name => "4ea0389f0364",
                            :last_name => "313d79104fb3")
        bad.to_param.should_not eql "4ea0389f0364313d79104fb3"
      end

      it "does not update slug if slugged fields have changed but generated slug is identical" do
        author.last_name = "DELEUZE"
        author.save
        author.to_param.should eql "gilles-deleuze"
      end
    end

    context "when :as is passed as an argument" do
      let!(:person) do
        Person.create(:name => "John Doe")
      end

      it "sets an alternative slug field name" do
        person.should respond_to(:_slugs)
        person.slugs.should eql ["john-doe"]
      end

      it 'defines #slug' do
        person.should respond_to :slugs
      end

      it 'defines #slug_changed?' do
        person.should respond_to :_slugs_changed?
      end

      it 'defines #slug_was' do
        person.should respond_to :_slugs_was
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
        book.slugs.should include("book-title")
      end

      it "generates a unique slug by appending a counter to duplicate text" do
        dup = Book.create(:title => "Book Title")
        dup.to_param.should eql "book-title-1"
      end

      it "does not allow a BSON::ObjectId as use for a slug" do
        bad = Book.create(:title => "4ea0389f0364313d79104fb3")
        bad.to_param.should_not eql "4ea0389f0364313d79104fb3"
      end

      it "ensures no duplicate values are stored in history" do
        book.update_attributes :title => 'Book Title'
        book.update_attributes :title => 'Foo'
        book.slugs.find_all { |slug| slug == 'book-title' }.size.should eql 1
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

      it "does not allow a BSON::ObjectId as use for a slug" do
        bad = book.authors.create(:first_name => "4ea0389f0364",
                                  :last_name => "313d79104fb3")
        bad.to_param.should_not eql "4ea0389f0364313d79104fb3"
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

      it "does not allow a BSON::ObjectId as use for a slug" do
        bad = Magazine.create(:title  => "4ea0389f0364313d79104fb3", :publisher_id => "abc123")
        bad.to_param.should_not eql "4ea0389f0364313d79104fb3"
      end

    end

    context "when #slug is given a block" do
      let(:caption) do
        Caption.create(:my_identity => "Edward Hopper (American, 1882-1967)",
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
        caption.my_identity = "Edward Hopper"
        caption.save
        caption.to_param.should eql "edward-hopper-soir-bleu-1914"
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

    context "when indexes are created" do
      before do
        Author.create_indexes
        Book.create_indexes

        AuthorPolymorphic.create_indexes
        BookPolymorphic.create_indexes
      end

      after do
        Author.remove_indexes
        Book.remove_indexes

        AuthorPolymorphic.remove_indexes
        BookPolymorphic.remove_indexes
      end

      context "when slug is not scoped by a reference association" do
        subject { Book }
        it_should_behave_like "has an index", { _slugs: 1 }, { unique: true, sparse: true }
      end

      context "when slug is scoped by a reference association" do
        subject { Author }
        it_should_behave_like "does not have an index", { _slugs: 1 }
      end

      context "for subclass scope" do
        context "when slug is not scoped by a reference association" do
          subject { BookPolymorphic }
          it_should_behave_like "has an index", { _type: 1, _slugs: 1 }, { unique: nil, sparse: nil }
        end

        context "when slug is scoped by a reference association" do
          subject { AuthorPolymorphic }
          it_should_behave_like "does not have an index", { _type: 1, _slugs: 1 }
        end

        context "when the object has STI" do
          it "scopes by the subclass" do
            b = BookPolymorphic.create!(title: 'Book')
            b.slug.should == 'book'

            b2 = BookPolymorphic.create!(title: 'Book')
            b2.slug.should == 'book-1'

            c = ComicBookPolymorphic.create!(title: 'Book')
            c.slug.should == 'book'

            c2 = ComicBookPolymorphic.create!(title: 'Book')
            c2.slug.should == 'book-1'

            BookPolymorphic.find('book').should == b
            BookPolymorphic.find('book-1').should == b2
            ComicBookPolymorphic.find('book').should == c
            ComicBookPolymorphic.find('book-1').should == c2
          end
        end
      end
    end

    context "for reserved words" do
      context "when the :reserve option is used on the model" do
        it "does not use the reserved slugs" do
          friend1 = Friend.create(:name => "foo")
          friend1.slugs.should_not include("foo")
          friend1.slugs.should include("foo-1")

          friend2 = Friend.create(:name => "bar")
          friend2.slugs.should_not include("bar")
          friend2.slugs.should include("bar-1")

          friend3 = Friend.create(:name => "en")
          friend3.slugs.should_not include("en")
          friend3.slugs.should include("en-1")
        end

        it "should start with concatenation -1" do
          friend1 = Friend.create(:name => "foo")
          friend1.slugs.should include("foo-1")
          friend2 = Friend.create(:name => "foo")
          friend2.slugs.should include("foo-2")
        end

        ["new", "edit"].each do |word|
          it "should overwrite the default reserved words allowing the word '#{word}'" do
            friend = Friend.create(:name => word)
            friend.slugs.should include word
          end
        end
      end
      context "when the model does not have any reserved words set" do
        ["new", "edit"].each do |word|
          it "does not use the default reserved word '#{word}'" do
            book = Book.create(:title => word)
            book.slugs.should_not include word
            book.slugs.should include("#{word}-1")
          end
        end
      end
    end

    context "when the object has STI" do
      it "scopes by the superclass" do
        book = Book.create(:title => "Anti Oedipus")
        comic_book = ComicBook.create(:title => "Anti Oedipus")
        comic_book.slugs.should_not eql(book.slugs)
      end

      it "scopes by the subclass" do
        book = BookPolymorphic.create(:title => "Anti Oedipus")
        comic_book = ComicBookPolymorphic.create(:title => "Anti Oedipus")
        comic_book.slugs.should eql(book.slugs)

        BookPolymorphic.find(book.slug).should == book
        ComicBookPolymorphic.find(comic_book.slug).should == comic_book
      end
    end

    context "when slug defined on alias of field" do
      it "should use accessor, not alias" do
        pseudonim  = Alias.create(:author_name => "Max Stirner")
        pseudonim.slugs.should include("max-stirner")
      end
    end

    describe "#to_param" do
      context "when called on a new record" do
        let(:book) { Book.new }

        it "should return nil" do
          book.to_param.should be_nil
        end

        it "should not persist the record" do
          book.to_param
          book.should_not be_persisted
        end

      end

      context "when called on an existing record with no slug" do
        let!(:book_no_title) { Book.create() }

        before do
          Book.collection.insert(:title => "Proust and Signs")
        end

        it "should return the id if there is no slug" do
          book = Book.first
          book.to_param.should == book.id.to_s
          book.reload.slugs.should be_empty
        end

        it "should not persist the record" do
          book_no_title.to_param.should == book_no_title._id.to_s
        end
      end
    end

    describe "#_slugs_changed?" do
      before do
        Book.create(:title => "A Thousand Plateaus")
      end

      let(:book) { Book.first }

      it "is initially unchanged" do
        book._slugs_changed?.should be_falsey
      end

      it "tracks changes" do
        book.slugs = ["Anti Oedipus"]
        book._slugs_changed?.should be_truthy
      end
    end

    describe "when regular expression matches, but document does not" do
      let!(:book_1) { Book.create(:title => "book-1") }
      let!(:book_2) { Book.create(:title => "book") }
      let!(:book_3) { Book.create(:title => "book") }

      it "book_2 should have the user supplied title without -1 after it" do
        book_2.to_param.should eql "book"
      end

      it "book_3 should have a generated slug" do
        book_3.to_param.should eql "book-2"
      end
    end

    context "when the slugged field is set manually" do
      context "when it set to a non-empty string" do
        it "respects the provided slug" do
          book = Book.create(:title => "A Thousand Plateaus", :slugs => ["not-what-you-expected"])
          book.to_param.should eql "not-what-you-expected"
        end

        it "ensures uniqueness" do
          book1 = Book.create(:title => "A Thousand Plateaus", :slugs => ["not-what-you-expected"])
          book2 = Book.create(:title => "A Thousand Plateaus", :slugs => ["not-what-you-expected"])
          book2.to_param.should eql "not-what-you-expected-1"
        end

        it "updates the slug when a new one is passed in" do
          book = Book.create(:title => "A Thousand Plateaus", :slugs => ["not-what-you-expected"])
          book.slugs = ["not-it-either"]
          book.save
          book.to_param.should eql "not-it-either"
        end

        it "updates the slug when a new one is appended" do
          book = Book.create(:title => "A Thousand Plateaus", :slugs => ["not-what-you-expected"])
          book.slugs.push "not-it-either"
          book.save
          book.to_param.should eql "not-it-either"
        end

        it "updates the slug to a unique slug when a new one is appended" do
          book1 = Book.create(:title => "Sleepyhead")
          book2 = Book.create(:title => "A Thousand Plateaus")
          book2.slugs.push "sleepyhead"
          book2.save
          book2.to_param.should eql "sleepyhead-1"
        end
      end

      context "when it is set to an empty string" do
        it "generate a new one" do
          book = Book.create(:title => "A Thousand Plateaus")
          book.to_param.should eql "a-thousand-plateaus"
        end
      end
    end

    context "slug can be localized" do
      before(:each) do
        @old_locale = I18n.locale
      end

      after(:each) do
        I18n.locale = @old_locale
      end

      it "generates a new slug for each localization" do
        page = PageSlugLocalized.new
        page.title = "Title on English"
        page.save
        page.slug.should eql "title-on-english"
        I18n.locale = :nl
        page.title = "Title on Netherlands"
        page.save
        page.slug.should eql "title-on-netherlands"
      end

      it "returns _id if no slug" do
        page = PageSlugLocalized.new
        page.title = "Title on English"
        page.save
        page.slug.should eql "title-on-english"
        I18n.locale = :nl
        page.slug.should eql page._id.to_s
      end

      it "fallbacks if slug not localized yet" do
        page = PageSlugLocalized.new
        page.title = "Title on English"
        page.save
        page.slug.should eql "title-on-english"
        I18n.locale = :nl
        page.slug.should eql page._id.to_s

        # Turn on i18n fallback
        require "i18n/backend/fallbacks"
        I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
        ::I18n.fallbacks[:nl] = [ :nl, :en ]
        page.slug.should eql "title-on-english"
        fallback_slug = page.slug

        fallback_page = PageSlugLocalized.find(fallback_slug) rescue nil
        fallback_page.should eq(page)

        # Restore fallback for next tests
        ::I18n.fallbacks[:nl] = [ :nl ]
      end

      it "returns a default slug if not localized" do
        page = PageLocalize.new
        page.title = "Title on English"
        page.save
        page.slug.should eql "title-on-english"
        I18n.locale = :nl
        page.title = "Title on Netherlands"
        page.slug.should eql "title-on-english"
        page.save
        page.slug.should eql "title-on-netherlands"
      end

      it "slugs properly when translations are set directly" do
        page = PageSlugLocalized.new
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page["_slugs"].should == {"en" => ["title-on-english"], "nl" => ["title-on-netherlands"]}
      end

      it "exact same title multiple langauges" do
        page = PageSlugLocalized.new
        page.title_translations = {"en" => "Title on English", "nl" => "Title on English"}
        page.save
        page["_slugs"].should == {"en" => ["title-on-english"], "nl" => ["title-on-english"]}

        page = PageSlugLocalized.create(title_translations: {"en" => "Title on English2", "nl" => "Title on English2"})
        page["_slugs"].should == {"en" => ["title-on-english2"], "nl" => ["title-on-english2"]}
      end



      it "does not produce duplicate slugs" do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalized.new
        page.title = "Title on English"
        page.save
        I18n.locale = "nl"
        page.title = "Title on Netherlands"
        page.save
        page.title_translations.should == {"en" => "Title on English", "nl" => "Title on Netherlands"}

        I18n.locale = old_locale
        page.title = "Title on English"
        page.title_translations.should == {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page["_slugs"].should == {"en" => ["title-on-english"], "nl" => ["title-on-netherlands"]}
      end

      it "does not produce duplicate slugs when one has changed" do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalized.new
        page.title = "Title on English"
        page.save
        I18n.locale = "nl"
        page.title = "Title on Netherlands"
        page.save
        page.title_translations.should == {"en" => "Title on English", "nl" => "Title on Netherlands"}

        I18n.locale = old_locale
        page.title = "Modified Title on English"
        page.save
        page.title_translations.should == {"en" => "Modified Title on English",
                                           "nl" => "Title on Netherlands"}
        page["_slugs"].should == {"en" => ["modified-title-on-english"],
                                  "nl" => ["title-on-netherlands"]}
      end

      it "does not produce duplicate slugs when transactions are set directly" do
        page = PageSlugLocalized.new
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page["_slugs"].should == {"en" => ["title-on-english"], "nl" => ["title-on-netherlands"]}
      end

      it "does not produce duplicate slugs when transactions are set directly and one has changed" do
        page = PageSlugLocalized.new
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page.title_translations = {"en" => "Modified Title on English",
                                   "nl" => "Title on Netherlands"}
        page.save
        page["_slugs"].should == {"en" => ["modified-title-on-english"],
                                  "nl" => ["title-on-netherlands"]}
      end

      it "works with a custom slug strategy" do
        page = PageSlugLocalizedCustom.new
        page.title = "a title for the slug"
        page.save
        page["_slugs"].should == {"en" => ["a-title-for-the-slug"], "nl"=>["a-title-for-the-slug"]}
      end
    end

    context "slug can be localized when using history" do
      before(:each) do
        @old_locale = I18n.locale
      end

      after(:each) do
        I18n.locale = @old_locale
      end

      it "generate a new slug for each localization and keep history" do
        old_locale = I18n.locale

        page = PageSlugLocalizedHistory.new
        page.title = "Title on English"
        page.save
        page.slug.should eql "title-on-english"
        I18n.locale = :nl
        page.title = "Title on Netherlands"
        page.save
        page.slug.should eql "title-on-netherlands"
        I18n.locale = old_locale
        page.title = "Modified title on English"
        page.save
        page.slug.should eql "modified-title-on-english"
        page.slug.should include("title-on-english")
        I18n.locale = :nl
        page.title = "Modified title on Netherlands"
        page.save
        page.slug.should eql "modified-title-on-netherlands"
        page.slug.should include("title-on-netherlands")
      end

      it "returns _id if no slug" do
        page = PageSlugLocalizedHistory.new
        page.title = "Title on English"
        page.save
        page.slug.should eql "title-on-english"
        I18n.locale = :nl
        page.slug.should eql page._id.to_s
      end

      it "fallbacks if slug not localized yet" do
        page = PageSlugLocalizedHistory.new
        page.title = "Title on English"
        page.save
        page.slug.should eql "title-on-english"
        I18n.locale = :nl
        page.slug.should eql page._id.to_s

        # Turn on i18n fallback
        require "i18n/backend/fallbacks"
        I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
        ::I18n.fallbacks[:nl] = [ :nl, :en ]
        page.slug.should eql "title-on-english"
        fallback_slug = page.slug

        fallback_page = PageSlugLocalizedHistory.find(fallback_slug) rescue nil
        fallback_page.should eq(page)
      end

      it "slugs properly when translations are set directly" do
        page = PageSlugLocalizedHistory.new
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page.title_translations = {"en" => "Modified Title on English",
                                   "nl" => "Modified Title on Netherlands"}
        page.save
        page["_slugs"].should == {"en" => ["title-on-english", "modified-title-on-english"],
                                  "nl" => ["title-on-netherlands", "modified-title-on-netherlands"]}
      end

      it "does not produce duplicate slugs" do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalizedHistory.new
        page.title = "Title on English"
        page.save
        I18n.locale = "nl"
        page.title = "Title on Netherlands"
        page.save
        page.title_translations.should == {"en" => "Title on English", "nl" => "Title on Netherlands"}

        I18n.locale = old_locale
        page.title = "Title on English"
        page.title_translations.should == {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page["_slugs"].should == {"en" => ["title-on-english"], "nl" => ["title-on-netherlands"]}
      end

      it "does not produce duplicate slugs when one has changed" do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalizedHistory.new
        page.title = "Title on English"
        page.save
        I18n.locale = "nl"
        page.title = "Title on Netherlands"
        page.save
        page.title_translations.should == {"en" => "Title on English", "nl" => "Title on Netherlands"}

        I18n.locale = old_locale
        page.title = "Modified Title on English"
        page.save
        page.title_translations.should == {"en" => "Modified Title on English",
                                           "nl" => "Title on Netherlands"}
        page["_slugs"].should == {"en" => ["title-on-english", "modified-title-on-english"],
                                  "nl" => ["title-on-netherlands"]}
      end

      it "does not produce duplicate slugs when transactions are set directly" do
        page = PageSlugLocalizedHistory.new
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page["_slugs"].should == {"en" => ["title-on-english"], "nl" => ["title-on-netherlands"]}
      end

      it "does not produce duplicate slugs when transactions are set directly and one has changed" do
        page = PageSlugLocalizedHistory.new
        page.title_translations = {"en" => "Title on English", "nl" => "Title on Netherlands"}
        page.save
        page.title_translations = {"en" => "Modified Title on English", "nl" => "Title on Netherlands"}
        page.save
        page["_slugs"].should == {"en" => ["title-on-english", "modified-title-on-english"],
                                  "nl" => ["title-on-netherlands"]}
      end

    end
  end
end
