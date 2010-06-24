class Publisher
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  field :year, :type => Integer
  field :place
  slug  :name
  embedded_in :book, :inverse_of => :publisher
end
