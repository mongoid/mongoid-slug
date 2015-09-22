class Friend
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  field :slug_history, type: Array
  slug :name, reserve: ['foo', 'bar', /^[a-z]{2}$/i], history: true
end
