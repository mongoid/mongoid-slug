require 'mongoid'
require 'stringex'

module Mongoid #:nodoc:

  # The slug module helps you generate a URL slug or permalink based on
  # one or more fields in a Mongoid model.
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
      cattr_accessor :slug_builder,
                     :slugged_fields,
                     :slug_name,
                     :slug_history_name,
                     :slug_scope,
                     :slug_reserve
    end

    module ClassMethods

      # Sets one ore more fields as source of slug.
      #
      # Takes a list of fields to slug and an optional options hash.
      #
      # The options hash respects the following members:
      #
      # * `:as`, which specifies name of the field that stores the
      # slug. Defaults to `slug`.
      #
      # * `:scope`, which specifies a reference association or field to 
      # scope the slug by. Embedded documents are by default scoped by 
      # their parent.
      #
      # * `:reserve`, which specifiees an array of reserved slugs.
      # Defaults to [], the empty array.
      # 
      # * `:permanent`, which specifies whether the slug should be
      # immutable once created. Defaults to `false`.
      #
      # * `:history`, which specifies whether a history of used slugs
      # should be kept. The document will be returned for each of these
      # slugs, and slugs present in any document's history cannot be used
      # as a slug for another document. Within a scope, slugs saved
      # in a document's history can be reused by another document.
      #
      # * `:index`, which specifies whether an index should be defined
      # for the slug. Defaults to `false` and has no effect if the
      # document is embedded. Make sure you have a unique index on the
      # slug of root documents to avoid the (very unlikely) race
      # condition that would ensue if two documents with identical
      # slugs were to be saved simultaneously.
      #
      # Alternatively, this method can be given a block to build a
      # custom slug out of the specified fields.
      #
      # The block takes a single argument, the document itself, and
      # should return a string that will serve as the base of the slug.
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
        options           = fields.extract_options!
        options[:history] = false if options[:permanent]

        self.slug_scope         = options[:scope]
        self.slug_reserve       = options[:reserve] || []
        self.slug_name          = options[:as] || :slug
        self.slug_history_name  = "#{self.slug_name}_history".to_sym if options[:history]
        self.slugged_fields     = fields.map(&:to_s)

        self.slug_builder =
          if block_given?
            block
          else
            lambda do |doc|
              slugged_fields.map { |f| doc.send(f) }.
                             join(' ')
            end
          end

        field slug_name

        if slug_history_name
          field slug_history_name, :type => Array
        end

        if options[:index]
          index(slug_name, :unique => !slug_scope)
          if slug_history_name
            index slug_history_name
          end
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
            if slug_history_name
              any_of({ slug_name => slug }, { slug_history_name => slug })
            else
              where(slug_name => slug)
            end.first
          end

          def self.find_by_#{slug_name}!(slug)
            self.find_by_#{slug_name}(slug) ||
              raise(Mongoid::Errors::DocumentNotFound.new(self, slug))
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
      
      # Returns the unique slug that would be used, were this string to be
      # used to generate the slug.
      # 
      # Takes a string and an optional hash of options
      # 
      # The options hash respects the following members:
      # 
      # * `:scope`, which specifies the scope that should be used to generate
      # the slug, if the class creates scoped slugs. Defaults to `nil`.
      # * `:model`, which specifies the model that the slug should be 
      # generated for. This option overrides `:scope` as the scope can now 
      # be extracted from the model. Defaults to `nil`.
      def unique_slug_for(slug_to_be, options = {})
        if slug_scope && self.reflect_on_association(slug_scope).nil?
          scope_object    = uniqueness_scope(options[:model])
          scope_attribute = options[:scope] || options[:model].try(:read_attribute, slug_scope)
        else
          scope_object = options[:scope] || uniqueness_scope(options[:model])
          scope_attribute = nil
        end
        
        excluded_id = options[:model]._id if options[:model]
        
        slug = slug_to_be.to_url
        
        # Regular expression that matches slug, slug-1, ... slug-n
        # If slug_name field was indexed, MongoDB will utilize that
        # index to match /^.../ pattern.
        pattern = /^#{Regexp.escape(slug)}(?:-(\d+))?$/

        if slug_scope &&
           self.reflect_on_association(slug_scope).nil?
          # scope is not an association, so it's scoped to a local field
          # (e.g. an association id in a denormalized db design)

          where_hash = {}
          where_hash[slug_name]   = pattern
          where_hash[:_id.ne]     = excluded_id if excluded_id
          where_hash[slug_scope]  = scope_attribute

          existing_slugs =
            deepest_document_superclass.
            only(slug_name).
            where(where_hash)
        else
          where_hash = {}
          where_hash[slug_name]   = pattern
          where_hash[:_id.ne]     = excluded_id if excluded_id

          existing_slugs =
            scope_object.
            only(slug_name).
            where(where_hash)
        end    

        existing_slugs = existing_slugs.map do |doc|
          doc.read_attribute(slug_name)
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

        existing_slugs << slug if slug_reserve.any? { |reserved| reserved === slug }

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

    # Returns the slug.
    def to_param
      read_attribute(slug_name) || begin
        generate_slug!
        save
        read_attribute(slug_name)
      end
    end
    
    # Returns the unique slug that would be used, were this string to be
    # used to generate the slug.
    def unique_slug_for(slug_to_be)
      self.class.unique_slug_for(slug_to_be, :model => self)
    end

    private

    def find_unique_slug
      # TODO: An epic method which calls for refactoring.

      # Generate a slug only if the slug was not set or changed manually.
      if (new_record? && read_attribute(slug_name).present?) ||
         (!new_record? && slug_field_changed?)
        slug_to_be = read_attribute(slug_name)
      else
        slug_to_be = slug_builder.call(self)
      end

      unique_slug_for(slug_to_be)
    end

    def generate_slug
      if new_record? || slug_field_changed? || slugged_fields_changed?
        generate_slug!
      end
    end

    def generate_slug!
      old_slug = read_attribute(slug_name)
      
      new_slug = find_unique_slug
      write_attribute(slug_name, new_slug)
      
      if slug_history_name && old_slug != nil && new_slug != old_slug
        history_slugs = read_attribute(slug_history_name) || []
        history_slugs << old_slug
        write_attribute(slug_history_name, history_slugs)
      end
    end

    def slug_field_changed?
      attribute_changed?(slug_name)
    end

    def slugged_fields_changed?
      slugged_fields.any? { |f| attribute_changed?(f) }
    end
  end
end
