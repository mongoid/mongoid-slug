require 'forwardable'

# Can use e.g. Mongoid::Slug::UniqueSlug.new(ModelClass.new).find_unique "slug-1" for auto-suggest ui
module Mongoid
  module Slug
    class UniqueSlug
      MUTEX_FOR_SLUG = Mutex.new
      class SlugState
        attr_reader :last_entered_slug, :existing_slugs, :existing_history_slugs, :sorted_existing

        def initialize slug, documents, pattern
          @slug = slug
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

        def slug_included?
          existing_slugs.include? @slug
        end

        def include_slug
          existing_slugs << @slug
        end

        def highest_existing_counter
          sort_existing_slugs
          @sorted_existing.last || 0
        end

        def sort_existing_slugs
          # remove the slug part and leave the absolute integer part and sort
          re = %r(^#{Regexp.escape(@slug)})
          @sorted_existing = existing_slugs.map do |s|
            s.sub(re,'').to_i.abs
          end.sort
        end

        def inspect
          {
            :slug                   => @slug,
            :existing_slugs         => existing_slugs,
            :last_entered_slug      => last_entered_slug,
            :existing_history_slugs => existing_history_slugs,
            :sorted_existing        => sorted_existing
          }
        end
      end

      extend Forwardable

      attr_reader :model, :_slug

      def_delegators :@model, :slug_scope, :reflect_on_association, :read_attribute,
        :check_against_id, :reserved_words, :url_builder, :collection_name,
        :embedded?, :reflect_on_all_associations, :by_model_type

      def initialize model
        @model = model
        @_slug = ""
        @state = nil
      end

      def metadata
        @model.respond_to?(:relation_metadata) ? @model.relation_metadata : @model.metadata
      end

      def find_unique attempt = nil
        MUTEX_FOR_SLUG.synchronize do
          @_slug = if attempt
            attempt.to_url
          else
            url_builder.call(model)
          end
          # Regular expression that matches slug, slug-1, ... slug-n
          # If slug_name field was indexed, MongoDB will utilize that
          # index to match /^.../ pattern.
          pattern = /^#{Regexp.escape(@_slug)}(?:-(\d+))?$/
  
          where_hash = {}
          where_hash[:_slugs.all] = [pattern]
          where_hash[:_id.ne]     = model._id
  
          if (scope = slug_scope) && reflect_on_association(scope).nil?
            # scope is not an association, so it's scoped to a local field
            # (e.g. an association id in a denormalized db design)
            where_hash[scope] = model.try(:read_attribute, scope)
          end
  
          if by_model_type == true
            where_hash[:_type] = model.try(:read_attribute, :_type)
          end
  
          @state = SlugState.new @_slug, uniqueness_scope.unscoped.where(where_hash), pattern
  
          # do not allow a slug that can be interpreted as the current document id
          @state.include_slug unless model.class.look_like_slugs?([@_slug])
  
          # make sure that the slug is not equal to a reserved word
          @state.include_slug if reserved_words.any? { |word| word === @_slug }
  
          # only look for a new unique slug if the existing slugs contains the current slug
          # - e.g if the slug 'foo-2' is taken, but 'foo' is available, the user can use 'foo'.
          if @state.slug_included?
            highest = @state.highest_existing_counter
            @_slug += "-#{highest.succ}"
          end
          @_slug
        end
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
          return model._parent.send(parent_metadata.inverse_of || self.metadata.name)
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
