# CHANGELOG

* Gemfile changes ( johnnyshields - #173 )
* Made thread safe ( jaxesn - #168 )
* Improve support for Mongoid::Paranoia (johnnyshields - #165)

## 3.2.2

## Bugfixes

* Avoid scope error in tests (johnnyshields - #163)
* require activesupport dependencies to fix error in test on ruby 1.9.3 and Mongoid 4 (digitalplaywright)

## 3.2.1

### Improvements
* Bump Mongoid 4 requirement to beta1 

### Bugfixes

* fix for Mongoid4 (blackxored)
* fix translation tests (digitalplaywright) 
* Add sparse option to slug index (klacointe)

## 3.2.0

### Improvements

* update stringex dependency to 2.0 or higher
* Mongoid 4 support (dblock)

### Bugfixes

* Fix for when using localized slug with custom slug building strategy on virtual attrbitues (asjohn)

## 3.1.2

### Bugfixes

* fixes for i8n slug generation (astjohn)
* don't use unique indexes with polymorphics (pdf)

### Improvements

* refactoring of test cases (lucasrenan)

## 3.1.1

### Bugfixes

* do not generate empty slug. Resolves: #121, #122 (digitalplaywright)

## 3.1.0

### New Features 

* optionally slugs are created and found per model type (joe1chen)

### Bugfixes

* fix issue with default scope and slug uniqueness (loopj)

## 3.0.0

### Bugfixes

* Avoid using reserved words as slugs (deepakkumarnd)
* Fix localized slug creation when using history and when the locale changes after document is created (byscripts)
* Improved specs for reserved words (astjohn)
* Mongoid Paranoia specs aded (simi)
* Fix Mongoid Slug for Ruby 2.0.0 (digitalplaywright)

### New Features

* Make slugs localizable by option (xslim)

## 2.0.1

###Bugfixes

* fix wrong homepage link in gemspec (digitalplaywright)

## 2.0.0

### New Features

* Separate out unique finding logic into own class (guyboertje)
* Enable custom specification of looks_like_slug? method (guyboertje)

### Major Changes (Backwards Incompatible)

* calling `to_param` on a document without a slug no longer builds a slug and
  persists the document (gerad)
* remove transfer from history (guyboertje)

## 1.0.1

###Bugfixes

* do not create indexes for embedded documents (digitalplaywright)

## 1.0.0

### Features
* only look for a new unique slug if the existing slugs contains the current slug (digitalplaywright)
  - e.g if the slug 'foo-2' is taken, but 'foo' is available, the user can use 'foo'.

### Minor Changes

* #76 Cleanup of callback handling (empact)

### Major Changes (Backwards Incompatible)

* Custom slug block now passes in the object (digitalplaywright)
* Fixed broken #find al (Alan Larkin)
* Only Mongoid 3.0 syntax is supported (digitalplaywright)
* Store all slugs in a single field of array type (digitalplaywright)
* Removed the ':as' feature (digitalplaywright)
* Renamed slug field to _slugs (digitalplaywright)
* Slugs are indexes by default and removed the :index option (digitalplaywright)
* Reserved words should default to :new and :edit (digitalplaywright)
* Removed find_by_slug (digitalplaywright)
* Add `#find_by_slug!` al (Alan Larkin)

### Bugfixes

* Correct index creation on scoped slugs ( Douwe Maan )

## 0.10.0
* Bugfix: Slug history should only apply if history is set to true. (tomaswitek)
* Bugfix: Model.slug should alias to to_param (tomaswitek) `
* Add .find_unique_slug_for and #find_unique_slug_for methods DouweM (Douwe Maan)
* Ensure uniqueness of slug set manually DouweM (Douwe Maan)
* Add support for reserved slugs siong1987 (Teng Siong Ong) DouweM (Douwe Maan)
* Add support for keeping a history of slugs DouweM (Douwe Maan)
* Add by_slug(slug) scope DouweM (Douwe Maan)
* Allow set slug on aliased field eagleas (Alexander Oryol)

## 0.9.0
* Allow overriding of slug at model creation time. (Brian McManus)

## 0.8.3

* Bump version of Stringex dependency.

## 0.8.2

* Generate a slug when an existing document does not have one. Should
  come in handy when adding slug module to models with existing data.

## 0.8.1

* No longer necessary to require library in Gemfile (Konstantin Shabanov)

## 0.8.0

* Fix bug concerning slugs with double-digit counters. (Jean Bredeche)
* Remove #slug!. The method is of limited value.

## 0.7.2

* Add `#find_by_slug!`. (Alex Sharp)

## 0.7.1

* Library no longers hit database multiple times to find unique slug when
  duplicates exist. (tiendung - Alex N.) 

## 0.7.0

* Slug now can be given an optional block to build a custom slug out of
  the specified fields.

## 0.6.4

* Add :any option to use first present field when multiple fields are
  slugged (Nader Akhnoukh)

## 0.6.3

* Mongoid no longer requires that emmbedded_in pass :inverse_of option
  sporkd (Peter Gumeson)

## 0.6.2

* Add #slug! to generate slug for an existing document.

## 0.6.1

* Add support for STI models. dmathieu (Damien Mathieu)

## 0.6.0

* Fix internals to work with Mongoid RC.
* Finder is now dynamic.

## 0.5.1

* Add support for scoping by reference association. ches (Ches Martin)
* Bring indexing back in as an option.

## 0.5.0

* Add support for non-Latin languages. etehtsea (Konstantin Shabanov)
* Remove :scoped. Embedded objects are now scoped by parent by
  default.
* Add finder method.

## Earlier tags

* To be found in the dustbin of git log.
