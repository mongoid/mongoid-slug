class Animal
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  field :nickname
  key :name, :nickname
  slug  :name
end
