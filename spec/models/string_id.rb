class StringId
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: String
  field :name, type: String

  slug :name, history: true
end
