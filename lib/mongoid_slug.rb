# Generates a URL slug/permalink based on a field in a Mongoid model.
module Mongoid::Slug
  
  def self.included(base)
    base.extend ClassMethods
    base.class_eval { field :slug; before_save :slugify }
  end

  module ClassMethods #:nodoc:

    # Set a field as source of slug
    def slug(*field)
      class_variable_set(:@@slugged_fields, field)
    end

    def find_by_slug(slug)
      where(:slug => slug).first
    end
  end

  def to_param
    slug
  end

  private

  def slugify
    self.slug = find_unique_slug if new_record? || slugged_fields_changed?
  end

  def slugged_fields_changed?
    self.class.class_eval('@@slugged_fields').any? do |field|
      self.send(field.to_s + '_changed?')
    end
  end

  def find_unique_slug(suffix='')
    slug = ("#{slug_base} #{suffix}").parameterize
    if (embedded? ? self._parent.collection.find("#{self.class.to_s.downcase.pluralize}.slug" => slug) : collection.find(:slug => slug)).count == 0
      slug
    else
      new_suffix = suffix.blank? ? '1' : "#{suffix.to_i + 1}"
      find_unique_slug(new_suffix)
    end
  end

  def slug_base
    self.class.class_eval('@@slugged_fields').collect{ |field| self.send(field) }.join(" ")
  end
end
