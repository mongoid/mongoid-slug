require "spec_helper"

describe Mongoid::Slug do

  context "root document" do
    before(:each) do
      @book = Book.create(:title => "A Thousand Plateaus", :authors => "Gilles Deleuze, Félix Guattari")
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
      similar_book.reload.to_param.should_not eql @book.to_param
    end

    it "appends a counter when slug is not unique" do
      similar_book = Book.create(:title => @book.title)
      similar_book.reload.slug.should match /\d$/
    end

    it "does not append a counter when slug is unique" do
      @book.reload.slug.should_not match /\d$/
    end

    it "does not update slug if slugged field has not changed" do
      existing_slug = @book.slug
      @book.update_attributes('authors' => "Gilles Deleuze")
      @book.reload.slug.should eql existing_slug
    end

    it "finds by slug" do
      Book.find_by_slug(@book.slug).should eql @book
    end
  end

  context "embedded has-many" do
    before(:each) do
      @person = Person.new(:name => "John Doe")
      @car = Car.new(:model => "Topolino")
      @person.cars << @car
      @person.save
    end

    it "generates slug" do
      pending "Callback not working?"
      @car.reload.to_param.should eql(@car.model.parameterize)
    end
  end

  context "embedded has-one" do
    before(:each) do
      @person = Person.new(:name => "John Doe")
      @pet = Pet.new(:name => "Pico Bello")
      @person.pet = @pet
      @person.save
    end

    it "generates slug" do
      pending "Callback not working?"
      @pet.reload.to_param.should eql(@pet.name.parameterize)
    end
  end

  context "multiple slugged fields" do
    before(:each) do
      @name = Name.create(:first_name => "John", :last_name => "Doe")
    end

    it "generates slug" do
      @name.reload.to_param.should eql([@name.first_name, @name.last_name].join(" ").parameterize)
    end
  end
end
