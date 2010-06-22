require "spec_helper"

describe Mongoid::Slug do
  before(:each) do
    @book = ::Book.create(:title => "A Thousand Plateaus", :authors => "Gilles Deleuze, Félix Guattari")
  end

  it "generates slug" do
    @book.to_param.should eql @book.title.parameterize
  end

  it "updates slug" do
    @book.update_attributes(:title => "Anti Oedipus")
    @book.reload.to_param.should eql "Anti Oedipus".parameterize
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
    @book.update_attributes('authors' => "Gilles Deleuze")
    @book.slug.should eql existing_slug
  end

  it "finds by slug" do
    Book.find_by_slug(@book.slug).should eql @book
  end
end
