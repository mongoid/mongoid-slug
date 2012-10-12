require 'forwardable'

# Can use e.g. Mongoid::Slug::UniqueSlug.new(ModelClass.new).find_unique "slug-1" for auto-suggest ui
module Mongoid
  module Slug
    class UniqueSlug

      class SlugState
        attr_reader :last_entered_slug, :existing_slugs, :existing_history_slugs, :sorted_existing

        def initialize attempt, documents, pattern
          @attempt = attempt
          @documents = documents
          @pattern = pattern
          @last_entered_slug = []
          @existing_slugs = []
          @existing_history_slugs = []
          @sorted_existing = []
          @documents.each do |doc|
            history_slugs = doc._slugs
            next if history_slugs.nil?
            existing_slugs.push(*history_slugs.find_all { |cur_slug| cur_slug =~ @pattern })
            last_entered_slug.push(*history_slugs.last) if history_slugs.last =~ @pattern
            existing_history_slugs.push(*history_slugs.first(history_slugs.length() - 1).find_all { |cur_slug| cur_slug =~ @pattern })
          end
        end

        def existing?
          existing_slugs.size > 0
        end

        def appended?
          existing_slugs.include? @attempt
        end

        def append_attempt
          existing_slugs << @attempt
        end

        def next_counter
          return 1 unless @sorted_existing.last
          @sorted_existing.last.match(/-(\d+)$/).try(:[], 1).to_i.succ
        end

        def sort_existing reference = nil
          @sorted_existing = reference ? counter_sort(reference) : standard_sort
        end

        def counter_sort reference
          # lop off the reference part to leave the counter part i.e '', '-1', '-2'
          base = reference.to_url
          re = %r(^#{Regexp.escape(base)})
          existing_slugs.select do |s|
            s =~ /-(\d+)$/
          end.map do |s|
            s.sub(re,'')
          end.sort
        end

        def standard_sort
          # Sort the existing_slugs in increasing order by comparing the
          # suffix numbers:
          # slug, slug-1, slug-2, ..., slug-n
          existing_slugs.sort do |a, b|
            prep_compare(a) <=> prep_compare(b)
          end
        end

        def prep_compare obj
          (@pattern.match(obj)[1] || -1).to_i
        end
      end

      extend Forwardable

      attr_reader :model, :_slug

      def_delegators :@model, :slug_scope, :reflect_on_association, :read_attribute,
        :check_against_id, :reserved_words, :slug_reference, :url_builder
        :collection_name, :embedded?, :reflect_on_all_associations, :metadata

      def initialize model
        @model = model
        @_slug = ""
        @state = nil
      end

      def find_unique attempt = nil
        @_slug = if attempt
          attempt.to_url
        else
          url_builder.call(model)
        end
        # Regular expression that matches slug, slug-1, ... slug-n
        # If slug_name field was indexed, MongoDB will utilize that
        # index to match /^.../ pattern.
        pattern = /^#{Regexp.escape(_slug)}(?:-(\d+))?$/

        where_hash = {}
        where_hash[:_slugs.all] = [pattern]
        where_hash[:_id.ne]     = model._id

        if (scope = slug_scope) && reflect_on_association(scope).nil?
          # scope is not an association, so it's scoped to a local field
          # (e.g. an association id in a denormalized db design)
          where_hash[scope] = model.try(:read_attribute, scope)
        end

        @state = SlugState.new _slug, uniqueness_scope.where(where_hash), pattern

        # #do not allow a slug that can be interpreted as the current document id
        @state.append_attempt if check_against_id && !model.class.look_like_slugs?([_slug])

        # #make sure that the slug is not equal to a reserved word
        @state.append_attempt if reserved_words.any? { |word| word === _slug }

        #only look for a new unique slug if the existing slugs contains the current slug
        # - e.g if the slug 'foo-2' is taken, but 'foo' is available, the user can use 'foo'.
        if @state.appended? && @state.existing?
          ref = slug_reference ? model.send(slug_reference) : nil
          @state.sort_existing(ref)
          counter = @state.next_counter
          @_slug += "-#{counter}"
        end
        _slug
      end

      def uniqueness_scope

        if slug_scope &&
            metadata = reflect_on_association(slug_scope)

          parent = model.send(metadata.name)

          # Make sure doc is actually associated with something, and that
          # some referenced docs have been persisted to the parent
          #
          # TODO: we need better reflection for reference associations,
          # like association_name instead of forcing collection_name here
          # -- maybe in the forthcoming Mongoid refactorings?
          inverse = metadata.inverse_of || collection_name
          return parent.respond_to?(inverse) ? parent.send(inverse) : model.class
        end

        if embedded?
          parent_metadata = reflect_on_all_associations(:embedded_in)[0]
          return model._parent.send(parent_metadata.inverse_of || model.metadata.name)
        end

        #unless embedded or slug scope, return the deepest document superclass
        appropriate_class = model.class
        while appropriate_class.superclass.include?(Mongoid::Document)
          appropriate_class = appropriate_class.superclass
        end
        appropriate_class
      end
    end
  end
end
