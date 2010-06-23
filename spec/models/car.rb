class Car
  include Mongoid::Document
  include Mongoid::Slug
  field :model
  slug  :model
  embedded_in :person, :inverse_of => :cars
end
