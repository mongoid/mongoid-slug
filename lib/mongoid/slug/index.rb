module Mongoid
  module Slug
    module Index

      # @param [ String or Symbol ] scope_key The optional scope key for the index
      # @param [ Boolean ] by_model_type Whether or not
      #
      # @return [ Array(Hash, Hash) ] the indexable fields and index options.
      def self.build_index(scope_key = nil, by_model_type = false, is_paranoid_doc = false)
        fields  = {_slugs: 1}
        options = {}

        fields.merge!({scope_key => 1}) if scope_key
        fields.merge!({_type: 1}) if by_model_type

        options.merge!({unique: true, sparse: true}) unless by_model_type || is_paranoid_doc

        return [fields, options]
      end
    end
  end
end
