Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on one or more
fields in a Mongoid model. It sits idly on top of [stringex](https://github.com/rsl/stringex) and works with non-Latin characters.

![lacan](http://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Nus_borromeu_1.jpg/360px-Nus_borromeu_1.jpg)

Quick Start
-----------

Add mongoid_slug to your Gemfile:

    gem 'mongoid_slug', :require => 'mongoid/slug'

Set up some slugs:

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

In your controller, use available finders:

    # GET /books/a-thousand-plateaus/authors/gilles-deleuze
    author = Book.find_by_slug(params[:book_id]).
                  authors.
                  find_by_name(params[:id])

[Read here](https://github.com/papercavalier/mongoid-slug/blob/master/lib/mongoid/slug.rb)
for all available options.

Scoping
-------

To scope a slug by a reference association, pass `:scope`:

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
