class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  slug  :title
  embeds_many :subjects
  references_many :authors
end
