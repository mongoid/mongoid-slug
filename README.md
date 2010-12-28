Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on one or more fields in a Mongoid model. It sits on top of [stringex](https://github.com/rsl/stringex) and works with non-Latin characters.

Quick Start
---------------

First, add mongoid_slug to your Gemfile:

    gem 'mongoid_slug', :require => 'mongoid/slug'

Say you have a book that embeds many authors. You can set up slugs for both resources like this:

    class Book
      include Mongoid::Document
      include Mongoid::Slug
      field :title
      slug  :title
      embeds_many :authors
    end

    class Author
      include Mongoid::Document
      include Mongoid::Slug
      field :first_name
      field :last_name
      slug  :first_name, :last_name
      embedded_in :book, :inverse_of => :authors
    end

In your controller, you can use the `find_by_slug` helper:

    def find_book
      Book.find_by_slug(params[:book_id])
    end

    def find_author
      @book.authors.find_by_slug(params[:id])
    end

To demo some more functionality in the console:

    >> book = Book.create(:title => "A Thousand Plateaus")
    >> book.to_param
    "a-thousand-plateaus"
    >> book.title = "Anti Oedipus"
    >> book.save
    >> book.to_param
    "anti-oedipus"
    >> author = book.authors.create(:first_name => "Gilles", :last_name => "Deleuze")
    >> author.to_param
    => "gilles-deleuze"
    >> author.update_attributes(:first_name => "Félix", :last_name => "Guattari")
    >> author.to_param
    => "felix-guattari"
