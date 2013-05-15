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
                     :by_model_type,
                     :sync,
                     :syncing

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
      #   @param options [Boolean] :sync Whether the slug should update the
      #   fields the slug is based on to the value of the newly generated
      #   slug. Not recommended for multiple fields. Defaults to `false`.
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
        self.sync                  = options[:sync]

        field :_slugs, type: Array, default: [], localize: options[:localize]
        alias_attribute :slugs, :_slugs

        unless embedded?
          if slug_scope
            scope_key = (metadata = self.reflect_on_association(slug_scope)) ? metadata.key : slug_scope
            if options[:by_model_type] == true
              # Add _type to the index to fix polymorphism
              index({ _type: 1, scope_key => 1, _slugs: 1}, {unique: true})
            else
              index({scope_key => 1, _slugs: 1}, {unique: true})
            end

          else
            # Add _type to the index to fix polymorphism
            if options[:by_model_type] == true
              index({_type: 1, _slugs: 1}, {unique: true})
            else
              index({_slugs: 1}, {unique: true})
            end
          end
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
      end

      def look_like_slugs?(*args)
        with_default_scope.look_like_slugs?(*args)
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

    end

    # Builds a new slug.
    #
    # @return [true]
    def build_slug
      _new_slug = find_unique_slug

      #skip slug generation and use Mongoid id
      #to find document instead
      return true if _new_slug.size == 0

      self._slugs.delete(_new_slug) if self._slugs

      if !!self.history && self._slugs.is_a?(Array)
        self._slugs << _new_slug
      else
        self._slugs = [_new_slug]
      end

      if sync
        self.syncing = true
        slugged_attributes.each do |slugged_attribute|
          update_attribute slugged_attribute, _new_slug
        end
        self.syncing = false
      end

      true

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
      (new_record? or _slugs_changed? or slugged_attributes_changed?) and !syncing
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
      if (new_record? and _slugs.present?) or (persisted? and _slugs_changed?)
        #user defined slug
        _cur_slug =  _slugs.last
      end
      #generate slug if the slug is not user defined or does not exist
      _cur_slug || pre_slug_string
    end

    private

    def pre_slug_string
      self.slugged_attributes.map { |f| self.send f }.join ' '
    end
  end
end

