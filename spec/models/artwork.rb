class Artwork
  include Mongoid::Document
  include Mongoid::Slug

  slug :title
  field :title
  field :published, type: Boolean, default: true
  scope :published, -> { where(published: true) }
  has_and_belongs_to_many :artists
end
