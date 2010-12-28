class Person
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name, :as => :permalink, :permanent => true
  embeds_many :relationships
end
