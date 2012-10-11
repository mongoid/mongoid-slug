class Entity
  include Mongoid::Document
  include Mongoid::Slug

  field :_id, type: String

  field :name
  field :user_edited_variation

  slug  :user_edited_variation, :history => true, :reference => :name, :skip_id_check => true, :transfer_historic => false
end
