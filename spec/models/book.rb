class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  slug  :title, :index => true, :history => true
  embeds_many :subjects
  references_many :authors
end

class ComicBook < Book
end
