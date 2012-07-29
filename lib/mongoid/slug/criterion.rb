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
    # You can override this behaviour and force slugs or _ids to be used by supplying a Hash with the
    # key force_slugs as the final argument to the method.
    #
    # When finding by slugs two database operations will occur: the first to map the slugs to _ids and
    # a second to retrieve the documents. It is recommended that you ensure the Mongoid IdentityMap
    # is enabled to mitigate against this overhead.
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
    # @example Force finding by ids.
    #   criteria.find('some-slug', { force_slugs: false })
    #
    # @example Force finding by slugs.
    #   criteria.find('some-slug', { force_slugs: true })
    #
    # @param [ Array<Object> ] args The ids or slugs to search for.
    #
    # @return [ Array<Document>, Document ] The matching document(s).
    #--
    # We need to check if the args could be Mongo _ids. If they are, we act as Mongoid would normally.
    # Otherwise we assume the args are slugs. In that case we perform a db operation to find the _ids
    # corresponding to the supplied slugs. We then let Mongoid use those _ids as it would normally.
    # This means we are performing two db operations rather than one. For that reason it is recommended
    # that the Mongoid IdentityMap be turned on (our extra db operation will ensure that the IdentityMap
    # is primed with the documents that Mongoid subsequently goes looking for, thus mitigating the expense).
    #
    # Because it is possible that the user may be using a String _id in their document, and in that event
    # there is no reasonable method of inferring whether a supplied argument is a slug or an _id, it is
    # necessary to provide an explicit method of finding by slugs, hence the +:force_slugs+ option.
    #++
    def find(*args)
      opts = { force_slugs: false }
      opts.merge!(args.pop) if args.last.is_a?(Hash)
      ids_or_slugs = args.__find_args__
      raise_invalid if ids_or_slugs.any?(&:nil?)
      if opts[:force_slugs] || look_like_slugs?(ids_or_slugs)
        for_slugs(ids_or_slugs).execute_or_raise_for_slugs(ids_or_slugs, args.multi_arged?)
      else
        for_ids(ids_or_slugs).execute_or_raise(ids_or_slugs, args.multi_arged?)
      end
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
      where({ _slugs: { '$in' => slugs } })
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