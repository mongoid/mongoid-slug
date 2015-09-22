class Magazine
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  field :publisher_id
  slug :title, scope: :publisher_id
end
