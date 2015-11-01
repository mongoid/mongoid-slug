class Artist
  include Mongoid::Document
  include Mongoid::Slug

  slug :name
  field :name
  has_and_belongs_to_many :artworks
end
