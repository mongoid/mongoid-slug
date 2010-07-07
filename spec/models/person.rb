class Person
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name, :as => :permalink
end
