class Bar
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name
  embeds_many :bazes, :class_name => "Baz"
  embedded_in :foo, :inverse_of => :bars
end
