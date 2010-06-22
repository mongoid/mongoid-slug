class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  field :authors
  slug :title
end
