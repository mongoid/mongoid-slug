module Mongoid
  module Slug
    module Index

      # @param [ String or Symbol ] scope_key The optional scope key for the index
      # @param [ Boolean ] by_model_type Whether or not
      #
      # @return [ Array(Hash, Hash) ] the indexable fields and index options.
      def self.build_index(scope_key = nil, by_model_type = false, paranoid = false)
        fields  = {_slugs: 1}
        fields.merge!(scope_key => 1) if scope_key
        fields.merge!(_type: 1)       if by_model_type

        # The sparse index option is always set, as in theory it increases performance when
        # a large number of records do not have a _slugs value. Note the sparse option is not
        # particularly useful with compound keys (i.e. when scope_key or by_model_type is set),
        # as the index is created whenever ANY of the key values is present (i.e. even when _slugs is unset)
        # See: http://docs.mongodb.org/manual/core/index-sparse/
        options = {sparse: true}

        # By design, we use the unique index constraint when possible to enforce slug uniqueness.
        # There are two edge cases where it must not be unique:
        #
        # 1) Single Table Inheritance (`by_model_type`) creates indexes on the base (parent) table,
        #    and the indexes will be applied to EVERY child (regardless if they are only defined on
        #    ONE child). This can cause collisions using various combinations of scopes/non-scopes
        #
        # 2) Paranoid docs rely on sparse indexes to exclude paranoid-deleted records
        #    from the unique index constraint (i.e. when _slugs is unset.) However, when
        #    using compound keys (`by_model_type` or `scope_key`, see above), paranoid-deleted records can become
        #    inadvertently indexed when _slugs is unset, causing duplicates
        options.merge!(unique: true) unless by_model_type || (paranoid && scope_key)

        return [fields, options]
      end
    end
  end
end
