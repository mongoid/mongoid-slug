# frozen_string_literal: true

require 'mongoid'
require 'stringex'
require 'mongoid/slug/criteria'
require 'mongoid/slug/index_builder'
require 'mongoid/slug/unique_slug'
require 'mongoid/slug/slug_id_strategy'
require 'mongoid/slug/railtie' if defined?(Rails)

module Mongoid
  # Slugs your Mongoid model.
  module Slug
    extend ActiveSupport::Concern

    MONGO_INDEX_KEY_LIMIT_BYTES = 1024

    included do
      cattr_accessor :slug_reserved_words,
                     :slug_scope,
                     :slug_index,
                     :slugged_attributes,
                     :slug_url_builder,
                     :slug_history,
                     :slug_by_model_type,
                     :slug_max_length

      # field :_slugs, type: Array, default: [], localize: false
      # alias_attribute :slugs, :_slugs
    end

    class << self
      attr_accessor :default_slug

      def configure(&block)
        instance_eval(&block)
      end

      def slug(&block)
        @default_slug = block if block_given?
      end
    end

    module ClassMethods
      # @overload slug(*fields)
      #   Sets one ore more fields as source of slug.
      #   @param [Array] fields One or more fields the slug should be based on.
      #   @yield If given, the block is used to build a custom slug.
      #
      # @overload slug(*fields, options)
      #   Sets one ore more fields as source of slug.
      #   @param [Array] fields One or more fields the slug should be based on.
      #   @param [Hash] options
      #   @param options [Boolean] :history Whether a history of changes to
      #   the slug should be retained. When searched by slug, the document now
      #   matches both past and present slugs.
      #   @param options [Boolean] :permanent Whether the slug should be
      #   immutable. Defaults to `false`.
      #   @param options [Array] :reserve` A list of reserved slugs
      #   @param options :scope [Symbol, Array<Symbol, String>] a reference association, field,
      #   or array of fields to scope the slug by.
      #   Embedded documents are, by default, scoped by their parent. Now it supports not only
      #   a single association or field but also an array of them.
      #   @param options :max_length [Integer] the maximum length of the text portion of the slug
      #   @yield If given, a block is used to build a slug.
      #
      # @example A custom builder
      #   class Person
      #     include Mongoid::Document
      #     include Mongoid::Slug
      #
      #     field :names, :type => Array
      #     slug :names do |doc|
      #       doc.names.join(' ')
      #     end
      #   end
      #
      def slug(*fields, &block)
        options = fields.extract_options!

        self.slug_scope            = options[:scope]
        self.slug_index            = options[:index].nil? ? true : options[:index]
        self.slug_reserved_words   = options[:reserve] || Set.new(%w[new edit])
        self.slugged_attributes    = fields.map(&:to_s)
        self.slug_history          = options[:history]
        self.slug_by_model_type    = options[:by_model_type]
        self.slug_max_length       = options.key?(:max_length) ? options[:max_length] : MONGO_INDEX_KEY_LIMIT_BYTES - 32

        field :_slugs, type: Array, localize: options[:localize]
        alias_attribute :slugs, :_slugs

        # Set indexes
        if slug_index && !embedded?
          # Check if scope is an array and handle accordingly.
          if slug_scope.is_a?(Array)
            slug_scope.each do |individual_scope|
              # Here, build indexes for each scope in the array.
              # This assumes `Mongoid::Slug::IndexBuilder.build_indexes` can handle individual scope items.
              # If not, `build_indexes` may need modification to support this.
              Mongoid::Slug::IndexBuilder.build_indexes(self, individual_scope, slug_by_model_type, options[:localize])
            end
          else
            # For a single scope, it remains unchanged.
            Mongoid::Slug::IndexBuilder.build_indexes(self, slug_scope_key, slug_by_model_type, options[:localize])
          end
        end

        self.slug_url_builder = block_given? ? block : default_slug_url_builder

        #-- always create slug on create
        #-- do not create new slug on update if the slug is permanent
        if options[:permanent]
          set_callback :create, :before, :build_slug
        else
          set_callback :save, :before, :build_slug, if: :slug_should_be_rebuilt?
        end
      end

      def default_slug_url_builder
        Mongoid::Slug.default_slug || ->(cur_object) { cur_object.slug_builder.to_url }
      end

      def look_like_slugs?(*args)
        with_default_scope.look_like_slugs?(*args)
      end

      # Returns the scope key for indexing, considering associations
      #
      # @return [ Array<Document>, Document ]
      def slug_scope_key
        return nil unless slug_scope

        # If slug_scope is an array, we return an array of keys.
        if slug_scope.is_a?(Array)
          slug_scope.map do |individual_scope|
            reflect_on_association(individual_scope).try(:key) || individual_scope
          end
        else
          reflect_on_association(slug_scope).try(:key) || slug_scope
        end
      end

      # Find documents by slugs.
      #
      # A document matches if any of its slugs match one of the supplied params.
      #
      # A document matching multiple supplied params will be returned only once.
      #
      # If any supplied param does not match a document a Mongoid::Errors::DocumentNotFound will be raised.
      #
      # @example Find by a slug.
      #   Model.find_by_slug!('some-slug')
      #
      # @example Find by multiple slugs.
      #   Model.find_by_slug!('some-slug', 'some-other-slug')
      #
      # @param [ Array<Object> ] args The slugs to search for.
      #
      # @return [ Array<Document>, Document ] The matching document(s).
      def find_by_slug!(*args)
        with_default_scope.find_by_slug!(*args)
      end

      def queryable
        current_scope || Criteria.new(self) # Use Mongoid::Slug::Criteria for slugged documents.
      end

      private

      if Threaded.method(:current_scope).arity == -1
        def current_scope
          Threaded.current_scope(self)
        end
      else
        def current_scope
          Threaded.current_scope
        end
      end
    end

    # Builds a new slug.
    #
    # @return [true]
    def build_slug
      if localized?
        begin
          orig_locale = I18n.locale
          all_locales.each do |target_locale|
            I18n.locale = target_locale
            apply_slug
          end
        ensure
          I18n.locale = orig_locale
        end
      else
        apply_slug
      end
      true
    end

    def apply_slug
      new_slug = find_unique_slug

      # skip slug generation and use Mongoid id
      # to find document instead
      return true if new_slug.empty?

      # avoid duplicate slugs
      _slugs&.delete(new_slug)

      if !!slug_history && _slugs.is_a?(Array)
        append_slug(new_slug)
      else
        self._slugs = [new_slug]
      end
    end

    # Builds slug then atomically sets it in the database.
    #
    # This method is adapted to use the :set method variants from both
    # Mongoid 3 (two args) and Mongoid 4 (hash arg)
    def set_slug!
      build_slug
      method(:set).arity == 1 ? set(_slugs: _slugs) : set(:_slugs, _slugs)
    end

    # Atomically unsets the slug field in the database. It is important to unset
    # the field for the sparse index on slugs.
    #
    # This also resets the in-memory value of the slug field to its default (empty array)
    def unset_slug!
      unset(:_slugs)
      clear_slug!
    end

    # Rolls back the slug value from the Mongoid changeset.
    def reset_slug!
      reset__slugs!
    end

    # Sets the slug to its default value.
    def clear_slug!
      self._slugs = []
    end

    # Finds a unique slug, were specified string used to generate a slug.
    #
    # Returned slug will the same as the specified string when there are no
    # duplicates.
    #
    # @return [String] A unique slug
    def find_unique_slug
      UniqueSlug.new(self).find_unique
    end

    # @return [Boolean] Whether the slug requires to be rebuilt
    def slug_should_be_rebuilt?
      new_record? || _slugs_changed? || slugged_attributes_changed?
    end

    def slugged_attributes_changed?
      slugged_attributes.any? { |f| attribute_changed? f.to_s }
    end

    # @return [String] A string which Action Pack uses for constructing an URL
    # to this record.
    def to_param
      slug || super
    end

    # @return [String] the slug, or nil if the document does not have a slug.
    def slug
      return _slugs.last if _slugs

      _id.to_s
    end

    def slug_builder
      cur_slug = nil
      if new_with_slugs? || persisted_with_slug_changes?
        # user defined slug
        cur_slug = _slugs.last
      end
      # generate slug if the slug is not user defined or does not exist
      cur_slug || pre_slug_string
    end

    private

    def append_slug(value)
      if localized?
        # This is necessary for the scenario in which the slugged locale is not yet present
        # but the default locale is. In this situation, self._slugs falls back to the default
        # which is undesired
        current_slugs = _slugs_translations.fetch(I18n.locale.to_s, [])
        current_slugs << value
        self._slugs_translations = _slugs_translations.merge(I18n.locale.to_s => current_slugs)
      else
        _slugs << value
      end
    end

    # Returns true if object is a new record and slugs are present
    def new_with_slugs?
      if localized?
        # We need to check if slugs are present for the locale without falling back
        # to a default
        new_record? && _slugs_translations.fetch(I18n.locale.to_s, []).any?
      else
        new_record? && _slugs.present?
      end
    end

    # Returns true if object has been persisted and has changes in the slug
    def persisted_with_slug_changes?
      if localized?
        changes = _slugs_change
        return (persisted? && false) if changes.nil?

        # ensure we check for changes only between the same locale
        original = changes.first.try(:fetch, I18n.locale.to_s, nil)
        compare = changes.last.try(:fetch, I18n.locale.to_s, nil)
        persisted? && original != compare
      else
        persisted? && _slugs_changed?
      end
    end

    def localized?
      fields['_slugs'].options[:localize]
    rescue StandardError
      false
    end

    # Return all possible locales for model
    # Avoiding usage of I18n.available_locales in case the user hasn't set it properly, or is
    # doing something crazy, but at the same time we need a fallback in case the model doesn't
    # have any localized attributes at all (extreme edge case).
    def all_locales
      locales = slugged_attributes
                .map { |attr| send("#{attr}_translations").keys if respond_to?("#{attr}_translations") }
                .flatten.compact.uniq
      locales = I18n.available_locales if locales.empty?
      locales
    end

    def pre_slug_string
      slugged_attributes.map { |f| send f }.join ' '
    end
  end
end
