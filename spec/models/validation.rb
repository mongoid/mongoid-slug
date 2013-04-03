class Validation
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  slug  :title
  validates :slug, presence: true, format: {with: /[-a-z0-9]{2,}/}
end
