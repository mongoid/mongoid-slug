require 'stringex'

module Mongoid #:nodoc:

  # Generates a URL slug or permalink based on one or more fields in a Mongoid
  # model.
  module Slug
    extend ActiveSupport::Concern

    included do
      cattr_accessor :slug_name, :slugged_fields, :slug_scope, :first_valid
    end

    module ClassMethods

      # Sets one ore more fields as source of slug.
      #
      # By default, the name of the field that stores the slug is "slug". Pass an
      # alternative name with the :as option.
      #
      # If you wish the slug to be permanent once created, set :permanent to true.
      #
      # To index slug in a top-level object, set :index to true.
      def slug(*fields)
        options = fields.extract_options!

        self.slug_name      = options[:as] || :slug
        self.slug_scope     = options[:scope] || nil
        self.first_valid    = options[:first_valid] || false
        self.slugged_fields = fields

        if options[:scoped]
          ActiveSupport::Deprecation.warn <<-EOM

            The :scoped => true option is deprecated and now default for embedded
            child documents. Please use :scope => :association_name if you wish
            to scope by a reference association.
          EOM
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

        instance_eval <<-CODE
          def self.find_by_#{slug_name}(slug)
            where(slug_name => slug).first rescue nil
          end
          
          def self.find_by_#{slug_name}_or_id(value)
            result = find_by_#{slug_name}(value)
            result = find(value) unless result

            result
          end
        CODE
      end
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
      if new_record? || slugged_fields_changed?
        self.send("#{slug_name}=", find_unique_slug)
      end
    end

    def increment_slug_counter
      @slug_counter = (slug_counter.to_i + 1).to_s
    end

    def slug_base
      slug_field_values = self.class.slugged_fields.map do |field|
        self.send(field)
      end
      if first_valid
        slug_field_values.detect {|v| v.present? }
      else
        slug_field_values.join(" ")
      end
    end

    def slugged_fields_changed?
      self.class.slugged_fields.any? do |field|
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
        metadata = reflect_on_all_associations(:embedded_in).first
        _parent.send(metadata.inverse_of)
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
