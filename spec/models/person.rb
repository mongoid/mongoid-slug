class Person
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  field :age, :type => Integer
  slug  :name, :as => :permalink
end
