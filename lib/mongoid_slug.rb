# Generates a URL slug/permalink based on a field in a Mongoid model.
module Mongoid::Slug
  
  def self.included(base)
    base.extend ClassMethods
    base.class_eval { field :slug; before_save :slugify }
  end

  module ClassMethods #:nodoc:
    
    # Set a field as source of slug
    def slug(field)
      class_variable_set(:@@slugged_field, field.to_sym)
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
    self.slug = find_unique_slug if new_record? || self.send((self.class.class_eval('@@slugged_field').to_s + '_changed?').to_sym)
  end

  def find_unique_slug(suffix='')
    slug = ("#{slugged_field} #{suffix}").parameterize
    if collection.find(:slug => slug).count == 0
      slug
    else
      new_suffix = suffix.blank? ? '1' : "#{suffix.to_i + 1}"
      find_unique_slug(new_suffix)
    end
  end

  def slugged_field
    self.send(self.class.class_eval('@@slugged_field'))
  end
end
