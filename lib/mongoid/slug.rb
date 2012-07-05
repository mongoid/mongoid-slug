module Mongoid
  # The Slug module helps you generate a URL slug or permalink based on one or
  # more fields in a Mongoid model.
  module Slug
    extend ActiveSupport::Concern

    included do
      cattr_accessor :slug_builder,
                     :slug_name,
                     :slug_history_name,
                     :slug_scope,
                     :reserved_words_in_slug,
                     :slugged_attributes
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
      #   @param options [String] :as The name of the field that stores the
      #   slug. Defaults to `slug`.
      #   @param options [Boolean] :history Whether a history of changes to
      #   the slug should be retained. When searched by slug, the document now
      #   matches both past and present slugs.
      #   @param options [Boolean] :index Whether an index should be defined
      #   on the slug field. Defaults to `false` and has no effect if the
      #   document is embedded.
      #   Make sure you have a unique index on the slugs of root documents to
      #   avoid race conditions.
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

        self.slug_scope             = options[:scope]
        self.reserved_words_in_slug = options[:reserve] || []
        self.slug_name              = options[:as] || :slug
        self.slugged_attributes     = fields.map(&:to_s)
        if options[:history]
          self.slug_history_name    = "#{self.slug_name}_history".to_sym
        end

        default_builder = lambda do |doc|
          slugged_attributes.map { |f| doc.send f }.join ' '
        end
        self.slug_builder = block_given? ? block : default_builder

        field slug_name

        unless slug_name == :slug
          alias_attribute :slug, slug_name
        end

        if slug_history_name
          field slug_history_name, :type => Array, :default => []
        end

        if options[:index]
          if slug_scope
            index [[slug_name, Mongo::ASCENDING], [slug_scope, Mongo::ASCENDING]], :unique => true
          else
            index slug_name, :unique => true
          end
          index slug_history_name if slug_history_name
        end

        set_callback options[:permanent] ? :create : :save, :before do |doc|
          doc.build_slug if doc.slug_should_be_rebuilt?
        end

        # Build a finder for slug.
        #
        # Defaults to `find_by_slug`.
        instance_eval <<-CODE
          def self.find_by_#{slug_name}(slug)
            if slug_history_name
              any_of({ slug_name => slug }, { slug_history_name => slug })
            else
              where(slug_name => slug)
            end.first
          end

          def self.find_by_#{slug_name}!(slug)
            self.find_by_#{slug_name}(slug) ||
              raise(Mongoid::Errors::DocumentNotFound.new self, slug)
          end
        CODE

        # Build a scope based on the slug name.
        #
        # Defaults to `by_slug`.
        scope "by_#{slug_name}".to_sym, lambda { |slug|
          if slug_history_name
            any_of({ slug_name => slug }, { slug_history_name => slug })
          else
            where(slug_name => slug)
          end
        }
      end

      # Finds a unique slug, were specified string used to generate a slug.
      #
      # Returned slug will the same as the specified string when there are no
      # duplicates.
      #
      # @param [String] desired_slug
      # @param [Hash] options
      # @param options [Symbol] :scope The scope that should be used to
      # generate the slug, if the class creates scoped slugs. Defaults to
      # `nil`.
      # @param options [Constant] :model The model that the slug should be
      # generated for. This option overrides `:scope`, as the scope can now
      # be extracted from the model. Defaults to `nil`.
      # @return [String] A unique slug
      def find_unique_slug_for(desired_slug, options = {})
        if slug_scope && self.reflect_on_association(slug_scope).nil?
          scope_object    = uniqueness_scope(options[:model])
          scope_attribute = options[:scope] || options[:model].try(:read_attribute, slug_scope)
        else
          scope_object = options[:scope] || uniqueness_scope(options[:model])
          scope_attribute = nil
        end

        excluded_id = options[:model]._id if options[:model]

        slug = desired_slug.to_url

        # Regular expression that matches slug, slug-1, ... slug-n
        # If slug_name field was indexed, MongoDB will utilize that
        # index to match /^.../ pattern.
        pattern = /^#{Regexp.escape(slug)}(?:-(\d+))?$/

        if slug_scope &&
           self.reflect_on_association(slug_scope).nil?
          # scope is not an association, so it's scoped to a local field
          # (e.g. an association id in a denormalized db design)

          where_hash = {}
          where_hash[slug_name]  = pattern
          where_hash[:_id.ne]    = excluded_id if excluded_id
          where_hash[slug_scope] = scope_attribute

          existing_slugs =
            deepest_document_superclass.
            only(slug_name).
            where(where_hash)
        else
          where_hash = {}
          where_hash[slug_name] = pattern
          where_hash[:_id.ne]   = excluded_id if excluded_id

          existing_slugs =
            scope_object.
            only(slug_name).
            where(where_hash)
        end

        existing_slugs = existing_slugs.map do |doc|
          doc.slug
        end

        if slug_history_name
          if slug_scope &&
             self.reflect_on_association(slug_scope).nil?
            # scope is not an association, so it's scoped to a local field
            # (e.g. an association id in a denormalized db design)

            where_hash = {}
            where_hash[slug_history_name.all] = [pattern]
            where_hash[:_id.ne]               = excluded_id if excluded_id
            where_hash[slug_scope]            = scope_attribute

            history_slugged_documents =
              deepest_document_superclass.
              where(where_hash)
          else
            where_hash = {}
            where_hash[slug_history_name.all] = [pattern]
            where_hash[:_id.ne]               = excluded_id if excluded_id

            history_slugged_documents =
              scope_object.
              where(where_hash)
          end

          existing_history_slugs = []
          history_slugged_documents.each do |doc|
            history_slugs = doc.read_attribute(slug_history_name)
            next if history_slugs.nil?
            existing_history_slugs.push(*history_slugs.find_all { |slug| slug =~ pattern })
          end

          # If the only conflict is in the history of a document in the same scope,
          # transfer the slug
          if slug_scope && existing_slugs.count == 0 && existing_history_slugs.count > 0
            history_slugged_documents.each do |doc|
              doc_history_slugs = doc.read_attribute(slug_history_name)
              next if doc_history_slugs.nil?
              doc_history_slugs -= existing_history_slugs
              doc.write_attribute(slug_history_name, doc_history_slugs)
              doc.save
            end
            existing_history_slugs = []
          end

          existing_slugs += existing_history_slugs
        end

        # Do not allow BSON::ObjectIds as slugs
        existing_slugs << slug if Moped::BSON::ObjectId.legal?(slug)

        if reserved_words_in_slug.any? { |word| word === slug }
          existing_slugs << slug
        end

        if existing_slugs.count > 0
          # Sort the existing_slugs in increasing order by comparing the
          # suffix numbers:
          # slug, slug-1, slug-2, ..., slug-n
          existing_slugs.sort! do |a, b|
            (pattern.match(a)[1] || -1).to_i <=>
            (pattern.match(b)[1] || -1).to_i
          end
          max = existing_slugs.last.match(/-(\d+)$/).try(:[], 1).to_i

          slug += "-#{max + 1}"
        end

        slug
      end

      private

      def uniqueness_scope(model = nil)
        if model
          if slug_scope && (metadata = self.reflect_on_association(slug_scope))
            parent = model.send(metadata.name)

            # Make sure doc is actually associated with something, and that
            # some referenced docs have been persisted to the parent
            #
            # TODO: we need better reflection for reference associations,
            # like association_name instead of forcing collection_name here
            # -- maybe in the forthcoming Mongoid refactorings?
            inverse = metadata.inverse_of || collection_name
            return parent.respond_to?(inverse) ? parent.send(inverse) : self
          end
          if embedded?
            parent_metadata = reflect_on_all_associations(:embedded_in)[0]
            return model._parent.send(parent_metadata.inverse_of || model.metadata.name)
          end
        end
        deepest_document_superclass
      end

      def deepest_document_superclass
        appropriate_class = self
        while appropriate_class.superclass.include?(Mongoid::Document)
          appropriate_class = appropriate_class.superclass
        end
        appropriate_class
      end
    end

    # Builds a new slug.
    #
    # @return [true]
    def build_slug
      write_attribute slug_name, find_unique_slug

      # @note Why can't I use `read_attribute (slug_history_name)` here?
      if slug_history_name && slug_was && slug_changed?
        self.send(slug_history_name).<<(slug_was).uniq!
      end

      true
    end

    # Finds a unique slug, were specified string used to generate a slug.
    #
    # Returned slug will the same as the specified string when there are no
    # duplicates.
    #
    # @param [String] Desired slug
    # @return [String] A unique slug
    def find_unique_slug_for(desired_slug)
      self.class.find_unique_slug_for desired_slug, :model => self
    end

    # @return [Boolean] Whether the slug requires to be rebuilt
    def slug_should_be_rebuilt?
      new_record? or slug_changed? or slugged_attributes_changed?
    end

    def slugged_attributes_changed?
      slugged_attributes.any? { |f| attribute_changed? f.to_s }
    end

    # @return [String] A string which Action Pack uses for constructing an URL
    # to this record.
    def to_param
      unless slug
        build_slug
        save
      end

      slug
    end

    private

    def find_unique_slug
      find_unique_slug_for user_defined_slug || slug_builder.call(self)
    end

    def user_defined_slug
      slug if (new_record? and slug.present?) or (persisted? and slug_changed?)
    end
  end
end
