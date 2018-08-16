module Mongoid
  module Slug
    class Criteria < Mongoid::Criteria
      # Find the matching document(s) in the criteria for the provided ids or slugs.
      #
      # If the document _ids are of the type BSON::ObjectId, and all the supplied parameters are
      # convertible to BSON::ObjectId (via BSON::ObjectId#from_string), finding will be
      # performed via _ids.
      #
      # If the document has any other type of _id field, and all the supplied parameters are of the same
      # type, finding will be performed via _ids.
      #
      # Otherwise finding will be performed via slugs.
      #
      # @example Find by an id.
      #   criteria.find(BSON::ObjectId.new)
      #
      # @example Find by multiple ids.
      #   criteria.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
      #
      # @example Find by a slug.
      #   criteria.find('some-slug')
      #
      # @example Find by multiple slugs.
      #   criteria.find([ 'some-slug', 'some-other-slug' ])
      #
      # @param [ Array<Object> ] args The ids or slugs to search for.
      #
      # @return [ Array<Document>, Document ] The matching document(s).
      def find(*args)
        look_like_slugs?(args.__find_args__) ? find_by_slug!(*args) : super
      end

      # Find the matchind document(s) in the criteria for the provided slugs.
      #
      # @example Find by a slug.
      #   criteria.find('some-slug')
      #
      # @example Find by multiple slugs.
      #   criteria.find([ 'some-slug', 'some-other-slug' ])
      #
      # @param [ Array<Object> ] args The slugs to search for.
      #
      # @return [ Array<Document>, Document ] The matching document(s).
      def find_by_slug!(*args)
        slugs = args.__find_args__
        raise_invalid if slugs.any?(&:nil?)
        for_slugs(slugs).execute_or_raise_for_slugs(slugs, args.multi_arged?)
      end

      def look_like_slugs?(args)
        return false unless args.all? { |id| id.is_a?(String) }
        id_field = @klass.fields['_id']
        @slug_strategy ||= id_field.options[:slug_id_strategy] || build_slug_strategy(id_field.type)
        args.none? { |id| @slug_strategy.call(id) }
      end

      protected

      # unless a :slug_id_strategy option is defined on the id field,
      # use object_id or string strategy depending on the id_type
      # otherwise default for all other id_types
      def build_slug_strategy(id_type)
        type_method = id_type.to_s.downcase.split('::').last + '_slug_strategy'
        respond_to?(type_method, true) ? method(type_method) : ->(_id) { false }
      end

      # a string will not look like a slug if it looks like a legal BSON::ObjectId
      def objectid_slug_strategy(id)
        Mongoid::Compatibility::ObjectId.legal?(id)
      end

      # a string will always look like a slug
      def string_slug_strategy(_id)
        true
      end

      def for_slugs(slugs)
        # _translations
        localized = (begin
                       @klass.fields['_slugs'].options[:localize]
                     rescue StandardError
                       false
                     end)
        if localized
          def_loc = I18n.default_locale
          query = { '$in' => slugs }
          where({ '$or' => [{ _slugs: query }, { "_slugs.#{def_loc}" => query }] }).limit(slugs.length)
        else
          where(_slugs: { '$in' => slugs }).limit(slugs.length)
        end
      end

      def execute_or_raise_for_slugs(slugs, multi)
        result = uniq
        check_for_missing_documents_for_slugs!(result, slugs)
        multi ? result : result.first
      end

      def check_for_missing_documents_for_slugs!(result, slugs)
        missing_slugs = slugs - result.map(&:slugs).flatten
        return unless !missing_slugs.blank? && Mongoid.raise_not_found_error
        raise Errors::DocumentNotFound.new(klass, slugs, missing_slugs)
      end
    end
  end
end
