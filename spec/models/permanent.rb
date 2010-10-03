class Permanent
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  slug :title, :permanent => true
end