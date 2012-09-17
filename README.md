*IMPORTANT:*  If you are upgrading to Mongoid Slug 1.0.0 please migrate in accordance with the instructions in https://github.com/digitalplaywright/mongoid-slug/wiki/How-to-upgrade-to-0.20.0.
Mongoid Slug 1.0.0  stores the slugs in a single field _slugs of array type, and all previous slugs must be migrated.

Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on one or more fields in a
Mongoid model. It sits idly on top of [stringex] [1], supporting non-Latin
characters.

[![Build Status](https://secure.travis-ci.org/digitalplaywright/mongoid-slug.png)](http://travis-ci.org/digitalplaywright/mongoid-slug)

Installation
------------

Add to your Gemfile:

```ruby
gem 'mongoid_slug'
```

Usage
-----

Set up a slug:

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Slug

  field :title
  slug :title
end
```

Find a document by its slug:

```ruby
# GET /books/a-thousand-plateaus
book = Book.find params[:book_id]
```

Mongoid Slug will attempt to determine whether you want to find using the `slugs` field or the `_id` field by inspecting the supplied parameters.

* If your document uses `BSON::ObjectId` identifiers, and all arguments passed to `find` are `String` and look like valid `BSON::ObjectId`, then Mongoid Slug will perform a find based on `_id`.
* If your document uses any other type of identifiers, and all arguments passed to `find` are of the same type, then Mongoid Slug will perform a find based on `_id`.
* Otherwise, if all arguments passed to `find` are of the type `String`, then Mongoid Slug will perform a find based on `slugs`.

To override this behaviour you may supply a hash of options as the final argument to `find` with the key `force_slugs` set to `true` or `false` as required. For example:

```ruby
Book.fields['_id'].type
=> String
book = Book.find 'a-thousand-plateaus' # Finds by _id
=> ...
book = Book.find 'a-thousand-plateaus', { force_slugs: true } # Finds by slugs
=> ...
```


[Read here] [4] for all available options.

Custom Slug Generation
-------

By default Mongoid Slug generates slugs with stringex. If this is not desired you can
define your own slug generator like this:

```
class Caption
  include Mongoid::Document
  include Mongoid::Slug

  #create a block that takes the current object as an argument
  #and returns the slug.
  slug do |cur_object|
    cur_object.slug_builder.to_url
  end
end

```

Scoping
-------

To scope a slug by a reference association, pass `:scope`:

```ruby
class Company
  include Mongoid::Document
  
  references_many :employees
end

class Employee
  include Mongoid::Document
  include Mongoid::Slug
  
  field :name
  referenced_in :company
  
  slug  :name, :scope => :company
end
```

In this example, if you create an employee without associating it with any
company, the scope will fall back to the root employees collection.

Currently, if you have an irregular association name, you **must** specify the
`:inverse_of` option on the other side of the assocation.

Embedded objects are automatically scoped by their parent.

The value of `:scope` can alternatively be a field within the model itself:

```ruby
class Employee
  include Mongoid::Document
  include Mongoid::Slug
  
  field :name
  field :company_id
  
  slug  :name, :scope => :company_id
end
```

History
-------

To specify that the history of a document should be kept track of, pass
`:history` with a value of `true`.

```ruby
class Page
  include Mongoid::Document
  include Mongoid::Slug
  
  field :title
  
  slug :title, history: true
end
```

The document will then be returned for any of the saved slugs:

```ruby
page = Page.new title: "Home"
page.save
page.update_attributes title: "Welcome"

Page.find("welcome") == Page.find("home") #=> true
```

Reserved Slugs
--------------

Pass words you do not want to be slugged using the `reserve` option:

```ruby
class Friend
  include Mongoid::Document

  field :name
  slug :name, reserve: ['admin', 'root']
end

friend = Friend.create name: 'admin'
Friend.find('admin') # => nil
friend.slug # => 'admin-1'
```

[1]: https://github.com/rsl/stringex/
[2]: https://secure.travis-ci.org/hakanensari/mongoid-slug.png
[3]: http://travis-ci.org/hakanensari/mongoid-slug
[4]: https://github.com/hakanensari/mongoid-slug/blob/master/lib/mongoid/slug.rb
