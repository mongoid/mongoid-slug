class Entity
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Slug::UuidIdCheck

  field :_id, type: String

  field :name
  field :user_edited_variation

  slug  :user_edited_variation, :history => true
end
