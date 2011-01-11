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

In your controller, use the `find_by_slug` helper:

    Book.find_by_slug(params[:book_id])
    book.authors.find_by_slug(params[:id])

You can customize the name of the field that stores the slug:

    class Person
      include Mongoid::Document
      include Mongoid::Slug
      field :name
      slug  :name, :as => :permalink
    end

The finder now becomes:

    Person.find_by_permalink(params[:id])

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

Scoping by Associations
-----------------------

Objects that are embedded in a parent document automatically have their slug uniqueness scoped to the parent. If you wish to scope by a reference association, you can pass a `:scope` option to the `slug` class method:

    class Company
      include Mongoid::Document
      field :name
      references_many :employees
    end

    class Employee
      include Mongoid::Document
      include Mongoid::Slug
      field :first_name
      field :last_name
      slug  :first_name, :last_name, :scope => :company
      referenced_in :company
    end

In this example, if you create an employee without associating it with any company, the slug scope will fall back to the root employees collection. Currently if you have an irregular association name, for instance:

    references_many :employees, :class_name => 'Person', :foreign_key => :company_id

you **must** specify the `:inverse_of` option on the other side of the assocation.

Indexing
--------

You may optionally pass an `:index` option to generate an index on the slug in top-level objects.

    class Book
      field :title
      slug  :title, :index => true
    end

Indexes on non-scoped slugs will be unique.
