class Sar
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name, :scoped => true
  embedded_in :foo, :inverse_of => :bars
end
