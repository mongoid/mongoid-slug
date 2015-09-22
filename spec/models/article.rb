class Article
  include Mongoid::Document
  include Mongoid::Slug
  field :brief
  field :title
  slug :title, :brief do |doc|
    [doc.title, doc.brief].reject(&:blank?).first
  end
end
