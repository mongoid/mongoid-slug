class Pet
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name
  embedded_in :person, :inverse_of => :pet
end
