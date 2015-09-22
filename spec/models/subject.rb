class Subject
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug :name, scope: :book, history: true
  embedded_in :book
end
