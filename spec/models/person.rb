class Person
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name, :as => :permalink, :permanent => true, :scope => :author
  embeds_many :relationships
  referenced_in :author, :inverse_of => :characters
end
