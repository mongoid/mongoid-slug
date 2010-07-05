class Baz
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  field :other
  slug  :name
  embedded_in :bar, :inverse_of => :bazes
end
