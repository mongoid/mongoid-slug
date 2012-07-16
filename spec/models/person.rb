class Person
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name, :permanent => true, :scope => :author
  embeds_many :relationships
  belongs_to :author, :inverse_of => :characters
end
