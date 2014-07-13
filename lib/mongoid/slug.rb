module Mongoid
  # Slugs your Mongoid model.
  module Slug
    extend ActiveSupport::Concern

    included do
      cattr_accessor :reserved_words,
                     :slug_scope,
                     :slugged_attributes,
                     :url_builder,
                     :history,
                     :by_model_type

      # field :_slugs, type: Array, default: [], localize: false
      # alias_attribute :slugs, :_slugs
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
      #   @param options :scope [Symbol] a reference association or field to
      #   scope the slug by. Embedded documents are, by default, scoped by
      #   their parent.
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
        self.reserved_words        = options[:reserve] || Set.new(["new", "edit"])
        self.slugged_attributes    = fields.map &:to_s
        self.history               = options[:history]
        self.by_model_type         = options[:by_model_type]

        field :_slugs, type: Array, default: [], localize: options[:localize]
        alias_attribute :slugs, :_slugs

        # Set index
        unless embedded?
          index(*Mongoid::Slug::Index.build_index(self.slug_scope_key, self.by_model_type))
        end

        #-- Why is it necessary to customize the slug builder?
        default_url_builder = lambda do |cur_object|
          cur_object.slug_builder.to_url
        end

        self.url_builder = block_given? ? block : default_url_builder

        #-- always create slug on create
        #-- do not create new slug on update if the slug is permanent
        if options[:permanent]
          set_callback :create, :before, :build_slug
        else
          set_callback :save, :before, :build_slug, :if => :slug_should_be_rebuilt?
        end

        # If paranoid document:
        # - include shim to add callbacks for restore method
        # - unset the slugs on destroy
        # - recreate the slug on restore
        # - force reset the slug when saving a destroyed paranoid document, to ensure it stays unset in the database
        if is_paranoid_doc?
          self.send(:include, Mongoid::Slug::Paranoia) unless self.respond_to?(:before_restore)
          set_callback :destroy, :after,  :unset_slug!
          set_callback :restore, :before, :set_slug!
          set_callback :save,    :before, :reset_slug!, :if => :paranoid_deleted?
          set_callback :save,    :after,  :clear_slug!, :if => :paranoid_deleted?
        end
      end

      def look_like_slugs?(*args)
        with_default_scope.look_like_slugs?(*args)
      end

      # Returns the scope key for indexing, considering associations
      #
      # @return [ Array<Document>, Document ] Whether the document is paranoid
      def slug_scope_key
        return nil unless self.slug_scope
        self.reflect_on_association(self.slug_scope).try(:key) || self.slug_scope
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
        scope_stack.last || Criteria.new(self) # Use Mongoid::Slug::Criteria for slugged documents.
      end

      # Indicates whether or not the document includes Mongoid::Paranoia
      #
      # This can be replaced with .paranoid? method once the following PRs are merged:
      # - https://github.com/simi/mongoid-paranoia/pull/19
      # - https://github.com/haihappen/mongoid-paranoia/pull/3
      #
      # @return [ Array<Document>, Document ] Whether the document is paranoid
      def is_paranoid_doc?
        !!(defined?(::Mongoid::Paranoia) && self < ::Mongoid::Paranoia)
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
      _new_slug = find_unique_slug

      #skip slug generation and use Mongoid id
      #to find document instead
      return true if _new_slug.size == 0

      # avoid duplicate slugs
      self._slugs.delete(_new_slug) if self._slugs

      if !!self.history && self._slugs.is_a?(Array)
        append_slug(_new_slug)
      else
        self._slugs = [_new_slug]
      end
    end

    # Builds slug then atomically sets it in the database.
    # This is used when working with the Mongoid::Paranoia restore callback.
    #
    # This method is adapted to use the :set method variants from both
    # Mongoid 3 (two args) and Mongoid 4 (hash arg)
    def set_slug!
      build_slug
      self.method(:set).arity == 1 ? set({_slugs: self._slugs}) : set(:_slugs, self._slugs)
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
      self.reset__slugs!
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
      (new_record? or _slugs_changed? or slugged_attributes_changed?) and !paranoid_deleted?
    end

    # Indicates whether or not the document has been deleted in paranoid fashion
    # Always returns false if the document is not paranoid
    #
    # @return [Boolean] Whether or not the document has been deleted in paranoid fashion
    def paranoid_deleted?
      !!(self.class.is_paranoid_doc? and self.deleted_at != nil)
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
      return _id.to_s
    end

    def slug_builder
      _cur_slug = nil
      if new_with_slugs? or persisted_with_slug_changes?
        #user defined slug
        _cur_slug = _slugs.last
      end
      #generate slug if the slug is not user defined or does not exist
      _cur_slug || pre_slug_string
    end

    def self.mongoid3?
      ::Mongoid.const_defined? :Observer
    end

    private

    def append_slug(_slug)
      if localized?
        # This is necessary for the scenario in which the slugged locale is not yet present
        # but the default locale is. In this situation, self._slugs falls back to the default
        # which is undesired
        current_slugs = self._slugs_translations.fetch(I18n.locale.to_s, [])
        current_slugs << _slug
        self._slugs_translations = self._slugs_translations.merge(I18n.locale.to_s => current_slugs)
      else
        self._slugs << _slug
      end
    end

    # Returns true if object is a new record and slugs are present
    def new_with_slugs?
      if localized?
        # We need to check if slugs are present for the locale without falling back
        # to a default
        new_record? and _slugs_translations.fetch(I18n.locale.to_s, []).any?
      else
        new_record? and _slugs.present?
      end
    end

    # Returns true if object has been persisted and has changes in the slug
    def persisted_with_slug_changes?
      if localized?
        changes = self._slugs_change
        return (persisted? and false) if changes.nil?

        # ensure we check for changes only between the same locale
        original = changes.first.try(:fetch, I18n.locale.to_s, nil)
        compare = changes.last.try(:fetch, I18n.locale.to_s, nil)
        persisted? and original != compare
      else
        persisted? and _slugs_changed?
      end
    end

    def localized?
      self.fields['_slugs'].options[:localize] rescue false
    end

    # Return all possible locales for model
    # Avoiding usage of I18n.available_locales in case the user hasn't set it properly, or is
    # doing something crazy, but at the same time we need a fallback in case the model doesn't
    # have any localized attributes at all (extreme edge case).
    def all_locales
      locales = self.slugged_attributes
                    .map{|attr| self.send("#{attr}_translations").keys if self.respond_to?("#{attr}_translations")}
                    .flatten.compact.uniq
      locales = I18n.available_locales if locales.empty?
      locales
    end

    def pre_slug_string
      self.slugged_attributes.map { |f| self.send f }.join ' '
    end
  end
end

