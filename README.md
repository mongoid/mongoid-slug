*IMPORTANT:*  If you are upgrading to Mongoid Slug 1.0.0 please migrate in accordance with the instructions in https://github.com/digitalplaywright/mongoid-slug/wiki/How-to-upgrade-to-1.0.0-or-newer.
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

* Mongoid Slug will perform a find based on `slugs` only if all arguments passed to `find` are of the type `String`
* If your document uses `BSON::ObjectId` identifiers, and all arguments look like valid `BSON::ObjectId`, then Mongoid Slug will perform a find based on `_id`.
* If your document uses any other type of identifiers, and all arguments passed to `find` are of the same type, then Mongoid Slug will perform a find based on `_id`.
* If your document uses `String` identifiers and you want to be able find by slugs or ids, to get the correct behaviour, you should add a slug_id_strategy option to your _id field definition.  This option should return something that responds to `call` (a callable) and takes one string argument, e.g. a lambda.  This callable must return true if the string looks like one of your ids.


```ruby
Book.fields['_id'].type
=> String
book = Book.find 'a-thousand-plateaus' # Finds by slugs
=> ...

class Post
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: String, slug_id_strategy: lambda {|id| id.start_with?('....')}

  field :name
  slug  :name, :history => true
end

Post.fields['_id'].type
=> String
post = Post.find 'a-thousand-plateaus' # Finds by slugs
=> ...
post = Post.find '50b1386a0482939864000001' # Finds by bson ids
=> ...
```
[Read here] [4] for all available options.

Custom Slug Generation
-------

By default Mongoid Slug generates slugs with stringex. If this is not desired you can
define your own slug generator like this:

```ruby
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
You can call stringex `to_url` method.

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

When reserved words are not specified, the words 'new' and 'edit' are considered reserved by default.
Specifying an array of custom reserved words will overwrite these defaults.

Custom Find Strategies
--------------

By default find will search for the document by the id field if the provided id
looks like a BSON ObjectId, and it will otherwise find by the _slugs field. However,
custom strategies can ovveride the default behavior, like e.g:

```ruby
module Mongoid::Slug::UuidIdStrategy
  def self.call id
    id =~ /\A([0-9a-fA-F]){8}-(([0-9a-fA-F]){4}-){3}([0-9a-fA-F]){12}\z/
  end
end
```

Use a custom strategy by adding the slug_id_strategy annotation to the _id field:

```ruby
class Entity
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: String, slug_id_strategy: UuidIdStrategy

  field :user_edited_variation
  slug  :user_edited_variation, :history => true
end
```


Adhoc checking whether a string is unique on a per Model basis
--------------------------------------------------------------

Lets say you want to have a auto-suggest function on your GUI that could provide a preview of what the url or slug could be before the form to create the record was submitted.

You can use the UniqueSlug class in your server side code to do this, e.g.

```ruby
title = params[:title]
unique = Mongoid::Slug::UniqueSlug.new(Book.new).find_unique(title)
...
# return some representation of unique
```

[1]: https://github.com/rsl/stringex/
[2]: https://secure.travis-ci.org/hakanensari/mongoid-slug.png
[3]: http://travis-ci.org/hakanensari/mongoid-slug
[4]: https://github.com/digitalplaywright/mongoid-slug/blob/master/lib/mongoid/slug.rb
