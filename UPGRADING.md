### Upgrading to 6.0.0

#### Support dropped for mongoid_paranoia

Due to the library not being updated, mongoid_paranoia is no longer supported.

### Upgrading to 5.3.0

#### Default value for _slugs is now nil

Neither `_slugs` nor `slugs` default to an empty `Array` and `nil` slugs are allowed since a sparse index is used. Previously a confusing `Mongo::Error::OperationFailure: E11000 duplicate key error index` error was raised on the second record with an empty set of slugs inserted into the database.

You should unset `_slugs` for any documents that have an empty array value.

```ruby
Klass.where(_slugs: []).unset(:_slugs)
Klass.where(_slugs: nil).unset(:_slugs)
```

See [#225](https://github.com/mongoid/mongoid-slug/pull/225) for more information.

#### Changes in unique index definitions

The `:sparse` option on the `_slugs` index is now set in all cases. The `:unique` option is set except in an edge case with Paranoid documents.

See [#172](https://github.com/mongoid/mongoid-slug/pull/172) and [#227](https://github.com/mongoid/mongoid-slug/pull/227) for more information.

### Upgrading to 5.2.0

MongoDB has a default limit around 1KB to the size of the index keys and will raise error 17280, `key too large to index` when trying to create a record that causes an index key to exceed that limit. MongoDB 2.4 did not enforce this limit (see [mongodb#SERVER-5290](https://jira.mongodb.org/browse/SERVER-5290)). MongoDB 2.6 corrected this. Slugs of the form `text[-number]` and the text portion is limited in size to `Mongoid::Slug::MONGO_INDEX_KEY_LIMIT_BYTES - 32` bytes since mongoid-slug 5.2. To restore old behavior, change the constant in your code or set the limit for each model to `nil`. This can be useful when running MongoDB with [failIndexKeyTooLong](https://docs.mongodb.org/manual/reference/parameters/#param.failIndexKeyTooLong) set to `false`, however be advised that MongoDB will make those documents impossible to find when the index is used. Note that setting this limit for exsiting data has no effect on such data.

See [mongoid-slug#204](https://github.com/mongoid/mongoid-slug/pull/204) for more information.

### Deprecated Gem Name

The underscored gem name, _mongoid_slug_, has been deprecated. Use the hyphenated version, _mongoid-slug_.

### Upgrading to 1.0.0

If you are upgrading to Mongoid Slug 1.0.0 please migrate in accordance with the instructions in https://github.com/mongoid/mongoid-slug/wiki/How-to-upgrade-to-1.0.0-or-newer. Mongoid Slug 1.0.0  stores the slugs in a single field _slugs of array type, and all previous slugs must be migrated.
