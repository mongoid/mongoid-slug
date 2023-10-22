# frozen_string_literal: true

require 'forwardable'

# Can use e.g. Mongoid::Slug::UniqueSlug.new(ModelClass.new).find_unique "slug-1" for auto-suggest ui
module Mongoid
  module Slug
    class UniqueSlug
      MUTEX_FOR_SLUG = Mutex.new
      class SlugState
        attr_reader :last_entered_slug, :existing_slugs, :existing_history_slugs, :sorted_existing

        def initialize(slug, documents, pattern)
          @slug = slug
          @documents = documents
          @pattern = pattern
          @last_entered_slug = []
          @existing_slugs = []
          @existing_history_slugs = []
          @sorted_existing = []
          regexp_pattern = Regexp.new(@pattern)
          @documents.each do |doc|
            history_slugs = doc._slugs
            next if history_slugs.nil?

            existing_slugs.push(*history_slugs.grep(regexp_pattern))
            last_entered_slug.push(*history_slugs.last) if history_slugs.last =~ regexp_pattern
            existing_history_slugs.push(*history_slugs.first(history_slugs.length - 1).grep(regexp_pattern))
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
          re = /^#{Regexp.escape(@slug)}/
          @sorted_existing = existing_slugs.map do |s|
            s.sub(re, '').to_i.abs
          end.sort
        end

        def inspect
          {
            slug: @slug,
            existing_slugs: existing_slugs,
            last_entered_slug: last_entered_slug,
            existing_history_slugs: existing_history_slugs,
            sorted_existing: sorted_existing
          }
        end
      end

      extend Forwardable

      attr_reader :model, :_slug

      def_delegators :@model, :slug_scope, :reflect_on_association, :read_attribute,
                     :check_against_id, :slug_reserved_words, :slug_url_builder, :collection_name,
                     :embedded?, :reflect_on_all_associations, :reflect_on_all_association,
                     :slug_by_model_type, :slug_max_length

      def initialize(model)
        @model = model
        @_slug = ''
        @state = nil
      end

      def metadata
        if @model.respond_to?(:_association)
          @model.send(:_association)
        elsif @model.respond_to?(:relation_metadata)
          @model.relation_metadata
        else
          @model.metadata
        end
      end

      def find_unique(attempt = nil)
        MUTEX_FOR_SLUG.synchronize do
          @_slug = if attempt
                     attempt.to_url
                   else
                     slug_url_builder.call(model)
                   end

          @_slug = @_slug[0...slug_max_length] if slug_max_length

          where_hash = {}
          where_hash[:_slugs.all] = [regex_for_slug]
          where_hash[:_id.ne]     = model._id

          if (scope = slug_scope)
            Array(scope).each do |individual_scope|
              next unless reflect_on_association(individual_scope).nil?

              # scope is not an association, so it's scoped to a local field
              # (e.g. an association id in a denormalized db design)
              where_hash[individual_scope] = model.try(:read_attribute, individual_scope)
            end
          end

          where_hash[:_type] = model.try(:read_attribute, :_type) if slug_by_model_type

          @state = SlugState.new @_slug, uniqueness_scope.unscoped.where(where_hash), escaped_pattern

          # do not allow a slug that can be interpreted as the current document id
          @state.include_slug unless model.class.look_like_slugs?([@_slug])

          # make sure that the slug is not equal to a reserved word
          @state.include_slug if slug_reserved_words.any? { |word| word === @_slug } # rubocop:disable Style/CaseEquality

          # only look for a new unique slug if the existing slugs contains the current slug
          # - e.g if the slug 'foo-2' is taken, but 'foo' is available, the user can use 'foo'.
          if @state.slug_included?
            highest = @state.highest_existing_counter
            @_slug += "-#{highest.succ}"
          end
          @_slug
        end
      end

      def escaped_pattern
        "^#{Regexp.escape(@_slug)}(?:-(\\d+))?$"
      end

      # Regular expression that matches slug, slug-1, ... slug-n
      # If slug_name field was indexed, MongoDB will utilize that
      # index to match /^.../ pattern.
      # Use Regexp::Raw to avoid the multiline option when querying the server.
      def regex_for_slug
        if embedded?
          Regexp.new(escaped_pattern)
        else
          BSON::Regexp::Raw.new(escaped_pattern)
        end
      end

      def uniqueness_scope
        # If slug_scope is present, we need to handle whether it's a single scope or multiple scopes.
        if slug_scope
          # We'll track individual scope results in an array.
          scope_results = []

          Array(slug_scope).each do |individual_scope|
            next unless (metadata = reflect_on_association(individual_scope))

            # For each scope, we identify its association metadata and fetch the parent record.
            parent = model.send(metadata.name)

            # It's important to handle nil cases if the parent record doesn't exist.
            if parent.nil?
              # You might want to handle this scenario differently based on your application's logic.
              next
            end

            # Make sure doc is actually associated with something, and that
            # some referenced docs have been persisted to the parent
            #
            # TODO: we need better reflection for reference associations,
            # like association_name instead of forcing collection_name here
            # -- maybe in the forthcoming Mongoid refactorings?
            inverse = metadata.inverse_of || collection_name
            next unless parent.respond_to?(inverse)

            # Add the associated records of the parent (based on the inverse) to our results.
            scope_results << parent.send(inverse)
          end

          # After iterating through all scopes, we need to decide how to combine the results (if there are multiple).
          # This part depends on how your application should treat multiple scopes.
          # Here, we'll simply return the first non-empty scope result as an example.
          scope_results.each do |result|
            return result if result.present? # or any other logic for selecting among multiple scope results
          end

          # If we reach this point, it means no valid parent scope was found (all were nil or didn't match the
          # conditions).
          # You might want to raise an error, return a default scope, or handle this scenario based on your
          # application's logic.
          # For this example, we're returning the model's class as a default.
          return model.class
        end

        # The rest of your method remains unchanged, handling cases where slug_scope isn't defined.
        # This is your existing logic for embedded models or deeper superclass retrieval.
        if embedded?
          parent_metadata = reflect_on_all_association(:embedded_in)[0]
          return model._parent.send(parent_metadata.inverse_of || self.metadata.name)
        end

        # Unless embedded or slug scope, return the deepest document superclass.
        appropriate_class = model.class
        appropriate_class = appropriate_class.superclass while appropriate_class.superclass.include?(Mongoid::Document)
        appropriate_class
      end
    end
  end
end
