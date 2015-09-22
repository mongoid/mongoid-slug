class Alias
  include Mongoid::Document
  include Mongoid::Slug
  field :name, as: :author_name
  slug :author_name
end
