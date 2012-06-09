class Animal
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  field :nickname

  def composite_key
    name + nickname
  end

  field :_id, type: String, default: ->{ composite_key }

  slug  :name
end
