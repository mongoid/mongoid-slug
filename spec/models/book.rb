class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title

  slug :title, history: true, max_length: nil
  embeds_many :subjects
  has_many :authors
end

class ComicBook < Book
end
