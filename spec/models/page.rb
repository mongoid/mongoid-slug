class Page
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  field :content
  field :order, type: Integer
  slug :title
  default_scope -> { asc(:order) }
end
