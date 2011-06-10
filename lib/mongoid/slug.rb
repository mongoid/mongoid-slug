require 'stringex'

module Mongoid #:nodoc:

  # The slug module helps you generate a URL slug or permalink based on one or
  # more fields in a Mongoid model.
  #
  #    class Person
  #      include Mongoid::Document
  #      include Mongoid::Slug
  #
  #      field :name
  #      slug :name
  #    end
  #
  module Slug
    extend ActiveSupport::Concern

    included do
      cattr_accessor :slug_builder, :slugged_fields, :slug_name, :slug_scope
    end

    module ClassMethods

      # Sets one ore more fields as source of slug.
      #
      # Takes a list of fields to slug and an optional options hash.
      #
      # The options hash respects the following members:
      #
      # * `:as`, which specifies name of the field that stores the slug.
      # Defaults to `slug`.
      #
      # * `:scope`, which specifies a reference association to scope the slug
      # by. Embedded documents are by default scoped by their parent.
      #
      # * `:permanent`, which specifies whether the slug should be immutable
      # once created. Defaults to `false`.
      #
      # * `:index`, which specifies whether an index should be defined for the
      # slug. Defaults to `false` and has no effect if the document is em-
      # bedded. Make sure you have a unique index on the slug of root
      # documents to avoid the (very unlikely) race condition that would ensue
      # if two documents with identical slugs were to be saved simultaneously.
      #
      # Alternatively, this method can be given a block to build a custom slug
      # out of the specified fields.
      #
      # The block takes a single argument, the document itself, and should
      # return a string that will serve as the base of the slug.
      #
      # Here, for instance, we slug an array field.
      #
      #     class Person
      #      include Mongoid::Document
      #      include Mongoid::Slug
      #
      #      field :names, :type => Array
      #      slug :names do |doc|
      #        doc.names.join(' ')
      #      end
      #
      def slug(*fields, &block)
        options             = fields.extract_options!
        self.slug_scope     = options[:scope]
        self.slug_name      = options[:as] || :slug
        self.slugged_fields = fields.map(&:to_s)

        self.slug_builder =
          if block_given?
            block
          else
            lambda do |doc|
              slugged_fields.map { |f| doc.read_attribute(f) }.join(' ')
            end
          end

        field slug_name

        if options[:index]
          index(slug_name, :unique => !slug_scope)
        end

        if options[:permanent]
          before_create :generate_slug
        else
          before_save :generate_slug
        end

        # Build a finder based on the slug name.
        #
        # Defaults to `find_by_slug`.
        instance_eval <<-CODE
          def self.find_by_#{slug_name}(slug)
            where(slug_name => slug).first
          end

          def self.find_by_#{slug_name}!(slug)
            where(slug_name => slug).first ||
              raise(Mongoid::Errors::DocumentNotFound.new(self.class, slug))
          end
        CODE
      end
    end

    # Regenerates slug.
    #
    # Should come in handy when generating slugs for an existing collection.
    def slug!
      generate_slug!
      save
    end

    # Returns the slug.
    def to_param
      read_attribute(slug_name)
    end

    private

    def find_unique_slug
      # TODO: An epic method which calls for refactoring.
      slug = slug_builder.call(self).to_url
            
      # Regular expression that matches slug, slug-1, slug-2, ... slug-n
      # If slug_name field was indexed, MongoDB will utilize that index to
      # match /^.../ pattern
      pattern = /^#{Regexp.escape(slug)}(?:-(\d+))?$/
      
      existing_slugs =
        uniqueness_scope.
        only(slug_name).
        where(slug_name => pattern, :_id.ne => _id).
        map {|obj| obj.try(:read_attribute, slug_name)}
      
      if existing_slugs.count > 0      
        # sort the existing_slugs in increasing order by comparing the suffix
        # numbers:
        # slug, slug-1, slug-2, ..., slug-n
        existing_slugs.sort! do |a, b|
          (pattern.match(a)[1] || -1).to_i <=> (pattern.match(b)[1] || -1).to_i
        end
        max_counter = existing_slugs.last.match(/-(\d+)$/).try(:[], 1).to_i

        # Use max_counter + 1 as unique counter
        slug += "-#{max_counter + 1}"
      end
      
      slug
    end

    def generate_slug
      if new_record? || slugged_fields_changed?
        generate_slug!
      end
    end

    def generate_slug!
      write_attribute(slug_name, find_unique_slug)
    end

    def slugged_fields_changed?
      slugged_fields.any? { |f| attribute_changed?(f) }
    end

    def uniqueness_scope
      if slug_scope
        metadata = self.class.reflect_on_association(slug_scope)
        parent = self.send(metadata.name)

        # Make sure doc is actually associated with something, and that some
        # referenced docs have been persisted to the parent
        #
        # TODO: we need better reflection for reference associations, like
        # association_name instead of forcing collection_name here -- maybe
        # in the forthcoming Mongoid refactorings?
        inverse = metadata.inverse_of || collection_name
        parent.respond_to?(inverse) ? parent.send(inverse) : self.class
      elsif embedded?
        parent_metadata = reflect_on_all_associations(:embedded_in).first
        _parent.send(parent_metadata.inverse_of || self.metadata.name)
      else
        appropriate_class = self.class
        while (appropriate_class.superclass.include?(Mongoid::Document))
          appropriate_class = appropriate_class.superclass
        end
        appropriate_class
      end
    end
  end
end
