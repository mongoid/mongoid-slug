# CHANGELOG

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
