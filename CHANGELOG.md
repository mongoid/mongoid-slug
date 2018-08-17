## 6.0.1 (Next)

* Your contribution here.
* [#255](https://github.com/mongoid/mongoid-slug/pull/255): Use mongoid::config#models in rake task, resolves #247 - [@kailan](https://github.com/kailan).

## 6.0.0 (2018/09/17)

* [#252](https://github.com/mongoid/mongoid-slug/pull/252): Compatibility with Mongoid 7.0.0+ - [@kailan](https://github.com/kailan).

## 5.3.3 (2017/04/06)

* [#240](https://github.com/mongoid/mongoid-slug/pull/240): Fix: ensure we find the correct `BSON::Regexp::Raw` class - [@artfuldodger](https://github.com/artfuldodger).

## 5.3.2 (2017/04/03)

* [#234](https://github.com/mongoid/mongoid-slug/pull/234): Compatibility with Mongoid 6 - [@moodlemags](https://github.com/moodlemags), [@dblock](https://github.com/dblock).
* [#238](https://github.com/mongoid/mongoid-slug/pull/238): Use `BSON::Regexp::Raw` instead of Ruby's Regexp to avoid a performance hit - [@mzikherman](https://github.com/mzikherman).

## 5.3.0 (2016/09/11)

* [#228](https://github.com/mongoid/mongoid-slug/pull/228): Moved to the [mongoid](http://mongoid.github.io) organization - [@dblock](https://github.com/dblock), [@digitalplaywright](https://github.com/digitalplaywright).
* [#166](https://github.com/mongoid/mongoid-slug/issues/166): Configure slug builder globally - [@anujaware](https://github.com/anujaware).
* [#209](https://github.com/mongoid/mongoid-slug/issues/209): Prefixed internal `Mongoid::Slug` class attributes with `slug_` to avoid conflicts - [@dblock](https://github.com/dblock).
* [#217](https://github.com/mongoid/mongoid-slug/issues/217): Fixed `mongoid_slug:set` rake task for Mongoid 6 - [@dblock](https://github.com/dblock).
* [#219](https://github.com/mongoid/mongoid-slug/pull/219): Mongoid HEAD and Rails 5.0.0.rc1 support - [@Fudoshiki](https://github.com/Fudoshiki).
* [#224](https://github.com/mongoid/mongoid-slug/pull/224): Use Danger, PR linter - [@dblock](https://github.com/dblock).
* [#222](https://github.com/mongoid/mongoid-slug/pull/225): Fix: `Mongo::Error::OperationFailure: E11000 duplicate key error index` error with blank slugs, default `_slugs` to `nil` instead of `[]` - [@dblock](https://github.com/dblock).
* [#172](https://github.com/mongoid/mongoid-slug/pull/172): Improved handling of unique and sparse index constraints - [@johnnyshields](https://github.com/johnnyshields).
* [#229](https://github.com/mongoid/mongoid-slug/pull/229): Upgraded to RuboCop 0.42.0 - [@dblock](https://github.com/dblock).

## 5.2.0 (2016/01/03)

* [#204](https://github.com/mongoid/mongoid-slug/pull/204): The text portion of the slug is now truncated at `Mongoid::Slug::MONGO_INDEX_KEY_LIMIT_BYTES - 32` bytes by default and can be set via `max_length` - [@dblock](https://github.com/dblock).
* [#177](https://github.com/mongoid/mongoid-slug/issues/177): Added `mongoid_slug:set` rake task to set slug for legacy data - [@anuja-joshi](https://github.com/anuja-joshi).

## 5.1.1

* [#197](https://github.com/mongoid/mongoid-slug/pull/197): Compatibility with Mongoid 5.0.1, fix [MONGOID-4177](https://jira.mongodb.org/browse/MONGOID-4177) - [@dblock](https://github.com/dblock).

## 5.1.0

* [#194](https://github.com/mongoid/mongoid-slug/issues/194): Fixed compatibility with Mongoid::Observer - [@dblock](https://github.com/dblock).

## 5.0.0

* [#187](https://github.com/mongoid/mongoid-slug/pull/187): Mongoid 5 support - [@dblock](https://github.com/dblock).
* [#188](https://github.com/mongoid/mongoid-slug/pull/188): Removed deprecated name, _mongoid_slug_ - [@dblock](https://github.com/dblock).
* [#189](https://github.com/mongoid/mongoid-slug/pull/189): Implemented RuboCop - [@dblock](https://github.com/dblock).

## 4.0.0

* [#179](https://github.com/mongoid/mongoid-slug/pull/179): Renamed gem to mongoid-slug - [@nofxx](https://github.com/nofxx).
* [#168](https://github.com/mongoid/mongoid-slug/pull/168): Finding a unique slug is now threadsafe - [@jaxesn](https://github.com/jaxesn).
* [#165](https://github.com/mongoid/mongoid-slug/pull/165): Fixed compatibility with Mongoid::Paranoia - [@johnnyshields](https://github.com/johnnyshields).

## 3.2.2

## Bugfixes

* [#163](https://github.com/mongoid/mongoid-slug/pull/163): Avoid scope error in tests - [@johnnyshields](https://github.com/johnnyshields).
* Require activesupport dependencies to fix error in test on ruby 1.9.3 and Mongoid 4 - [@digitalplaywright](https://github.com/digitalplaywright).

## 3.2.1

### Improvements

* Bumped Mongoid 4 requirement to beta1 - [@digitalplaywright](https://github.com/digitalplaywright).

### Bugfixes

* Fixed Mongoid4 - [@blackxored](https://github.com/blackxored).
* Fixed translation tests - [@digitalplaywright](https://github.com/digitalplaywright).
* Added sparse option to slug index - [@klacointe](https://github.com/klacointe).

## 3.2.0

### Improvements

* Updated stringex dependency to 2.0 or higher - [@digitalplaywright](https://github.com/digitalplaywright).
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

* [#121](https://github.com/mongoid/mongoid-slug/issues/121), [#122](https://github.com/mongoid/mongoid-slug/issues/122): Do not generate empty slug - [@digitalplaywright](https://github.com/digitalplaywright).

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

* [#76](https://github.com/mongoid/mongoid-slug/pull/76): Cleanup of callback handling - [@empact](https://github.com/empact).

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

* [#43](https://github.com/mongoid/mongoid-slug/pull/43): Allowed overriding of slug at model creation time - [@bdmac](https://github.com/bdmac).

## 0.8.3

* Bumped version of Stringex dependency - [@digitalplaywright](https://github.com/digitalplaywright).

## 0.8.2

* Generated a slug when an existing document does not have one - [@digitalplaywright](https://github.com/digitalplaywright).

## 0.8.1

* [#27](https://github.com/mongoid/mongoid-slug/pull/27): No longer necessary to require library in Gemfile - [@etehtsea](https://github.com/etehtsea).

## 0.8.0

* [#23](https://github.com/mongoid/mongoid-slug/pull/23): Fix edbug concerning slugs with double-digit counters - [@jbredeche](https://github.com/jbredeche).
* Removed #slug!. The method is of limited value - [@digitalplaywright](https://github.com/digitalplaywright).

## 0.7.2

* [#21](https://github.com/mongoid/mongoid-slug/pull/21): Added `#find_by_slug!` - [@ajsharp](https://github.com/ajsharp).

## 0.7.1

* [#16](https://github.com/mongoid/mongoid-slug/pull/16): Library no longers hit database multiple times to find unique slug when duplicates exist - [@tiendung](https://github.com/tiendung).

## 0.7.0

* Slug now can be given an optional block to build a custom slug out of the specified fields - [@digitalplaywright](https://github.com/digitalplaywright).

## 0.6.4

* [#10](https://github.com/mongoid/mongoid-slug/pull/10): Added :any option to use first present field when multiple fields are slugged - [@iamnader](https://github.com/iamnader).

## 0.6.3

* [#13](https://github.com/mongoid/mongoid-slug/pull/13): Mongoid no longer requires that emmbedded_in pass `:inverse_of` option - [@sporkd](https://github.com/sporkd).

## 0.6.2

* Added #slug! to generate slug for an existing document - [@digitalplaywright](https://github.com/digitalplaywright).

## 0.6.1

* Added support for STI models - [@dmathieu](https://github.com/dmathieu).

## 0.6.0

* Fixed internals to work with Mongoid RC - [@digitalplaywright](https://github.com/digitalplaywright).
* Finder is now dynamic - [@digitalplaywright](https://github.com/digitalplaywright).

## 0.5.1

* Added support for scoping by reference association - [@ches](https://github.com/ches).
* Brought indexing back in as an option - [@digitalplaywright](https://github.com/digitalplaywright).

## 0.5.0

* Added support for non-Latin languages - [@etehtsea](https://github.com/etehtsea).
* Removed :scoped. Embedded objects are now scoped by parent by default - [@digitalplaywright](https://github.com/digitalplaywright).
* Added finder method - [@digitalplaywright](https://github.com/digitalplaywright).

## Earlier tags

* To be found in the dustbin of git log - [@digitalplaywright](https://github.com/digitalplaywright).
