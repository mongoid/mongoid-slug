# Generates a URL slug/permalink based on fields in a Mongoid model.
module Mongoid::Slug
  extend ActiveSupport::Concern

  included do
    cattr_accessor :slugged
  end

  module ClassMethods #:nodoc:
    # Set a field or a number of fields as source of slug
    def slug(*fields)
      self.slugged = fields
      field :slug; index :slug, :unique => true; before_save :slugify
    end

    # This returns an array containing the match rather than
    # the match itself.
    #
    # http://groups.google.com/group/mongoid/browse_thread/thread/5905589e108d7cc0
    def find_by_slug(slug)
      where(:slug => slug).limit(1)
    end
  end

  def to_param
    slug
  end

  private

  def slugify
    if new_record? || slugged_changed?
      self.slug = find_unique_slug
    end
  end

  def slugged_changed?
    self.class.slugged.any? do |field|
      self.send(field.to_s + '_changed?')
    end
  end

  def find_unique_slug(suffix='')
    slug = ("#{slug_base} #{suffix}").parameterize

    if (embedded? ?
        _parent.collection.find("#{association_name}.slug" => slug) :
        collection.find(:slug => slug)
      ).reject{ |doc| doc.id == self.id }.empty?
      slug
    else
      new_suffix = suffix.blank? ? '1' : "#{suffix.to_i + 1}"
      find_unique_slug(new_suffix)
    end
  end

  def slug_base
    self.class.slugged.collect{ |field| self.send(field) }.join(" ")
  end
end
