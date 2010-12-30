CHANGELOG
=========

0.5.1
-----

* Added support for scoping by a reference association via :scope
  option. Thanks, Ches.
* Added :index option. This will create an index on the slug in
  top-level objects.

0.5.0
-----

* Added support for non-Latin languages. Thanks, Konstantin Shabanov.
* Removed :scoped option. Embedded objects are now scoped by parent by
  default.
* Added a .find_by_slug helper.
