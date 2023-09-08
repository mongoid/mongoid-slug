Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on one or more fields in a Mongoid model.
It sits idly on top of [stringex](https://github.com/rsl/stringex), supporting non-Latin characters.

[![Build Status](https://github.com/mongoid/mongoid-slug/actions/workflows/test.yml/badge.svg?query=branch%3Amaster)](https://github.com/mongoid/mongoid-slug/actions/workflows/test.ym?query=branch%3Amaster)
[![Gem Version](https://badge.fury.io/rb/mongoid-slug.svg)](http://badge.fury.io/rb/mongoid-slug)
[![Code Climate](https://codeclimate.com/github/mongoid/mongoid-slug.svg)](https://codeclimate.com/github/mongoid/mongoid-slug)

### Version Support

Mongoid Slug 7.x requires at least Mongoid 7.0.0 and Ruby 2.5.0. For earlier Mongoid and Ruby version support, please use an earlier version of Mongoid Slug.

Mongoid Slug is compatible with all MongoDB versions which Mongoid supports, however, please see "Slug Max Length" section below for MongoDB 4.0 and earlier.

### Installation

Add to your Gemfile:

```ruby
gem 'mongoid-slug'
```

### Usage

### Set Up a Slug

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Slug

  field :title
  slug :title
end
```

### Find a Document by its Slug

```ruby
# GET /books/a-thousand-plateaus
book = Book.find params[:book_id]
```

Mongoid Slug will attempt to determine whether you want to find using the `slugs` field or the `_id` field by inspecting the supplied parameters.

* Mongoid Slug will perform a find based on `slugs` only if all arguments passed to `find` are of the type `String`.
* If your document uses `BSON::ObjectId` identifiers, and all arguments look like valid `BSON::ObjectId`, then Mongoid Slug will perform a find based on `_id`.
* If your document uses any other type of identifiers, and all arguments passed to `find` are of the same type, then Mongoid Slug will perform a find based on `_id`.
* If your document uses `String` identifiers and you want to be able find by slugs or ids, to get the correct behaviour, you should add a `slug_id_strategy` option to your `_id` field definition. This option should return something that responds to `call` (a callable) and takes one string argument, e.g. a lambda.  This callable must return true if the string looks like one of your ids.

```ruby
Book.fields['_id'].type
=> String

book = Book.find 'a-thousand-plateaus' # Finds by slugs
=> ...

class Post
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: String, slug_id_strategy: lambda { |id| id.start_with?('...') }

  field :name
  slug  :name, history: true
end

Post.fields['_id'].type
=> String

post = Post.find 'a-thousand-plateaus' # Finds by slugs
=> ...

post = Post.find '50b1386a0482939864000001' # Finds by bson ids
=> ...
```
[Examine slug.rb](lib/mongoid/slug.rb) for all available options.

### Updating Existing Records

To set slugs for existing records run following rake task:

```ruby
rake mongoid_slug:set
```

You can pass model names as an option for which you want to set slugs:

```ruby
rake mongoid_slug:set[Model1,Model2]
```

### Nil Slugs

Empty slugs are possible and generate a `nil` value for the `_slugs` field. In the `Post` example above, a blank post `name` will cause the document record not to contain a `_slugs` field in the database. The default `_slugs` index is `sparse`, allowing that. If you wish to change this behavior add a custom `validates_presence_of :_slugs` validator to the document or change the database index to `sparse: false`.

### Custom Slug Generation

By default Mongoid Slug generates slugs with stringex. If this is not desired you can define your own slug generator.

There are two ways to define slug generator.

#### Globally

Configure a block in `config/initializers/mongoid_slug.rb` as follows:

```ruby
Mongoid::Slug.configure do |c|
  # create a block that takes the current object as an argument and return the slug
  c.slug = proc { |cur_obj|
    cur_object.slug_builder.to_url
  }
end
```

#### On Model

```ruby
class Caption
  include Mongoid::Document
  include Mongoid::Slug

  # create a block that takes the current object as an argument and returns the slug
  slug do |cur_object|
    cur_object.slug_builder.to_url
  end
end
```

The `to_url` method comes from [stringex](https://github.com/rsl/stringex).

You can define a slug builder globally and/or override it per model.

### Scoping

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

  slug :name, scope: :company
end
```

In this example, if you create an employee without associating it with any company, the scope will fall back to the root employees collection.

Currently, if you have an irregular association name, you **must** specify the `:inverse_of` option on the other side of the assocation.

Embedded objects are automatically scoped by their parent.

Note that the unique index on the `Employee` collection in this example is derived from the `scope` value and is `{ _slugs: 1, company_id: 1}`. Therefore `:company` must be `referenced_in` above the definition of `slug` or it will not be able to resolve the association and mistakenly create a `{ _slugs: 1, company: 1}` index. An alternative is to scope to the field itself as follows:

```ruby
class Employee
  include Mongoid::Document
  include Mongoid::Slug

  field :name
  field :company_id

  slug :name, scope: :company_id
end
```

### Slug Max Length

MongoDB [featureCompatibilityVersion](https://docs.mongodb.com/manual/reference/command/setFeatureCompatibilityVersion/#std-label-view-fcv)
"4.0" and earlier applies an [Index Key Limit](https://docs.mongodb.com/manual/reference/limits/#mongodb-limit-Index-Key-Limit)
which limits the total size of an index entry to around 1KB and will raise error,
`17280 - key too large to index` when trying to create a record that causes an index key to exceed that limit.
By default slugs are of the form `text[-number]` and the text portion is limited in size
to `Mongoid::Slug::MONGO_INDEX_KEY_LIMIT_BYTES - 32` bytes.
You can change this limit with `max_length` or set it to `nil` if you're running MongoDB
with [failIndexKeyTooLong](https://docs.mongodb.org/manual/reference/parameters/#param.failIndexKeyTooLong) set to `false`.

```ruby
class Company
  include Mongoid::Document
  include Mongoid::Slug

  field :name

  slug  :name, max_length: 24
end
```

### Optionally Find and Create Slugs per Model Type

By default when using STI, the scope will be around the super-class.

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title

  slug  :title, history: true
  embeds_many :subjects
  has_many :authors
end

class ComicBook < Book
end

book = Book.create(title: 'Anti Oedipus')
comic_book = ComicBook.create(title: 'Anti Oedipus')
comic_book.slugs.should_not eql(book.slugs)
```

If you want the scope to be around the subclass, then set the option `by_model_type: true`.

```ruby
class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title

  slug  :title, history: true, by_model_type: true
  embeds_many :subjects
  has_many :authors
end

class ComicBook < Book
end

book = Book.create(title: 'Anti Oedipus')
comic_book = ComicBook.create(title: 'Anti Oedipus')
comic_book.slugs.should eql(book.slugs)
```

### History

Enable slug history tracking by setting `history: true`.

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

Page.find("welcome") == Page.find("home") # => true
```

### Reserved Slugs

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

### Localize Slugs

The slugs can be localized. This feature is built upon Mongoid localized fields,
so fallbacks and localization works as documented in the Mongoid manual.

```ruby
class PageSlugLocalize
  include Mongoid::Document
  include Mongoid::Slug

  field :title, localize: true
  slug  :title, localize: true
end
```

By specifying `localize: true`, the slug index will be created on the
[I18n.default_locale](http://guides.rubyonrails.org/i18n.html#the-public-i18n-api) field only.
For example, if `I18n.default_locale` is `:en`, the index will be generated as follows:

```ruby
slug :title, localize: true

# The following index is auto-generated:
index({ '_slugs.en' => 1 }, { unique: true, sparse: true })
```

If you are supporting multiple locales, you may specify the list of locales on which
to create indexes as an `Array`.

```ruby
slug :title, localize: [:fr, :es, :de]

# The following indexes are auto-generated:
index({ '_slugs.fr' => 1 }, { unique: true, sparse: true })
index({ '_slugs.es' => 1 }, { unique: true, sparse: true })
index({ '_slugs.de' => 1 }, { unique: true, sparse: true })
```

### Custom Find Strategies

By default find will search for the document by the id field if the provided id looks like a `BSON::ObjectId`, and it will otherwise find by the _slugs field. However, custom strategies can ovveride the default behavior, like e.g:

```ruby
module Mongoid::Slug::UuidIdStrategy
  def self.call id
    id =~ /\A([0-9a-fA-F]){8}-(([0-9a-fA-F]){4}-){3}([0-9a-fA-F]){12}\z/
  end
end
```

Use a custom strategy by adding the `slug_id_strategy` annotation to the `_id` field:

```ruby
class Entity
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: String, slug_id_strategy: UuidIdStrategy

  field :user_edited_variation
  slug  :user_edited_variation, history: true
end
```

### Adhoc Checking Whether a Slug is Unique

Lets say you want to have a auto-suggest function on your GUI that could provide a preview of what the url or slug could be before the form to create the record was submitted.

You can use the UniqueSlug class in your server side code to do this, e.g.

```ruby
title = params[:title]
unique = Mongoid::Slug::UniqueSlug.new(Book.new).find_unique(title)
...
# return some representation of unique
```

Contributing
------------

Mongoid-slug is work of [many of contributors](https://github.com/mongoid/mongoid-slug/graphs/contributors). You're encouraged to submit [pull requests](https://github.com/mongoid/mongoid-slug/pulls), [propose features, ask questions and discuss issues](https://github.com/mongoid/mongoid-slug/issues). See [CONTRIBUTING](CONTRIBUTING.md) for details.

Copyright & License
-------------------

Copyright (c) 2010-2017 Hakan Ensari & Contributors, see [LICENSE](LICENSE) for details.
