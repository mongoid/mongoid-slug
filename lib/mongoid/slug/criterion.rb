require 'moped/bson/object_id'

module Mongoid
  class Criteria
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
    alias :original_find :find
    def find(*args)
      return original_find(*args) unless @klass.ancestors.include?(Mongoid::Slug)

      send (look_like_slugs?(args.__find_args__) ? :find_by_slug! : :original_find), *args
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

    protected

    # True if all supplied args look like slugs. Will only attempt to type cast for Moped::BSON::ObjectId.
    # Thus '123' will be interpreted as a slug even if the _id is an Integer field, etc.
    def look_like_slugs?(args)
      if args.all? { |id| id.is_a?(String) }
        id_type = @klass.fields['_id'].type
        case
          when id_type == Moped::BSON::ObjectId
            args.any? { |id| !Moped::BSON::ObjectId.legal?(id) }
          else args.any? { |id| id.class != id_type }
        end
      else
        false
      end
    end

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
