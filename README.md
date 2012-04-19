Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on one or more fields in a
Mongoid model. It sits idly on top of [stringex] [1], supporting non-Latin
characters.

[![travis] [2]] [3]

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

Find a record by its slug:

```ruby
# GET /books/a-thousand-plateaus
book = Book.find_by_slug params[:book_id]
```

[Read here] [4] for all available options.

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

Page.find_by_slug("welcome") == Page.find_by_slug("home") #=> true
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
Friend.find_by_slug('admin') # => nil
friend.slug # => 'admin-1'
```

[1]: https://github.com/rsl/stringex/
[2]: https://secure.travis-ci.org/hakanensari/mongoid-slug.png
[3]: http://travis-ci.org/hakanensari/mongoid-slug
[4]: https://github.com/hakanensari/mongoid-slug/blob/master/lib/mongoid/slug.rb
