class Entity
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: String, slug_id_strategy: UuidIdStrategy

  field :name
  field :user_edited_variation

  slug :user_edited_variation, history: true
end
