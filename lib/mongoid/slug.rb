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
      cattr_accessor :slug_name, :slugged_fields, :slug_scope
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
      # Alternatively, this method can be given a block that builds a custom
      # slug.
      #
      # The block takes a single argument, the document itself.
        options = fields.extract_options!

        self.slug_name  = options[:as] || :slug
        self.slug_scope = options[:scope]

        class_eval <<-CODE
          def slug_any?
            #{!!options[:any]}
          end
        CODE

        if block_given?
        else
          self.slugged_fields = fields
        end


        field slug_name

        if options[:index]
          index slug_name, :unique => !slug_scope
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
      self.send(:generate_slug!)
      save if self.send("#{slug_name}_changed?")
    end

    def to_param
      self.send(slug_name)
    end

    private

    attr_reader :slug_counter

    def build_slug
      ("#{slug_base} #{slug_counter}").to_url
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
      self.send("#{slug_name}=", find_unique_slug)
    end

    # def generate_slug
    #   generate_slug! if new_record? || slugged_fields_changed?
    # end

    def increment_slug_counter
      @slug_counter = (slug_counter.to_i + 1).to_s
    end

    def slug_base
      values = self.slugged_fields.map do |field|
        self.send(field)
      end

      if slug_any?
        values.detect { |value| value.present? }
      else
        values.join(' ')
      end
    end

    def slugged_fields_changed?
      self.slugged_fields.any? do |field|
        self.send("#{field}_changed?")
      end
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
