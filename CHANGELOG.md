# CHANGELOG

## Next

* Your contribution here.

## 5.1.0

* [#194](https://github.com/digitalplaywright/mongoid-slug/issues/194): Fixed compatibility with Mongoid::Observer - [@dblock](https://github.com/dblock).

## 5.0.0

* [#187](https://github.com/digitalplaywright/mongoid-slug/pull/187): Mongoid 5 support - [@dblock](https://github.com/dblock).
* [#188](https://github.com/digitalplaywright/mongoid-slug/pull/188): Removed deprecated name, _mongoid_slug_ - [@dblock](https://github.com/dblock).
* [#189](https://github.com/digitalplaywright/mongoid-slug/pull/189): Implemented RuboCop - [@dblock](https://github.com/dblock).

## 4.0.0

* [#179](https://github.com/digitalplaywright/mongoid-slug/pull/179): Renamed gem to mongoid-slug - [@nofxx](https://github.com/nofxx).
* [#168](https://github.com/digitalplaywright/mongoid-slug/pull/168): Finding a unique slug is now threadsafe - [@jaxesn](https://github.com/jaxesn).
* [#165](https://github.com/digitalplaywright/mongoid-slug/pull/165): Fixed compatibility with Mongoid::Paranoia - [@johnnyshields](https://github.com/johnnyshields).

## 3.2.2

## Bugfixes

* [#163](https://github.com/digitalplaywright/mongoid-slug/pull/163): Avoid scope error in tests - [@johnnyshields](https://github.com/johnnyshields).
* Require activesupport dependencies to fix error in test on ruby 1.9.3 and Mongoid 4 - [@digitalplaywright](https://github.com/digitalplaywright).

## 3.2.1

### Improvements

* Bumped Mongoid 4 requirement to beta1.

### Bugfixes

* Fixed Mongoid4 - [@blackxored](https://github.com/blackxored).
* Fixed translation tests - [@digitalplaywright](https://github.com/digitalplaywright).
* Added sparse option to slug index - [@klacointe](https://github.com/klacointe).

## 3.2.0

### Improvements

* Updated stringex dependency to 2.0 or higher.
* Added Mongoid 4 support - [@dblock](https://github.com/dblock).

### Bugfixes

* Fixed for when using localized slug with custom slug building strategy on virtual attrbitues - [@astjohn](https://github.com/astjohn).

## 3.1.2

### Bugfixes

* Fixes for i8n slug generation - [@astjohn](https://github.com/astjohn).
* Don't use unique indexes with polymorphics - [@pdf](https://github.com/pdf).

### Improvements

* Refactored of test cases - [@lucasrenan](https://github.com/lucasrenan).

## 3.1.1

### Bugfixes

* [#121](https://github.com/digitalplaywright/mongoid-slug/issues/121), [#122](https://github.com/digitalplaywright/mongoid-slug/issues/122): Do not generate empty slug - [@digitalplaywright](https://github.com/digitalplaywright).

## 3.1.0

### New Features

* Optionally slugs are created and found per model type - [@joe1chen](https://github.com/joe1chen).

### Bugfixes

* Fixed issue with default scope and slug uniqueness - [@loopj](https://github.com/loopj).

## 3.0.0

### Bugfixes

* Avoid using reserved words as slugs - [@deepakkumarnd](https://github.com/deepakkumarnd).
* Fixed localized slug creation when using history and when the locale changes after document is created - [@byscripts](https://github.com/byscripts).
* Improved specs for reserved words - [@astjohn](https://github.com/astjohn).
* Added Mongoid Paranoia specs - [@simi](https://github.com/simi).
* Fixed Mongoid Slug for Ruby 2.0.0 - [@digitalplaywright](https://github.com/digitalplaywright).

### New Features

* Made slugs localizable by option - [@xslim](https://github.com/xslim).

## 2.0.1

### Bugfixes

* Fix wrong homepage link in gemspec - [@digitalplaywright](https://github.com/digitalplaywright).

## 2.0.0

### New Features

* Separated out unique finding logic into own class - [@guyboertje](https://github.com/guyboertje).
* Enabled custom specification of looks_like_slug? method - [@guyboertje](https://github.com/guyboertje).

### Major Changes (Backwards Incompatible)

* Calling `to_param` on a document without a slug no longer builds a slug and persists the document - [@gerad](https://github.com/gerad).
* Removed transfer from history - [@guyboertje](https://github.com/guyboertje).

## 1.0.1

### Bugfixes

* Do not create indexes for embedded documents - [@digitalplaywright](https://github.com/digitalplaywright).

## 1.0.0

### Features

* Only look for a new unique slug if the existing slugs contains the current slug - [@digitalplaywright](https://github.com/digitalplaywright).

### Minor Changes

* #76 Cleanup of callback handling - [@empact](https://github.com/empact).

### Major Changes (Backwards Incompatible)

* Custom slug block now passes in the object - [@digitalplaywright](https://github.com/digitalplaywright).
* Fixed broken #find - [@al](https://github.com/al).
* Only Mongoid 3.0 syntax is supported - [@digitalplaywright](https://github.com/digitalplaywright).
* Store all slugs in a single field of array type - [@digitalplaywright](https://github.com/digitalplaywright).
* Removed the ':as' feature - [@digitalplaywright](https://github.com/digitalplaywright).
* Renamed slug field to _slugs - [@digitalplaywright](https://github.com/digitalplaywright).
* Slugs are indexes by default and removed the :index option - [@digitalplaywright](https://github.com/digitalplaywright).
* Reserved words should default to :new and :edit - [@digitalplaywright](https://github.com/digitalplaywright).
* Removed find_by_slug - [@digitalplaywright](https://github.com/digitalplaywright).
* Added `#find_by_slug!` - [@al](https://github.com/al).

### Bugfixes

* Corrected index creation on scoped slugs - [@DouweM](https://github.com/DouweM).

## 0.10.0
* Fixed Slug history should only apply if history is set to true - [@tomaswitek](https://github.com/tomaswitek).
* Fixed Model.slug should alias to to_param - [@tomaswitek](https://github.com/tomaswitek).
* Added .find_unique_slug_for and #find_unique_slug_for methods - [@DouweM](https://github.com/DouweM).
* Ensured uniqueness of slug set manually - [@DouweM](https://github.com/DouweM).
* Added support for reserved slugs - [@siong1987](https://github.com/siong1987), [@DouweM](https://github.com/DouweM).
* Added support for keeping a history of slugs - [@DouweM](https://github.com/DouweM).
* Added by_slug(slug) scope - [@DouweM](https://github.com/DouweM).
* Allowed set slug on aliased field - [@eagleas](https://github.com/eagleas).

## 0.9.0

* Allowed overriding of slug at model creation time - Brian McManus.

## 0.8.3

* Bumped version of Stringex dependency.

## 0.8.2

* Generated a slug when an existing document does not have one.

## 0.8.1

* No longer necessary to require library in Gemfile - Konstantin Shabanov.

## 0.8.0

* Fix edbug concerning slugs with double-digit counters - Jean Bredeche.
* Removed #slug!. The method is of limited value.

## 0.7.2

* Added `#find_by_slug!` - Alex Sharp.

## 0.7.1

* Library no longers hit database multiple times to find unique slug when duplicates exist - [@tiendung](https://github.com/tiendung).

## 0.7.0

* Slug now can be given an optional block to build a custom slug out of the specified fields.

## 0.6.4

* Added :any option to use first present field when multiple fields are slugged - Nader Akhnoukh.

## 0.6.3

* Mongoid no longer requires that emmbedded_in pass :inverse_of option sporkd - Peter Gumeson.

## 0.6.2

* Added #slug! to generate slug for an existing document.

## 0.6.1

* Added support for STI models - [@dmathieu](https://github.com/dmathieu).

## 0.6.0

* Fixed internals to work with Mongoid RC.
* Finder is now dynamic.

## 0.5.1

* Added support for scoping by reference association - [@ches](https://github.com/ches).
* Brought indexing back in as an option.

## 0.5.0

* Added support for non-Latin languages - [@etehtsea](https://github.com/etehtsea).
* Removed :scoped. Embedded objects are now scoped by parent by default.
* Added finder method.

## Earlier tags

* To be found in the dustbin of git log.
