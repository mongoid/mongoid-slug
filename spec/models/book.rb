class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  field :slug_history
  slug  :title, :index => true, :history => true
  embeds_many :subjects
  has_many :authors
end

class ComicBook < Book
end
