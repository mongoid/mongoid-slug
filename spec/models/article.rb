class Article
  include Mongoid::Document
  include Mongoid::Slug
  field :brief
  field :title
  slug  do |doc|
    [:title, :brief].map { |f| doc.send(f) }.reject(&:blank?).first
  end
end
