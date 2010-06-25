require "spec_helper"

describe Mongoid::Slug do

  before(:each) do
    @book = Book.create(:title => "A Thousand Plateaus", :isbn => "9789245242475")
  end

  context "root" do

    it "generates slug" do
      @book.to_param.should eql @book.title.parameterize
    end

    it "updates slug" do
      @book.update_attributes(:title => "Anti Oedipus")
      @book.to_param.should eql "Anti Oedipus".parameterize
    end

    it "generates a unique slug" do
      similar_book = Book.create(:title => @book.title)
      similar_book.to_param.should_not eql @book.to_param
    end

    it "appends a counter when slug is not unique" do
      similar_book = Book.create(:title => @book.title)
      similar_book.slug.should match /\d$/
    end

    it "does not append a counter when slug is unique" do
      @book.slug.should_not match /\d$/
    end

    it "does not update slug if slugged field has not changed" do
      existing_slug = @book.slug
      @book.update_attributes('isbn' => "9785545858118")
      @book.slug.should eql existing_slug
    end

    context ".find_by_slug" do
      it "finds by slug" do
        Book.find_by_slug(@book.slug).should eql @book
      end
    end

  end

  context "embedded has many" do

    before(:each) do
      @subject = @book.subjects.create(:name => "Psychoanalysis")
    end

    it "generates slug" do
      @subject.to_param.should eql(@subject.name.parameterize)
    end

    it "updates slug" do
      @subject.update_attributes(:name => "Schizoanalysis")
      @subject.to_param.should eql "Schizoanalysis".parameterize
    end

    it "generates a unique slug" do
      similar_subject = @book.subjects.create(:model => @subject.name)
      similar_subject.to_param.should_not eql @subject.to_param
    end

    it "appends a counter when slug is not unique" do
      similar_subject = @book.subjects.create(:name => @subject.name)
      similar_subject.slug.should match /\d$/
    end

    it "does not append a counter when slug is unique" do
      @subject.slug.should_not match /\d$/
    end

    it "does not update slug if slugged field has not changed" do
      existing_slug = @subject.slug
      @subject.update_attributes(:description => "Lorem ipsum dolor sit amet")
      @subject.slug.should eql existing_slug
    end

    context ".find_by_slug" do
      it "raises error" do
        lambda { @book.subjects.find_by_slug(@subject.slug) }.should raise_error
      end

      it "does find by a regular where" do
        @book.subjects.where(:slug => @subject.slug).first.should eql @subject
      end
    end

  end

  context "embedded has one" do

    before(:each) do
      @publisher = @book.create_publisher(:name => "OUP")
    end

    it "generates slug" do
      @publisher.to_param.should eql(@publisher.name.parameterize)
    end

    it "updates slug" do
      @publisher.update_attributes(:name => "Harvard UP")
      @publisher.to_param.should eql "Harvard UP".parameterize
    end

    it "does not update slug if slugged field has not changed" do
      existing_slug = @publisher.slug
      @publisher.update_attributes(:year => 2001)
      @publisher.slug.should eql existing_slug
    end

  end

  context "slugging composite fields" do
    before(:each) do
      @author = Author.create(:first_name => "Gilles", :last_name => "Deleuze")
    end

    it "generates slug" do
      @author.to_param.should eql("Gilles Deleuze".parameterize)
    end

    it "updates slug" do
      @author.update_attributes(:first_name => "Félix", :last_name => "Guattari")
      @author.to_param.should eql "Félix Guattari".parameterize
    end

    it "generates a unique slug" do
      similar_author = Author.create(:first_name => @author.first_name,
                                     :last_name => @author.last_name)
      similar_author.to_param.should_not eql @author.to_param
    end

    it "appends a counter when slug is not unique" do
      similar_author = Author.create(:first_name => @author.first_name,
                                     :last_name => @author.last_name)
      similar_author.slug.should match /\d$/
    end

    it "does not append a counter when slug is unique" do
      @author.slug.should_not match /\d$/
    end

    context ".find_by_slug" do
      it "finds by slug" do
        Author.find_by_slug("gilles-deleuze").should eql @author
      end
    end
  end
end
