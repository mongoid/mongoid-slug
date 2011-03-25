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
      # Takes a list of one or more fields to slug and an optional options
      # hash.
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
      # bedded.
      #
      # Alternatively, this method can be given a block to build a custom slug
      # out of the specified fields.
      #
      # The block takes a single argument, the document itself, and should
      # return a string that will serve as the base of the slug. Make sure you
      # build the slug only using the specified fields.
      #
      # Here, for instance, we slug an array field.
      #
      #     slug :creators do |doc|
      #       doc.creators.join(' ')
      #     end
      #
      def slug(*fields, &block)
        options = fields.extract_options!
        self.slug_scope = options[:scope]
        self.slug_name = options[:as] || :slug
        self.slugged_fields = fields

        self.slug_builder =
          if block_given?
            block
          else
            lambda do |doc|
              slugged_fields.map { |f| doc.send(f) }.join(',')
            end
          end

        field slug_name

        if options[:index]

          # Indices on scoped documents are not unique. All others are.
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
      self.send(slug_name)
    end

    private

    def build_slug
      ("#{slug_builder.call(self)} #{@slug_counter}").to_url
    end

    def find_unique_slug
      slug = build_slug
      if unique_slug?(slug)
        slug
      else
        increment_slug_counter
        find_unique_slug
      end
    end

    def generate_slug
      if new_record? || slugged_fields_changed?
        generate_slug!
      end
    end

    def generate_slug!
      self.send("#{slug_name}=", find_unique_slug)
    end

    def increment_slug_counter
      @slug_counter = (@slug_counter.to_i + 1).to_s
    end

    def slugged_fields_changed?
      slugged_fields.any? { |f| self.send("#{f}_changed?") }
    end

    def unique_slug?(slug)
      uniqueness_scope.where(slug_name => slug).
        reject { |doc| doc.id == self.id }.
        empty?
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
