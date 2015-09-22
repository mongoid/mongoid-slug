class Relationship
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug :name
  embeds_many :partners
  embedded_in :person
end
