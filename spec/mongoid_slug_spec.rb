require "spec_helper"

describe Mongoid::Slug do

  before(:each) do
    @book = Book.create(:title => "A Thousand Plateaus", :isbn => "9789245242475")
  end

  context "root document" do

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

    it "does not update slug if slugged fields have not changed" do
      former_slug = @book.slug
      @book.update_attributes(:isbn => "9785545858118")
      @book.slug.should eql former_slug
    end

    it "does not update slug if slugged fields have changed but generated slug is the same" do
      former_slug = @book.slug
      @book.update_attributes(:title => "A thousand plateaus")
      @book.slug.should eql former_slug
    end

    it "finds by slug" do
      Book.where(:slug => @book.slug).first.should eql @book
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
      former_slug = @subject.slug
      @subject.update_attributes(:description => "Lorem ipsum dolor sit amet")
      @subject.slug.should eql former_slug
    end

    it "finds by slug" do
      @book.subjects.where(:slug => @subject.slug).first.should eql @subject
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
      former_slug = @publisher.slug
      @publisher.update_attributes(:year => 2001)
      @publisher.slug.should eql former_slug
    end

  end

  context "composite fields" do
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

    it "finds by slug" do
      Author.where(:slug => "gilles-deleuze").first.should eql @author
    end
  end
end
