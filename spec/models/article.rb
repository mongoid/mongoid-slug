class Article
  include Mongoid::Document
  include Mongoid::Slug
  field :brief
  field :title
  slug  :title, :brief, :any => true
end
