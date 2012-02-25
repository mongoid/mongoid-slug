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
      # * `:scope`, which specifies a reference association to scope
      # the slug by. Embedded documents are by default scoped by their
      # parent.
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
    end

    # Returns the slug.
    def to_param
      read_attribute(slug_name) || begin
        generate_slug!
        save
        read_attribute(slug_name)
      end
    end

    private

    def find_unique_slug
      # TODO: An epic method which calls for refactoring.
      slug = slug_builder.call(self).to_url

      # Regular expression that matches slug, slug-1, ... slug-n
      # If slug_name field was indexed, MongoDB will utilize that
      # index to match /^.../ pattern.
      pattern = /^#{Regexp.escape(slug)}(?:-(\d+))?$/

      if slug_scope &&
         self.class.reflect_on_association(slug_scope).nil?
        # scope is not an association, so it's scoped to a local field
        # (e.g. an association id in a denormalized db design)
        existing_slugs =
          self.class.
          only(slug_name).
          where(slug_name  => pattern,
                :_id.ne    => _id,
                slug_scope => self[slug_scope])
      else
        existing_slugs =
          uniqueness_scope.
          only(slug_name).
          where(slug_name => pattern, :_id.ne => _id)
      end    

      existing_slugs = existing_slugs.map do |obj|
        obj.read_attribute(slug_name)
      end
      
      if slug_history_name
        if slug_scope &&
           self.class.reflect_on_association(slug_scope).nil?
          # scope is not an association, so it's scoped to a local field
          # (e.g. an association id in a denormalized db design)
          history_slugged_documents =
            self.class.
            where(slug_history_name.all => [pattern],
                  :_id.ne    => _id,
                  slug_scope => self[slug_scope])
        else
          history_slugged_documents =
            uniqueness_scope.
            where(slug_history_name.all => [pattern], 
                  :_id.ne => _id)
        end

        existing_history_slugs = []
        history_slugged_documents.each do |obj|
          history_slugs = obj.read_attribute(slug_history_name)
          next if history_slugs.nil?
          existing_history_slugs.push(*history_slugs.find_all { |slug| slug =~ pattern })
        end
        
        # if the only conflict is in the history of a document in the same scope,
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

    def generate_slug
      # Generate a slug for new records only if the slug was not set.
      # If we're not a new record generate a slug if our slugged fields
      # changed on us.
      if (new_record? && !read_attribute(slug_name)) ||
         (!new_record? && slugged_fields_changed?)
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

    def slugged_fields_changed?
      slugged_fields.any? { |f| attribute_changed?(f) }
    end

    def uniqueness_scope
      if slug_scope
        metadata = self.class.reflect_on_association(slug_scope)
        parent = self.send(metadata.name)

        # Make sure doc is actually associated with something, and that
        # some referenced docs have been persisted to the parent
        #
        # TODO: we need better reflection for reference associations,
        # like association_name instead of forcing collection_name here
        # -- maybe in the forthcoming Mongoid refactorings?
        inverse = metadata.inverse_of || collection_name
        parent.respond_to?(inverse) ? parent.send(inverse) : self.class
      elsif embedded?
        parent_metadata = reflect_on_all_associations(:embedded_in)[0]
        _parent.send(parent_metadata.inverse_of || self.metadata.name)
      else
        appropriate_class = self.class
        while appropriate_class.superclass.include?(Mongoid::Document)
          appropriate_class = appropriate_class.superclass
        end
        appropriate_class
      end
    end
  end
end
