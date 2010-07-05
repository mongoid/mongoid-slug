class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  field :isbn
  slug  :title
  embeds_one :publisher
  embeds_many :subjects
  references_many :authors
end
