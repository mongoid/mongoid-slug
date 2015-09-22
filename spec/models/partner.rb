class Partner
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug :name
  embedded_in :relationship
end
