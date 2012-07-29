module Mongoid
  # Slugs your Mongoid model.
  module Slug
    extend ActiveSupport::Concern

    included do
      cattr_accessor :reserved_words,
                     :slug_builder,
                     :slug_scope,
                     :slugged_attributes

      field :_slugs, type: Array, default: []
      alias_attribute :slugs, :_slugs
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

        self.slug_scope         = options[:scope]
        self.reserved_words     = options[:reserve] || Set.new([:new, :edit])
        self.slugged_attributes = fields.map &:to_s

        if slug_scope
          index({slug_scope: 1, _slugs: 1}, {unique: true})
        else
          index({_slugs: 1}, {unique: true})
        end

        #-- Why is it necessary to customize the slug builder?
        default_builder = lambda do |doc|
          slugged_attributes.map { |f| doc.send f }.join ' '
        end

        self.slug_builder = block_given? ? block : default_builder

        #-- a slug can be permanent or not
        set_callback options[:permanent] ? :create : :save, :before do |doc|
          doc.build_slug if doc.slug_should_be_rebuilt?
        end

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

        _slug = desired_slug.to_url

        # Regular expression that matches slug, slug-1, ... slug-n
        # If slug_name field was indexed, MongoDB will utilize that
        # index to match /^.../ pattern.
        pattern = /^#{Regexp.escape(_slug)}(?:-(\d+))?$/

        if slug_scope &&
           self.reflect_on_association(slug_scope).nil?
          # scope is not an association, so it's scoped to a local field
          # (e.g. an association id in a denormalized db design)

          where_hash = {}
          where_hash[:_slugs.all] = [pattern]
          where_hash[:_id.ne]               = excluded_id if excluded_id
          where_hash[slug_scope]            = scope_attribute

          history_slugged_documents =
            deepest_document_superclass.
            where(where_hash)
        else
          where_hash = {}
          where_hash[:_slugs.all] = [pattern]
          where_hash[:_id.ne]               = excluded_id if excluded_id

          history_slugged_documents =
            scope_object.
            where(where_hash)
        end

        existing_slugs = []
        existing_history_slugs = []
        last_entered_slug = []
        history_slugged_documents.each do |doc|
          history_slugs = doc._slugs
          next if history_slugs.nil?
          existing_slugs.push(*history_slugs.find_all { |cur_slug| cur_slug =~ pattern })
          last_entered_slug.push(*history_slugs.last) if history_slugs.last =~ pattern
          existing_history_slugs.push(*history_slugs.first(history_slugs.length() -1).find_all { |cur_slug| cur_slug =~ pattern })
        end

        # If the only conflict is in the history of a document in the same scope,
        # transfer the slug
        if slug_scope && last_entered_slug.count == 0 && existing_history_slugs.count > 0
          history_slugged_documents.each do |doc|
            doc._slugs -= existing_history_slugs
            doc.save
          end
          existing_slugs = []
        end

        # Do not allow Moped::BSON::ObjectIds as slugs
        existing_slugs << _slug if Moped::BSON::ObjectId.legal?(_slug)

        if reserved_words.any? { |word| word === _slug }
          existing_slugs << _slug
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

          _slug += "-#{max + 1}"
        end

        _slug
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
      #   Model.find_by_slug('some-slug')
      #
      # @example Find by multiple slugs.
      #   Model.find_by_slug('some-slug', 'some-other-slug')
      #
      # @param [ Array<Object> ] args The slugs to search for.
      #
      # @return [ Array<Document>, Document ] The matching document(s).
      def find_by_slug(*args)
        with_default_scope.find_by_slug(*args)
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
      _new_slug = find_unique_slug
      self._slugs.delete(_new_slug)
      self._slugs << _new_slug

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
      new_record? or _slugs_changed? or slugged_attributes_changed?
    end

    def slugged_attributes_changed?
      slugged_attributes.any? { |f| attribute_changed? f.to_s }
    end

    # @return [String] A string which Action Pack uses for constructing an URL
    # to this record.
    def to_param
      unless _slugs.last
        build_slug
        save
      end

      _slugs.last
    end

    private

    def find_unique_slug
      find_unique_slug_for user_defined_slug || slug_builder.call(self)
    end

    def user_defined_slug
      _slugs.last if (new_record? and _slugs.present?) or (persisted? and _slugs_changed?)
    end
  end
end
