require 'spec_helper'

describe Mongoid::Slug::Criteria do
  describe '.find' do
    let!(:book) { Book.create(title: 'A Working Title').tap { |d| d.update_attribute(:title, 'A Thousand Plateaus') } }
    let!(:book2) { Book.create(title: 'Difference and Repetition') }
    let!(:friend) { Friend.create(name: 'Jim Bob') }
    let!(:friend2) { Friend.create(name: friend.id.to_s) }
    let!(:integer_id) { IntegerId.new(name: 'I have integer ids').tap { |d| d.id = 123; d.save! } }
    let!(:integer_id2) { IntegerId.new(name: integer_id.id.to_s).tap { |d| d.id = 456; d.save! } }
    let!(:string_id) { StringId.new(name: 'I have string ids').tap { |d| d.id = 'abc'; d.save! } }
    let!(:string_id2) { StringId.new(name: string_id.id.to_s).tap { |d| d.id = 'def'; d.save! } }
    let!(:subject) { Subject.create(name: 'A Subject', book: book) }
    let!(:subject2) { Subject.create(name: 'A Subject', book: book2) }
    let!(:without_slug) { WithoutSlug.new.tap { |d| d.id = 456; d.save! } }

    context 'when the model does not use mongoid slugs' do
      it "should not use mongoid slug's custom find methods" do
        expect_any_instance_of(Mongoid::Slug::Criteria).not_to receive(:find)
        expect(WithoutSlug.find(without_slug.id.to_s)).to eq(without_slug)
      end
    end

    context 'using slugs' do
      context '(single)' do
        context 'and a document is found' do
          it 'returns the document as an object' do
            expect(Book.find(book.slugs.first)).to eq(book)
          end
        end

        context 'but no document is found' do
          it 'raises a Mongoid::Errors::DocumentNotFound error' do
            expect do
              Book.find('Anti Oedipus')
            end.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context '(multiple)' do
        context 'and all documents are found' do
          it 'returns the documents as an array without duplication' do
            expect(Book.find(book.slugs + book2.slugs)).to match_array([book, book2])
          end
        end

        context 'but not all documents are found' do
          it 'raises a Mongoid::Errors::DocumentNotFound error' do
            expect do
              Book.find(book.slugs + ['something-nonexistent'])
            end.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context 'when no documents match' do
        it 'raises a Mongoid::Errors::DocumentNotFound error' do
          expect do
            Book.find('Anti Oedipus')
          end.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end

      context 'when ids are BSON::ObjectIds and the supplied argument looks like a BSON::ObjectId' do
        it 'it should find based on ids not slugs' do # i.e. it should type cast the argument
          expect(Friend.find(friend.id.to_s)).to eq(friend)
        end
      end

      context 'when ids are Strings' do
        it 'it should find based on ids not slugs' do # i.e. string ids should take precedence over string slugs
          expect(StringId.find(string_id.id.to_s)).to eq(string_id)
        end
      end

      context 'when ids are Integers and the supplied arguments looks like an Integer' do
        it 'it should find based on slugs not ids' do # i.e. it should not type cast the argument
          expect(IntegerId.find(integer_id.id.to_s)).to eq(integer_id2)
        end
      end

      context 'models that does not use slugs, should find using the original find' do
        it 'it should find based on ids' do # i.e. it should not type cast the argument
          expect(WithoutSlug.find(without_slug.id.to_s)).to eq(without_slug)
        end
      end

      context 'when scoped' do
        context 'and a document is found' do
          it 'returns the document as an object' do
            expect(book.subjects.find(subject.slugs.first)).to eq(subject)
            expect(book2.subjects.find(subject.slugs.first)).to eq(subject2)
          end
        end

        context 'but no document is found' do
          it 'raises a Mongoid::Errors::DocumentNotFound error' do
            expect do
              book.subjects.find('Another Subject')
            end.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end
    end

    context 'using ids' do
      it 'raises a Mongoid::Errors::DocumentNotFound error if no document is found' do
        expect do
          Book.find(friend.id)
        end.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      context 'given a single document' do
        it 'returns the document' do
          expect(Friend.find(friend.id)).to eq(friend)
        end
      end

      context 'given multiple documents' do
        it 'returns the documents' do
          expect(Book.find([book.id, book2.id])).to match_array([book, book2])
        end
      end
    end
  end

  describe '.find_by_slug!' do
    let!(:book) { Book.create(title: 'A Working Title').tap { |d| d.update_attribute(:title, 'A Thousand Plateaus') } }
    let!(:book2) { Book.create(title: 'Difference and Repetition') }
    let!(:friend) { Friend.create(name: 'Jim Bob') }
    let!(:friend2) { Friend.create(name: friend.id.to_s) }
    let!(:integer_id) { IntegerId.new(name: 'I have integer ids').tap { |d| d.id = 123; d.save! } }
    let!(:integer_id2) { IntegerId.new(name: integer_id.id.to_s).tap { |d| d.id = 456; d.save! } }
    let!(:string_id) { StringId.new(name: 'I have string ids').tap { |d| d.id = 'abc'; d.save! } }
    let!(:string_id2) { StringId.new(name: string_id.id.to_s).tap { |d| d.id = 'def'; d.save! } }
    let!(:subject) { Subject.create(name: 'A Subject', book: book) }
    let!(:subject2) { Subject.create(name: 'A Subject', book: book2) }

    context '(single)' do
      context 'and a document is found' do
        it 'returns the document as an object' do
          expect(Book.find_by_slug!(book.slugs.first)).to eq(book)
        end
      end

      context 'but no document is found' do
        it 'raises a Mongoid::Errors::DocumentNotFound error' do
          expect do
            Book.find_by_slug!('Anti Oedipus')
          end.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context '(multiple)' do
      context 'and all documents are found' do
        it 'returns the documents as an array without duplication' do
          expect(Book.find_by_slug!(book.slugs + book2.slugs)).to match_array([book, book2])
        end
      end

      context 'but not all documents are found' do
        it 'raises a Mongoid::Errors::DocumentNotFound error' do
          expect do
            Book.find_by_slug!(book.slugs + ['something-nonexistent'])
          end.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context 'when scoped' do
      context 'and a document is found' do
        it 'returns the document as an object' do
          expect(book.subjects.find_by_slug!(subject.slugs.first)).to eq(subject)
          expect(book2.subjects.find_by_slug!(subject.slugs.first)).to eq(subject2)
        end
      end

      context 'but no document is found' do
        it 'raises a Mongoid::Errors::DocumentNotFound error' do
          expect do
            book.subjects.find_by_slug!('Another Subject')
          end.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end
  end

  describe '.where' do
    let!(:artist1) { Artist.create!(name: 'Leonardo') }
    let!(:artist2) { Artist.create!(name: 'Malevich') }
    let!(:artwork1) { Artwork.create!(title: 'Mona Lisa', artist_ids: [artist1.id], published: true) }
    let!(:artwork2) { Artwork.create!(title: 'Black Square', artist_ids: [artist2.id], published: false) }
    let!(:artwork3) { Artwork.create! }

    it 'counts artworks' do
      expect(Artwork.in(artist_ids: artist1.id).count).to eq 1
      expect(Artwork.in(artist_ids: artist2.id).count).to eq 1
    end

    it 'counts published artworks' do
      expect(Artwork.in(artist_ids: artist1.id).published.count).to eq 1
      expect(Artwork.in(artist_ids: artist2.id).published.count).to eq 0
    end
  end
end
