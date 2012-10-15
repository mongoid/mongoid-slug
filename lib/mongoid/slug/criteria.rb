# require 'moped/bson/object_id'

module Mongoid
  module Slug
    class Criteria < Mongoid::Criteria
      # Find the matchind document(s) in the criteria for the provided ids or slugs.
      #
      # If the document _ids are of the type Moped::BSON::ObjectId, and all the supplied parameters are
      # convertible to Moped::BSON::ObjectId (via Moped::BSON::ObjectId#from_string), finding will be
      # performed via _ids.
      #
      # If the document has any other type of _id field, and all the supplied parameters are of the same
      # type, finding will be performed via _ids.
      #
      # Otherwise finding will be performed via slugs.
      #
      # @example Find by an id.
      #   criteria.find(Moped::BSON::ObjectId.new)
      #
      # @example Find by multiple ids.
      #   criteria.find([ Moped::BSON::ObjectId.new, Moped::BSON::ObjectId.new ])
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

      # True if all supplied args look like slugs. Will only attempt to type cast for Moped::BSON::ObjectId.
      # Thus '123' will be interpreted as a slug even if the _id is an Integer field, etc.
      def look_like_slugs?(args)
        return false unless args.all? { |id| id.is_a?(String) }
        id_type = @klass.fields['_id'].type.to_s.downcase
        strategy = check_strategies[id_type]
        args.none? { |id| strategy.call(id) }
      end
      
      def check_strategies
        @check_strategies ||= build_strategies
      end

      def build_strategies
        hash = {
          'moped::bson::objectid' => method(:object_id_check),
          'string'                => method(:string_id_check)
        }
        hash.default = lambda {|id| false}
        hash
      end

      def object_id_check id
        Moped::BSON::ObjectId.legal?(id)
      end

      def string_id_check id
        true
      end

      protected

      def for_slugs(slugs)
        where({ _slugs: { '$in' => slugs } }).limit(slugs.length)
      end

      def execute_or_raise_for_slugs(slugs, multi)
        result = uniq
        check_for_missing_documents_for_slugs!(result, slugs)
        multi ? result : result.first
      end

      def check_for_missing_documents_for_slugs!(result, slugs)
        missing_slugs = slugs - result.map(&:slugs).flatten

        if !missing_slugs.blank? && Mongoid.raise_not_found_error
          raise Errors::DocumentNotFound.new(klass, slugs, missing_slugs)
        end
      end
    end
  end
end
