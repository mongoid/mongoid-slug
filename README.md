Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on one or more
fields in a Mongoid model. It sits idly on top of [stringex] [1] and
works with non-Latin characters.

[![travis](https://secure.travis-ci.org/hakanensari/mongoid-slug.png)](http://travis-ci.org/hakanensari/mongoid-slug)

Quick Start
-----------

Add mongoid_slug to your Gemfile:

```ruby
gem 'mongoid_slug'
```

Set up some slugs:

```ruby
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
```

In your controller, use available finders:

```ruby
# GET /books/a-thousand-plateaus/authors/gilles-deleuze
author = Book.find_by_slug(params[:book_id]).
              authors.
              find_by_name(params[:id])
```

[Read here] [2]
for all available options.

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

In this example, if you create an employee without associating it with
any company, the scope will fall back to the root employees collection.

Currently, if you have an irregular association name, you **must**
specify the `:inverse_of` option on the other side of the assocation.

Embedded objects are automatically scoped by their parent.

If the value of `:scope` is not an association, it should be the name of a field within the model itself:

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

To specify a document's history should be kept track of, pass `:history` with a value of `true`.

```ruby
class Page
  include Mongoid::Document
  include Mongoid::Slug
  
  field :title
  
  slug :title, :history => true
end
```

The document will then be returned for any of the saved slugs:

```ruby
page = Page.new(:title => "Home")
page.save
page.title = "Welcome"
page.save

Page.find_by_slug("welcome") == page  #=> true
Page.find_by_slug("home") == page     #=> true
```

[1]: https://github.com/rsl/stringex/
[2]: https://github.com/hakanensari/mongoid-slug/blob/master/lib/mongoid/slug.rb

Reserved Slugs
--------------

To reserve slugs so that they will not be used as slugs, pass an array of reserved slugs into `:reserve`:

```ruby
class Friend
  include Mongoid::Document
  field :name
  slug  :name, :reserve => ['foo', 'bar']
end
```

Reserved slugs will instead start with suffix "-1". For the example above,

```ruby
friend = Friend.create(:name => "foo") # first foo friend
friend.slug # returns "foo-1" instead of "foo" since "foo" is reserved
```
