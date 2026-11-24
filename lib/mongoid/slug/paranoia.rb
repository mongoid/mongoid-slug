# frozen_string_literal: true

module Mongoid
  module Slug
    # Releases the slugs of soft-deleted Mongoid::Paranoia documents, so that other documents can claim them, and
    # builds a unique slug again when a document is restored.
    #
    # Include it in a model that includes Mongoid::Paranoia and Mongoid::Slug:
    #
    #   class Agent
    #     include Mongoid::Document
    #     include Mongoid::Paranoia
    #     include Mongoid::Slug
    #     include Mongoid::Slug::Paranoia
    #
    #     field :name
    #     slug :name
    #   end
    #
    # To enable it for every paranoid model, include it into Mongoid::Paranoia before any model includes
    # Mongoid::Paranoia, for example in an initializer:
    #
    #   Mongoid::Paranoia.include Mongoid::Slug::Paranoia
    module Paranoia
      extend ActiveSupport::Concern

      included do
        # Mongoid::Slug installs these callbacks when slug is called; this covers including the module afterwards.
        define_slug_paranoia_callbacks if respond_to?(:slugged_attributes) && slugged_attributes.present?
      end

      class_methods do
        def define_slug_paranoia_callbacks
          unless defined?(::Mongoid::Paranoia) && include?(::Mongoid::Paranoia)
            raise ArgumentError, "#{name} includes Mongoid::Slug::Paranoia without Mongoid::Paranoia; " \
                                 'include Mongoid::Paranoia before calling slug'
          end

          # Callbacks with the same method name replace each other, so these use dedicated methods rather than
          # adding a second :build_slug save callback, and defining them again is harmless.
          set_callback :destroy, :after, :unset_slug!, if: :slug_paranoid_soft_destroyed?
          set_callback :restore, :before, :set_slug!
          set_callback :save, :before, :remove_paranoid_slug, if: :slug_paranoid_deleted?
          set_callback :save, :before, :rebuild_paranoid_slug, if: :slug_paranoid_undeleted?
        end
        private :define_slug_paranoia_callbacks
      end

      private

      # destroy! hard-deletes and freezes the document, which then has no slug to release.
      def slug_paranoid_soft_destroyed?
        slug_paranoid_deleted? && !frozen?
      end

      # Clearing deleted_at directly instead of calling restore also gives the document a slug again.
      def slug_paranoid_undeleted?
        deleted_at.nil? && !deleted_at_was.nil? && _slugs.blank?
      end

      # Removes the field rather than storing an empty value, so the sparse unique index ignores the document.
      def remove_paranoid_slug
        remove_attribute(:_slugs) if attributes.key?('_slugs')
      end

      def rebuild_paranoid_slug
        build_slug
      end
    end
  end
end
