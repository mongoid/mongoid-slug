Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on one or more
fields in a Mongoid model.

It sits idly on top of [stringex](https://github.com/rsl/stringex) and
works with non-Latin characters.

Quick Start
-----------

Add mongoid_slug to your Gemfile:

    gem 'mongoid_slug', :require => 'mongoid/slug'

Set up slugs in models like this:

    class Book
      include Mongoid::Document
      include Mongoid::Slug

      field :title
      embeds_many :authors

      slug :title
    end

    class Author
      include Mongoid::Document
      include Mongoid::Slug

      field :first
      field :last
      embedded_in :book, :inverse_of => :authors

      slug :first, :last, :as => :name
    end

Finder
------

In your controller, throw in some minimal magic:

    # GET /books/a-thousand-plateaus/authors/gilles-deleuze
    author = Book.find_by_slug(params[:book_id]).
                  authors.
                  find_by_name(params[:id])

Permanence
----------

By default, slugs are not permanent:

    >> book = Book.create(:title => "A Thousand Plateaus")
    >> book.to_param
    "a-thousand-plateaus"
    >> book.title = "Anti Oedipus"
    >> book.save
    >> book.to_param
    "anti-oedipus"

If you require permanent slugs, pass the `:permanent` option when
defining the slug.

Scope
-----

To scope an object by a reference association, pass `:scope`:

    class Company
      include Mongoid::Document
      references_many :employees
    end

    class Employee
      include Mongoid::Document
      include Mongoid::Slug
      field :name
      slug  :name, :scope => :company
      referenced_in :company
    end

In this example, if you create an employee without associating it with
any company, the scope will fall back to the root employees collection.

Currently, if you have an irregular association name, you **must**
specify the `:inverse_of` option on the other side of the assocation.

Embedded objects are automatically scoped by their parent.

Indexes
-------

You may optionally pass an `:index` option to define an index on top-level
slugs.

    class Book
      field :title
      slug  :title, :index => true
    end

Indexes on unscoped slugs will be unique.

This option has no effect if the object is embedded.
