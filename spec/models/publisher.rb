class Publisher
  include Mongoid::Document
  include Mongoid::Slug
  field :login
  field :name
  slug  :login, :name do |doc|
    [doc.title, doc.brief].reject(&:blank?).first
  end
end