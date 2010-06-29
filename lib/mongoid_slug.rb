# Generates a URL slug/permalink based on fields in a Mongoid model.
module Mongoid::Slug
  
  def self.included(base) #:nodoc:
    base.extend ClassMethods
    base.class_eval { field :slug; before_save :slugify }
  end

  module ClassMethods #:nodoc:

    # Set a field or a number of fields as source of slug
    def slug(*fields)
      class_variable_set(:@@slugged, fields)
    end

    def find_by_slug(slug)
      if embedded?
        raise 'I have not implemented this method yet for embedded docs. Try: parent.children.where(:slug => "foo") instead'
      else
        where(:slug => slug).first
      end
    end
  end

  def to_param
    slug
  end

  private

  def slugify
    self.slug = find_unique_slug if new_record? || slugged_changed?
  end

  def slugged_changed?
    self.class.class_eval('@@slugged').any? do |field|
      self.send(field.to_s + '_changed?')
    end
  end

  def find_unique_slug(suffix='')
    slug = ("#{slug_base} #{suffix}").parameterize
    if (embedded? ? _parent.collection.find("#{self.class.to_s.downcase.pluralize}.slug" => slug) : collection.find(:slug => slug)).
      to_a.reject{ |doc| doc.id == self.id }.count == 0
      slug
    else
      new_suffix = suffix.blank? ? '1' : "#{suffix.to_i + 1}"
      find_unique_slug(new_suffix)
    end
  end

  def slug_base
    self.class.class_eval('@@slugged').collect{ |field| self.send(field) }.join(" ")
  end
end
