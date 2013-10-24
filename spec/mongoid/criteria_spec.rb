#encoding: utf-8
require "spec_helper"

describe Mongoid::Slug::Criteria do
  describe ".find" do
    let!(:book) { Book.create(:title => "A Working Title").tap { |d| d.update_attribute(:title, "A Thousand Plateaus") } }
    let!(:book2) { Book.create(:title => "Difference and Repetition") }
    let!(:friend) { Friend.create(:name => "Jim Bob") }
    let!(:friend2) { Friend.create(:name => friend.id.to_s) }
    let!(:integer_id) { IntegerId.new(:name => "I have integer ids").tap { |d| d.id = 123; d.save } }
    let!(:integer_id2) { IntegerId.new(:name => integer_id.id.to_s).tap { |d| d.id = 456; d.save } }
    let!(:string_id) { StringId.new(:name => "I have string ids").tap { |d| d.id = 'abc'; d.save } }
    let!(:string_id2) { StringId.new(:name => string_id.id.to_s).tap { |d| d.id = 'def'; d.save } }
    let!(:subject) { Subject.create(:name  => "A Subject", :book => book) }
    let!(:subject2) { Subject.create(:name  => "A Subject", :book => book2) }
    let!(:without_slug) { WithoutSlug.new().tap { |d| d.id = 456; d.save } }

    context "when the model does not use mongoid slugs" do
      it "should not use mongoid slug's custom find methods" do
        Mongoid::Slug::Criteria.any_instance.should_not_receive(:find)
        WithoutSlug.find(without_slug.id.to_s).should == without_slug
      end
    end

    context "using slugs" do
      context "(single)" do
        context "and a document is found" do
          it "returns the document as an object" do
            Book.find(book.slugs.first).should == book
          end
        end

        context "but no document is found" do
          it "raises a Mongoid::Errors::DocumentNotFound error" do
            lambda {
              Book.find("Anti Oedipus")
            }.should raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "(multiple)" do
        context "and all documents are found" do
          it "returns the documents as an array without duplication" do
            Book.find(book.slugs + book2.slugs).should =~ [book, book2]
          end
        end

        context "but not all documents are found" do
          it "raises a Mongoid::Errors::DocumentNotFound error" do
            lambda {
              Book.find(book.slugs + ['something-nonexistent'])
            }.should raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when no documents match" do
        it "raises a Mongoid::Errors::DocumentNotFound error" do
          lambda {
            Book.find("Anti Oedipus")
          }.should raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end

      context "when ids are BSON::ObjectIds and the supplied argument looks like a BSON::ObjectId" do
        it "it should find based on ids not slugs" do # i.e. it should type cast the argument
          Friend.find(friend.id.to_s).should == friend
        end
      end

      context "when ids are Strings" do
        it "it should find based on ids not slugs" do # i.e. string ids should take precedence over string slugs
          StringId.find(string_id.id.to_s).should == string_id
        end
      end

      context "when ids are Integers and the supplied arguments looks like an Integer" do
        it "it should find based on slugs not ids" do # i.e. it should not type cast the argument
          IntegerId.find(integer_id.id.to_s).should == integer_id2
        end
      end

      context "models that does not use slugs, should find using the original find" do
        it "it should find based on ids" do # i.e. it should not type cast the argument
          WithoutSlug.find(without_slug.id.to_s).should == without_slug
        end
      end

      context "when scoped" do
        context "and a document is found" do
          it "returns the document as an object" do
            book.subjects.find(subject.slugs.first).should == subject
            book2.subjects.find(subject.slugs.first).should == subject2
          end
        end

        context "but no document is found" do
          it "raises a Mongoid::Errors::DocumentNotFound error" do
            lambda {
              book.subjects.find('Another Subject')
            }.should raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end
    end

    context "using ids" do
      it "raises a Mongoid::Errors::DocumentNotFound error if no document is found" do
        lambda {
          Book.find(friend.id)
        }.should raise_error(Mongoid::Errors::DocumentNotFound)
      end

      context "given a single document" do
        it "returns the document" do
          Friend.find(friend.id).should == friend
        end
      end

      context "given multiple documents" do
        it "returns the documents" do
          Book.find([book.id, book2.id]).should =~ [book, book2]
        end
      end
    end
  end

  describe ".find_by_slug!" do
    let!(:book) { Book.create(:title => "A Working Title").tap { |d| d.update_attribute(:title, "A Thousand Plateaus") } }
    let!(:book2) { Book.create(:title => "Difference and Repetition") }
    let!(:friend) { Friend.create(:name => "Jim Bob") }
    let!(:friend2) { Friend.create(:name => friend.id.to_s) }
    let!(:integer_id) { IntegerId.new(:name => "I have integer ids").tap { |d| d.id = 123; d.save } }
    let!(:integer_id2) { IntegerId.new(:name => integer_id.id.to_s).tap { |d| d.id = 456; d.save } }
    let!(:string_id) { StringId.new(:name => "I have string ids").tap { |d| d.id = 'abc'; d.save } }
    let!(:string_id2) { StringId.new(:name => string_id.id.to_s).tap { |d| d.id = 'def'; d.save } }
    let!(:subject) { Subject.create(:name  => "A Subject", :book => book) }
    let!(:subject2) { Subject.create(:name  => "A Subject", :book => book2) }

    context "(single)" do
      context "and a document is found" do
        it "returns the document as an object" do
          Book.find_by_slug!(book.slugs.first).should == book
        end
      end

      context "but no document is found" do
        it "raises a Mongoid::Errors::DocumentNotFound error" do
          lambda {
            Book.find_by_slug!("Anti Oedipus")
          }.should raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "(multiple)" do
      context "and all documents are found" do
        it "returns the documents as an array without duplication" do
          Book.find_by_slug!(book.slugs + book2.slugs).should =~ [book, book2]
        end
      end

      context "but not all documents are found" do
        it "raises a Mongoid::Errors::DocumentNotFound error" do
          lambda {
            Book.find_by_slug!(book.slugs + ['something-nonexistent'])
          }.should raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "when scoped" do
      context "and a document is found" do
        it "returns the document as an object" do
          book.subjects.find_by_slug!(subject.slugs.first).should == subject
          book2.subjects.find_by_slug!(subject.slugs.first).should == subject2
        end
      end

      context "but no document is found" do
        it "raises a Mongoid::Errors::DocumentNotFound error" do
          lambda {
            book.subjects.find_by_slug!('Another Subject')
          }.should raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end
  end
end
