# Generates a URL slug/permalink based on fields in a Mongoid model.
module Mongoid::Slug
  extend ActiveSupport::Concern

  included do
    cattr_accessor :slug_name, :slugged_fields, :slug_scoped
  end

  module ClassMethods #:nodoc:
    # Set a field or a number of fields as source of slug
    def slug(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      self.slug_name = options[:as] || :slug
      self.slug_scoped = options[:scoped] || false
      self.slugged_fields = args

      field slug_name
      if slug_scoped
        index slug_name
      else
        index slug_name, :unique => true
      end
      before_save :generate_slug
    end
  end

  def to_param
    self.send slug_name
  end

  private

  def find_(slug, stack=[])
    if embedded?
      if slug_scoped && stack.empty?
        _parent.send(association_name).where( slug_name => slug ).to_a
      else
        stack << association_name
        _parent.send :find_, slug, stack
      end
    else
      stack.reverse!
      path = (stack + [slug_name]).join(".")
      found = collection.find(path => slug).to_a
    
      stack.each do |name|
        if found.any?
          found = found.first.send(name).to_a
        end
      end
    
      found
    end
  end

  def find_unique_slug(suffix='')
    slug = ("#{slug_base} #{suffix}").parameterize
    if find_(slug).reject{ |doc| doc.id == self.id }.empty?
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
