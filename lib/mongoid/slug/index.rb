module Mongoid
  module Slug
    module Index

      # @param [ String or Symbol ] scope_key The optional scope key for the index
      # @param [ Boolean ] by_model_type Whether or not
      #
      # @return [ Array(Hash, Hash) ] the indexable fields and index options.
      def self.build_index(scope_key = nil, by_model_type = false)
        fields  = {_slugs: 1}
        options = {}

        if scope_key
          fields.merge!({scope_key => 1})
        end

        if by_model_type
          fields.merge!({_type: 1})
        else
          options.merge!({unique: true, sparse: true})
        end

        return [fields, options]
      end
    end
  end
end
