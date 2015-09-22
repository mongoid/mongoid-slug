class IntegerId
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: Integer
  field :name, type: String

  slug :name, history: true
end
