# Generates a URL slug/permalink based on fields in a Mongoid model.
module Mongoid::Slug
  extend ActiveSupport::Concern

  included do
    cattr_accessor :slug_name, :slugged_fields
  end

  module ClassMethods #:nodoc:
    # Set a field or a number of fields as source of slug
    def slug(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      self.slug_name = options[:as] || :slug
      self.slugged_fields = args

      field slug_name
      index slug_name, :unique => true
      before_save :generate_slug
    end
  end

  def to_param
    self.send slug_name
  end

  private

  def duplicate_of(slug, association_chain=[])
    if embedded?
      association_chain << association_name
      _parent.send :duplicate_of, slug, association_chain
    else
      association_chain.reverse! << "slug"
      collection.find(association_chain.join(".") => slug)
    end
  end

  def find_unique_slug(suffix='')
    slug = ("#{slug_base} #{suffix}").parameterize

    if duplicate_of(slug).reject{ |doc| doc.id == self.id }.empty?
      slug
    else
      suffix = suffix.blank? ? '1' : "#{suffix.to_i + 1}"
      find_unique_slug(suffix)
    end
  end

  def generate_slug
    if new_record? || slugged_fields_changed?
      self.send("#{slug_name}=", find_unique_slug)
    end
  end

  def slug_base
    self.class.slugged_fields.collect{ |field| self.send(field) }.join(" ")
  end

  def slugged_fields_changed?
    self.class.slugged_fields.any? do |field|
      self.send(field.to_s + '_changed?')
    end
  end
end
