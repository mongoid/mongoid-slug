class Subject
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name
  embedded_in :book, :inverse_of => :subjects
end
