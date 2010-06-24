class Author
  include Mongoid::Document
  include Mongoid::Slug
  field :first_name
  field :last_name
  slug  :first_name, :last_name
end
