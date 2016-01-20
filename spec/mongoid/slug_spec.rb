# encoding: utf-8
require 'spec_helper'

module Mongoid
  describe Slug do
    let(:book) do
      Book.create(title: 'A Thousand Plateaus')
    end

    context 'should not persist incorrect slugs' do
      it 'slugs should not be generated from invalid documents' do
        # this will fail now
        x = IncorrectSlugPersistence.create!(name: 'test')
        expect(x.slug).to eq('test')

        # I believe this will now fail
        x.name = 'te'
        x.valid?
        expect(x.slug).not_to eq('te')

        # I believe this will persist the 'te'
        x.name = 'testb'
        x.save!
      end

      it "doesn't persist blank strings" do
        book = Book.create!(title: '')
        expect(book.reload.slugs).to be_empty
      end
    end

    context 'when option skip_id_check is used with UUID _id ' do
      let(:entity0) do
        Entity.create(_id: UUID.generate, name: 'Pelham 1 2 3', user_edited_variation: 'pelham-1-2-3')
      end
      let(:entity1) do
        Entity.create(_id: UUID.generate, name: 'Jackson 5', user_edited_variation: 'jackson-5')
      end
      let(:entity2) do
        Entity.create(_id: UUID.generate, name: 'Jackson 5', user_edited_variation: 'jackson-5')
      end

      it 'generates a unique slug by appending a counter to duplicate text' do
        expect(entity0.to_param).to eql 'pelham-1-2-3'

        5.times do |x|
          dup = Entity.create(_id: UUID.generate, name: entity0.name, user_edited_variation: entity0.user_edited_variation)
          expect(dup.to_param).to eql "pelham-1-2-3-#{x.succ}"
        end
      end

      it 'allows the user to edit the sluggable field' do
        expect(entity1.to_param).to eql 'jackson-5'
        expect(entity2.to_param).to eql 'jackson-5-1'
        entity2.user_edited_variation = 'jackson-5-indiana'
        entity2.save
        expect(entity2.to_param).to eql 'jackson-5-indiana'
      end

      it 'allows users to edit the sluggable field' do
        expect(entity1.to_param).to eql 'jackson-5'
        expect(entity2.to_param).to eql 'jackson-5-1'
        entity2.user_edited_variation = 'jackson-5-indiana'
        entity2.save
        expect(entity2.to_param).to eql 'jackson-5-indiana'
      end

      it 'it restores the slug if the editing user tries to use an existing slug' do
        expect(entity1.to_param).to eql 'jackson-5'
        expect(entity2.to_param).to eql 'jackson-5-1'
        entity2.user_edited_variation = 'jackson-5'
        entity2.save
        expect(entity2.to_param).to eql 'jackson-5-1'
      end

      it 'does not force an appended counter on a plain string' do
        entity = Entity.create(_id: UUID.generate, name: 'Adele', user_edited_variation: 'adele')
        expect(entity.to_param).to eql 'adele'
      end
    end

    context 'when the object is top-level' do
      it 'generates a slug' do
        expect(book.to_param).to eql 'a-thousand-plateaus'
      end

      it 'updates the slug' do
        book.title = 'Anti Oedipus'
        book.save
        expect(book.to_param).to eql 'anti-oedipus'
      end

      it 'generates a unique slug by appending a counter to duplicate text' do
        15.times do |x|
          dup = Book.create(title: book.title)
          expect(dup.to_param).to eql "a-thousand-plateaus-#{x + 1}"
        end
      end

      it 'does not allow a BSON::ObjectId as use for a slug' do
        bson_id = Mongoid::Compatibility::Version.mongoid3? ? Moped::BSON::ObjectId.new.to_s : BSON::ObjectId.new.to_s
        bad = Book.create(title: bson_id)
        expect(bad.slugs).not_to include(bson_id)
      end

      it 'does not update slug if slugged fields have not changed' do
        book.save
        expect(book.to_param).to eql 'a-thousand-plateaus'
      end

      it 'does not change slug if slugged fields have changed but generated slug is identical' do
        book.title = 'a thousand plateaus'
        book.save
        expect(book.to_param).to eql 'a-thousand-plateaus'
      end

      context 'using find' do
        it 'finds by id as string' do
          expect(Book.find(book.id.to_s)).to eql book
        end

        it 'finds by id as array of strings' do
          expect(Book.find([book.id.to_s])).to eql [book]
        end

        it 'finds by id as BSON::ObjectId' do
          expect(Book.find(book.id)).to eql book
        end

        it 'finds by id as an array of BSON::ObjectIds' do
          expect(Book.find([book.id])).to eql [book]
        end

        it 'returns an empty array if given an empty array' do
          expect(Book.find([])).to eql []
        end
      end
    end

    context 'when the object is embedded' do
      let(:subject) do
        book.subjects.create(name: 'Psychoanalysis')
      end

      it 'generates a slug' do
        expect(subject.to_param).to eql 'psychoanalysis'
      end

      it 'updates the slug' do
        subject.name = 'Schizoanalysis'
        subject.save
        expect(subject.to_param).to eql 'schizoanalysis'
      end

      it 'generates a unique slug by appending a counter to duplicate text' do
        dup = book.subjects.create(name: subject.name)
        expect(dup.to_param).to eql 'psychoanalysis-1'
      end

      it 'does not allow a BSON::ObjectId as use for a slug' do
        bad = book.subjects.create(name: '4ea0389f0364313d79104fb3')
        expect(bad.slugs).not_to eql '4ea0389f0364313d79104fb3'
      end

      it 'does not update slug if slugged fields have not changed' do
        subject.save
        expect(subject.to_param).to eql 'psychoanalysis'
      end

      it 'does not change slug if slugged fields have changed but generated slug is identical' do
        subject.name = 'PSYCHOANALYSIS'
        expect(subject.to_param).to eql 'psychoanalysis'
      end

      context 'using find' do
        it 'finds by id as string' do
          expect(book.subjects.find(subject.id.to_s)).to eql subject
        end

        it 'finds by id as array of strings' do
          expect(book.subjects.find([subject.id.to_s])).to eql [subject]
        end

        it 'finds by id as BSON::ObjectId' do
          expect(book.subjects.find(subject.id)).to eql subject
        end

        it 'finds by id as an array of BSON::ObjectIds' do
          expect(book.subjects.find([subject.id])).to eql [subject]
        end

        it 'returns an empty array if given an empty array' do
          expect(book.subjects.find([])).to eql []
        end
      end
    end

    context 'when the object is embedded in another embedded object' do
      let(:person) do
        Person.create(name: 'John Doe')
      end

      let(:relationship) do
        person.relationships.create(name: 'Engagement')
      end

      let(:partner) do
        relationship.partners.create(name: 'Jane Smith')
      end

      it 'generates a slug' do
        expect(partner.to_param).to eql 'jane-smith'
      end

      it 'updates the slug' do
        partner.name = 'Jane Doe'
        partner.save
        expect(partner.to_param).to eql 'jane-doe'
      end

      it 'generates a unique slug by appending a counter to duplicate text' do
        dup = relationship.partners.create(name: partner.name)
        expect(dup.to_param).to eql 'jane-smith-1'
      end

      it 'does not allow a BSON::ObjectId as use for a slug' do
        bad = relationship.partners.create(name: '4ea0389f0364313d79104fb3')
        expect(bad.slugs).not_to eql '4ea0389f0364313d79104fb3'
      end

      it 'does not update slug if slugged fields have not changed' do
        partner.save
        expect(partner.to_param).to eql 'jane-smith'
      end

      it 'does not change slug if slugged fields have changed but generated slug is identical' do
        partner.name = 'JANE SMITH'
        expect(partner.to_param).to eql 'jane-smith'
      end

      it 'scopes by parent object' do
        affair = person.relationships.create(name: 'Affair')
        lover = affair.partners.create(name: partner.name)
        expect(lover.to_param).to eql partner.to_param
      end

      context 'using find' do
        it 'finds by id as string' do
          expect(relationship.partners.find(partner.id.to_s)).to eql partner
        end

        it 'finds by id as array of strings' do
          expect(relationship.partners.find([partner.id.to_s])).to eql [partner]
        end

        it 'finds by id as BSON::ObjectId' do
          expect(relationship.partners.find(partner.id)).to eql partner
        end

        it 'finds by id as an array of BSON::ObjectIds' do
          expect(relationship.partners.find([partner.id])).to eql [partner]
        end

        it 'returns an empty array if given an empty array' do
          expect(relationship.partners.find([])).to eql []
        end
      end
    end

    context 'when the slug is composed of multiple fields' do
      let!(:author) do
        Author.create(
          first_name: 'Gilles',
          last_name: 'Deleuze')
      end

      it 'generates a slug' do
        expect(author.to_param).to eql 'gilles-deleuze'
      end

      it 'updates the slug' do
        author.first_name = 'Félix'
        author.last_name  = 'Guattari'
        author.save
        expect(author.to_param).to eql 'felix-guattari'
      end

      it 'generates a unique slug by appending a counter to duplicate text' do
        dup = Author.create(
          first_name: author.first_name,
          last_name: author.last_name)
        expect(dup.to_param).to eql 'gilles-deleuze-1'

        dup2 = Author.create(
          first_name: author.first_name,
          last_name: author.last_name)

        dup.save
        expect(dup2.to_param).to eql 'gilles-deleuze-2'
      end

      it 'does not allow a BSON::ObjectId as use for a slug' do
        bad = Author.create(first_name: '4ea0389f0364',
                            last_name: '313d79104fb3')
        expect(bad.to_param).not_to eql '4ea0389f0364313d79104fb3'
      end

      it 'does not update slug if slugged fields have changed but generated slug is identical' do
        author.last_name = 'DELEUZE'
        author.save
        expect(author.to_param).to eql 'gilles-deleuze'
      end
    end

    context 'when :as is passed as an argument' do
      let!(:person) do
        Person.create(name: 'John Doe')
      end

      it 'sets an alternative slug field name' do
        expect(person).to respond_to(:_slugs)
        expect(person.slugs).to eql ['john-doe']
      end

      it 'defines #slug' do
        expect(person).to respond_to :slugs
      end

      it 'defines #slug_changed?' do
        expect(person).to respond_to :_slugs_changed?
      end

      it 'defines #slug_was' do
        expect(person).to respond_to :_slugs_was
      end
    end

    context 'when :permanent is passed as an argument' do
      let(:person) do
        Person.create(name: 'John Doe')
      end

      it 'does not update the slug when the slugged fields change' do
        person.name = 'Jane Doe'
        person.save
        expect(person.to_param).to eql 'john-doe'
      end
    end

    context 'when :history is passed as an argument' do
      context 'true' do
        let(:book) do
          Book.create(title: 'Book Title')
        end

        before(:each) do
          book.title = 'Other Book Title'
          book.save
        end

        it "saves the old slug in the owner's history" do
          expect(book.slugs).to include('book-title')
        end

        it 'generates a unique slug by appending a counter to duplicate text' do
          dup = Book.create(title: 'Book Title')
          expect(dup.to_param).to eql 'book-title-1'
        end

        it 'does not allow a BSON::ObjectId as use for a slug' do
          bad = Book.create(title: '4ea0389f0364313d79104fb3')
          expect(bad.to_param).not_to eql '4ea0389f0364313d79104fb3'
        end

        it 'ensures no duplicate values are stored in history' do
          book.update_attributes title: 'Book Title'
          book.update_attributes title: 'Foo'
          expect(book.slugs.find_all { |slug| slug == 'book-title' }.size).to eql 1
        end
      end
      context 'false' do
        let(:author) do
          Author.create(first_name: 'Gilles', last_name: 'Deleuze')
        end

        before(:each) do
          author.first_name = 'John'
          author.save
        end

        it "does not save the old slug in the owner's history" do
          expect(author.slugs.count).to eq 1
          expect(author.slugs).to_not include('gilles-deleuze')
        end
      end
    end

    context 'when slug is scoped by a reference association' do
      let(:author) do
        book.authors.create(first_name: 'Gilles', last_name: 'Deleuze')
      end

      it 'scopes by parent object' do
        book2 = Book.create(title: 'Anti Oedipus')
        dup = book2.authors.create(
          first_name: author.first_name,
          last_name: author.last_name
        )
        expect(dup.to_param).to eql author.to_param
      end

      it 'generates a unique slug by appending a counter to duplicate text' do
        dup = book.authors.create(
          first_name: author.first_name,
          last_name: author.last_name)
        expect(dup.to_param).to eql 'gilles-deleuze-1'
      end

      it 'does not allow a BSON::ObjectId as use for a slug' do
        bad = book.authors.create(first_name: '4ea0389f0364',
                                  last_name: '313d79104fb3')
        expect(bad.to_param).not_to eql '4ea0389f0364313d79104fb3'
      end

      context 'with an irregular association name' do
        let(:character) do
          # well we've got to make up something... :-)
          author.characters.create(name: 'Oedipus')
        end

        let!(:author2) do
          Author.create(
            first_name: 'Sophocles',
            last_name: 'son of Sophilos'
          )
        end

        it 'scopes by parent object provided that inverse_of is specified' do
          dup = author2.characters.create(name: character.name)
          expect(dup.to_param).to eql character.to_param
        end
      end
    end

    context "when slug is scoped by one of the class's own fields" do
      let!(:magazine) do
        Magazine.create(title: 'Big Weekly', publisher_id: 'abc123')
      end

      it 'should scope by local field' do
        expect(magazine.to_param).to eql 'big-weekly'
        magazine2 = Magazine.create(title: 'Big Weekly', publisher_id: 'def456')
        expect(magazine2.to_param).to eql magazine.to_param
      end

      it 'should generate a unique slug by appending a counter to duplicate text' do
        dup = Magazine.create(title: 'Big Weekly', publisher_id: 'abc123')
        expect(dup.to_param).to eql 'big-weekly-1'
      end

      it 'does not allow a BSON::ObjectId as use for a slug' do
        bad = Magazine.create(title: '4ea0389f0364313d79104fb3', publisher_id: 'abc123')
        expect(bad.to_param).not_to eql '4ea0389f0364313d79104fb3'
      end
    end

    context 'when #slug is given a block' do
      let(:caption) do
        Caption.create(my_identity: 'Edward Hopper (American, 1882-1967)',
                       title: 'Soir Bleu, 1914',
                       medium: 'Oil on Canvas')
      end

      it 'generates a slug' do
        expect(caption.to_param).to eql 'edward-hopper-soir-bleu-1914'
      end

      it 'updates the slug' do
        caption.title = 'Road in Maine, 1914'
        caption.save
        expect(caption.to_param).to eql 'edward-hopper-road-in-maine-1914'
      end

      it 'does not change slug if slugged fields have changed but generated slug is identical' do
        caption.my_identity = 'Edward Hopper'
        caption.save
        expect(caption.to_param).to eql 'edward-hopper-soir-bleu-1914'
      end
    end

    context 'when slugged field contains non-ASCII characters' do
      it 'slugs Cyrillic characters' do
        book.title = 'Капитал'
        book.save
        expect(book.to_param).to eql 'kapital'
      end

      it 'slugs Greek characters' do
        book.title = 'Ελλάδα'
        book.save
        expect(book.to_param).to eql 'ellada'
      end

      it 'slugs Chinese characters' do
        book.title = '中文'
        book.save
        expect(book.to_param).to eql 'zhong-wen'
      end

      it 'slugs non-ASCII Latin characters' do
        book.title = 'Paul Cézanne'
        book.save
        expect(book.to_param).to eql 'paul-cezanne'
      end
    end

    context 'when indexes are created' do
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

      context 'when slug is not scoped by a reference association' do
        subject { Book }
        it_should_behave_like 'has an index', { _slugs: 1 }, unique: true, sparse: true
      end

      context 'when slug is scoped by a reference association' do
        subject { Author }
        it_should_behave_like 'does not have an index', _slugs: 1
      end

      context 'for subclass scope' do
        context 'when slug is not scoped by a reference association' do
          subject { BookPolymorphic }
          it_should_behave_like 'has an index', { _type: 1, _slugs: 1 }, unique: nil, sparse: nil
        end

        context 'when slug is scoped by a reference association' do
          subject { AuthorPolymorphic }
          it_should_behave_like 'does not have an index', _type: 1, _slugs: 1
        end

        context 'when the object has STI' do
          it 'scopes by the subclass' do
            b = BookPolymorphic.create!(title: 'Book')
            expect(b.slug).to eq('book')

            b2 = BookPolymorphic.create!(title: 'Book')
            expect(b2.slug).to eq('book-1')

            c = ComicBookPolymorphic.create!(title: 'Book')
            expect(c.slug).to eq('book')

            c2 = ComicBookPolymorphic.create!(title: 'Book')
            expect(c2.slug).to eq('book-1')

            expect(BookPolymorphic.find('book')).to eq(b)
            expect(BookPolymorphic.find('book-1')).to eq(b2)
            expect(ComicBookPolymorphic.find('book')).to eq(c)
            expect(ComicBookPolymorphic.find('book-1')).to eq(c2)
          end
        end
      end
    end

    context 'for reserved words' do
      context 'when the :reserve option is used on the model' do
        it 'does not use the reserved slugs' do
          friend1 = Friend.create(name: 'foo')
          expect(friend1.slugs).not_to include('foo')
          expect(friend1.slugs).to include('foo-1')

          friend2 = Friend.create(name: 'bar')
          expect(friend2.slugs).not_to include('bar')
          expect(friend2.slugs).to include('bar-1')

          friend3 = Friend.create(name: 'en')
          expect(friend3.slugs).not_to include('en')
          expect(friend3.slugs).to include('en-1')
        end

        it 'should start with concatenation -1' do
          friend1 = Friend.create(name: 'foo')
          expect(friend1.slugs).to include('foo-1')
          friend2 = Friend.create(name: 'foo')
          expect(friend2.slugs).to include('foo-2')
        end

        %w(new edit).each do |word|
          it "should overwrite the default reserved words allowing the word '#{word}'" do
            friend = Friend.create(name: word)
            expect(friend.slugs).to include word
          end
        end
      end
      context 'when the model does not have any reserved words set' do
        %w(new edit).each do |word|
          it "does not use the default reserved word '#{word}'" do
            book = Book.create(title: word)
            expect(book.slugs).not_to include word
            expect(book.slugs).to include("#{word}-1")
          end
        end
      end
    end

    context 'when the object has STI' do
      it 'scopes by the superclass' do
        book = Book.create(title: 'Anti Oedipus')
        comic_book = ComicBook.create(title: 'Anti Oedipus')
        expect(comic_book.slugs).not_to eql(book.slugs)
      end

      it 'scopes by the subclass' do
        book = BookPolymorphic.create(title: 'Anti Oedipus')
        comic_book = ComicBookPolymorphic.create(title: 'Anti Oedipus')
        expect(comic_book.slugs).to eql(book.slugs)

        expect(BookPolymorphic.find(book.slug)).to eq(book)
        expect(ComicBookPolymorphic.find(comic_book.slug)).to eq(comic_book)
      end
    end

    context 'when slug defined on alias of field' do
      it 'should use accessor, not alias' do
        pseudonim = Alias.create(author_name: 'Max Stirner')
        expect(pseudonim.slugs).to include('max-stirner')
      end
    end

    describe '#to_param' do
      context 'when called on a new record' do
        let(:book) { Book.new }

        it 'should return nil' do
          expect(book.to_param).to be_nil
        end

        it 'should not persist the record' do
          book.to_param
          expect(book).not_to be_persisted
        end
      end

      context 'when called on an existing record with no slug' do
        let!(:book_no_title) { Book.create }

        before do
          if Mongoid::Compatibility::Version.mongoid5?
            Book.collection.insert_one(title: 'Proust and Signs')
          else
            Book.collection.insert(title: 'Proust and Signs')
          end
        end

        it 'should return the id if there is no slug' do
          book = Book.first
          expect(book.to_param).to eq(book.id.to_s)
          expect(book.reload.slugs).to be_empty
        end

        it 'should not persist the record' do
          expect(book_no_title.to_param).to eq(book_no_title._id.to_s)
        end
      end
    end

    describe '#_slugs_changed?' do
      before do
        Book.create(title: 'A Thousand Plateaus')
      end

      let(:book) { Book.first }

      it 'is initially unchanged' do
        expect(book._slugs_changed?).to be_falsey
      end

      it 'tracks changes' do
        book.slugs = ['Anti Oedipus']
        expect(book._slugs_changed?).to be_truthy
      end
    end

    describe 'when regular expression matches, but document does not' do
      let!(:book_1) { Book.create(title: 'book-1') }
      let!(:book_2) { Book.create(title: 'book') }
      let!(:book_3) { Book.create(title: 'book') }

      it 'book_2 should have the user supplied title without -1 after it' do
        expect(book_2.to_param).to eql 'book'
      end

      it 'book_3 should have a generated slug' do
        expect(book_3.to_param).to eql 'book-2'
      end
    end

    context 'when the slugged field is set manually' do
      context 'when it set to a non-empty string' do
        it 'respects the provided slug' do
          book = Book.create(title: 'A Thousand Plateaus', slugs: ['not-what-you-expected'])
          expect(book.to_param).to eql 'not-what-you-expected'
        end

        it 'ensures uniqueness' do
          Book.create(title: 'A Thousand Plateaus', slugs: ['not-what-you-expected'])
          book2 = Book.create(title: 'A Thousand Plateaus', slugs: ['not-what-you-expected'])
          expect(book2.to_param).to eql 'not-what-you-expected-1'
        end

        it 'updates the slug when a new one is passed in' do
          book = Book.create(title: 'A Thousand Plateaus', slugs: ['not-what-you-expected'])
          book.slugs = ['not-it-either']
          book.save
          expect(book.to_param).to eql 'not-it-either'
        end

        it 'updates the slug when a new one is appended' do
          book = Book.create(title: 'A Thousand Plateaus', slugs: ['not-what-you-expected'])
          book.slugs.push 'not-it-either'
          book.save
          expect(book.to_param).to eql 'not-it-either'
        end

        it 'updates the slug to a unique slug when a new one is appended' do
          Book.create(title: 'Sleepyhead')
          book2 = Book.create(title: 'A Thousand Plateaus')
          book2.slugs.push 'sleepyhead'
          book2.save
          expect(book2.to_param).to eql 'sleepyhead-1'
        end
      end

      context 'when it is set to an empty string' do
        it 'generate a new one' do
          book = Book.create(title: 'A Thousand Plateaus')
          expect(book.to_param).to eql 'a-thousand-plateaus'
        end
      end
    end

    context 'slug can be localized' do
      before(:each) do
        @old_locale = I18n.locale
      end

      after(:each) do
        I18n.locale = @old_locale
      end

      it 'generates a new slug for each localization' do
        page = PageSlugLocalized.new
        page.title = 'Title on English'
        page.save
        expect(page.slug).to eql 'title-on-english'
        I18n.locale = :nl
        page.title = 'Title on Netherlands'
        page.save
        expect(page.slug).to eql 'title-on-netherlands'
      end

      it 'returns _id if no slug' do
        page = PageSlugLocalized.new
        page.title = 'Title on English'
        page.save
        expect(page.slug).to eql 'title-on-english'
        I18n.locale = :nl
        expect(page.slug).to eql page._id.to_s
      end

      it 'fallbacks if slug not localized yet' do
        page = PageSlugLocalized.new
        page.title = 'Title on English'
        page.save
        expect(page.slug).to eql 'title-on-english'
        I18n.locale = :nl
        expect(page.slug).to eql page._id.to_s

        # Turn on i18n fallback
        require 'i18n/backend/fallbacks'
        I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
        ::I18n.fallbacks[:nl] = [:nl, :en]
        expect(page.slug).to eql 'title-on-english'
        fallback_slug = page.slug

        fallback_page = begin
                          PageSlugLocalized.find(fallback_slug)
                        rescue
                          nil
                        end
        expect(fallback_page).to eq(page)

        # Restore fallback for next tests
        ::I18n.fallbacks[:nl] = [:nl]
      end

      it 'returns a default slug if not localized' do
        page = PageLocalize.new
        page.title = 'Title on English'
        page.save
        expect(page.slug).to eql 'title-on-english'
        I18n.locale = :nl
        page.title = 'Title on Netherlands'
        expect(page.slug).to eql 'title-on-english'
        page.save
        expect(page.slug).to eql 'title-on-netherlands'
      end

      it 'slugs properly when translations are set directly' do
        page = PageSlugLocalized.new
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        expect(page['_slugs']).to eq('en' => ['title-on-english'], 'nl' => ['title-on-netherlands'])
      end

      it 'exact same title multiple langauges' do
        page = PageSlugLocalized.new
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on English' }
        page.save
        expect(page['_slugs']).to eq('en' => ['title-on-english'], 'nl' => ['title-on-english'])

        page = PageSlugLocalized.create(title_translations: { 'en' => 'Title on English2', 'nl' => 'Title on English2' })
        expect(page['_slugs']).to eq('en' => ['title-on-english2'], 'nl' => ['title-on-english2'])
      end

      it 'does not produce duplicate slugs' do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalized.new
        page.title = 'Title on English'
        page.save
        I18n.locale = 'nl'
        page.title = 'Title on Netherlands'
        page.save
        expect(page.title_translations).to eq('en' => 'Title on English', 'nl' => 'Title on Netherlands')

        I18n.locale = old_locale
        page.title = 'Title on English'
        expect(page.title_translations).to eq('en' => 'Title on English', 'nl' => 'Title on Netherlands')
        expect(page['_slugs']).to eq('en' => ['title-on-english'], 'nl' => ['title-on-netherlands'])
      end

      it 'does not produce duplicate slugs when one has changed' do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalized.new
        page.title = 'Title on English'
        page.save
        I18n.locale = 'nl'
        page.title = 'Title on Netherlands'
        page.save
        expect(page.title_translations).to eq('en' => 'Title on English', 'nl' => 'Title on Netherlands')

        I18n.locale = old_locale
        page.title = 'Modified Title on English'
        page.save
        expect(page.title_translations).to eq('en' => 'Modified Title on English',
                                              'nl' => 'Title on Netherlands')
        expect(page['_slugs']).to eq('en' => ['modified-title-on-english'],
                                     'nl' => ['title-on-netherlands'])
      end

      it 'does not produce duplicate slugs when transactions are set directly' do
        page = PageSlugLocalized.new
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        expect(page['_slugs']).to eq('en' => ['title-on-english'], 'nl' => ['title-on-netherlands'])
      end

      it 'does not produce duplicate slugs when transactions are set directly and one has changed' do
        page = PageSlugLocalized.new
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        page.title_translations = { 'en' => 'Modified Title on English',
                                    'nl' => 'Title on Netherlands' }
        page.save
        expect(page['_slugs']).to eq('en' => ['modified-title-on-english'],
                                     'nl' => ['title-on-netherlands'])
      end

      it 'works with a custom slug strategy' do
        page = PageSlugLocalizedCustom.new
        page.title = 'a title for the slug'
        page.save
        expect(page['_slugs']).to eq('en' => ['a-title-for-the-slug'], 'nl' => ['a-title-for-the-slug'])
      end
    end

    context 'slug can be localized when using history' do
      before(:each) do
        @old_locale = I18n.locale
      end

      after(:each) do
        I18n.locale = @old_locale
      end

      it 'generate a new slug for each localization and keep history' do
        old_locale = I18n.locale

        page = PageSlugLocalizedHistory.new
        page.title = 'Title on English'
        page.save
        expect(page.slug).to eql 'title-on-english'
        I18n.locale = :nl
        page.title = 'Title on Netherlands'
        page.save
        expect(page.slug).to eql 'title-on-netherlands'
        I18n.locale = old_locale
        page.title = 'Modified title on English'
        page.save
        expect(page.slug).to eql 'modified-title-on-english'
        expect(page.slug).to include('title-on-english')
        I18n.locale = :nl
        page.title = 'Modified title on Netherlands'
        page.save
        expect(page.slug).to eql 'modified-title-on-netherlands'
        expect(page.slug).to include('title-on-netherlands')
      end

      it 'returns _id if no slug' do
        page = PageSlugLocalizedHistory.new
        page.title = 'Title on English'
        page.save
        expect(page.slug).to eql 'title-on-english'
        I18n.locale = :nl
        expect(page.slug).to eql page._id.to_s
      end

      it 'fallbacks if slug not localized yet' do
        page = PageSlugLocalizedHistory.new
        page.title = 'Title on English'
        page.save
        expect(page.slug).to eql 'title-on-english'
        I18n.locale = :nl
        expect(page.slug).to eql page._id.to_s

        # Turn on i18n fallback
        require 'i18n/backend/fallbacks'
        I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
        ::I18n.fallbacks[:nl] = [:nl, :en]
        expect(page.slug).to eql 'title-on-english'
        fallback_slug = page.slug

        fallback_page = begin
                          PageSlugLocalizedHistory.find(fallback_slug)
                        rescue
                          nil
                        end
        expect(fallback_page).to eq(page)
      end

      it 'slugs properly when translations are set directly' do
        page = PageSlugLocalizedHistory.new
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        page.title_translations = { 'en' => 'Modified Title on English',
                                    'nl' => 'Modified Title on Netherlands' }
        page.save
        expect(page['_slugs']).to eq('en' => ['title-on-english', 'modified-title-on-english'],
                                     'nl' => ['title-on-netherlands', 'modified-title-on-netherlands'])
      end

      it 'does not produce duplicate slugs' do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalizedHistory.new
        page.title = 'Title on English'
        page.save
        I18n.locale = 'nl'
        page.title = 'Title on Netherlands'
        page.save
        expect(page.title_translations).to eq('en' => 'Title on English', 'nl' => 'Title on Netherlands')

        I18n.locale = old_locale
        page.title = 'Title on English'
        expect(page.title_translations).to eq('en' => 'Title on English', 'nl' => 'Title on Netherlands')
        expect(page['_slugs']).to eq('en' => ['title-on-english'], 'nl' => ['title-on-netherlands'])
      end

      it 'does not produce duplicate slugs when one has changed' do
        old_locale = I18n.locale

        # Using a default locale of en.
        page = PageSlugLocalizedHistory.new
        page.title = 'Title on English'
        page.save
        I18n.locale = 'nl'
        page.title = 'Title on Netherlands'
        page.save
        expect(page.title_translations).to eq('en' => 'Title on English', 'nl' => 'Title on Netherlands')

        I18n.locale = old_locale
        page.title = 'Modified Title on English'
        page.save
        expect(page.title_translations).to eq('en' => 'Modified Title on English',
                                              'nl' => 'Title on Netherlands')
        expect(page['_slugs']).to eq('en' => ['title-on-english', 'modified-title-on-english'],
                                     'nl' => ['title-on-netherlands'])
      end

      it 'does not produce duplicate slugs when transactions are set directly' do
        page = PageSlugLocalizedHistory.new
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        expect(page['_slugs']).to eq('en' => ['title-on-english'], 'nl' => ['title-on-netherlands'])
      end

      it 'does not produce duplicate slugs when transactions are set directly and one has changed' do
        page = PageSlugLocalizedHistory.new
        page.title_translations = { 'en' => 'Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        page.title_translations = { 'en' => 'Modified Title on English', 'nl' => 'Title on Netherlands' }
        page.save
        expect(page['_slugs']).to eq('en' => ['title-on-english', 'modified-title-on-english'],
                                     'nl' => ['title-on-netherlands'])
      end
    end
  end
end
