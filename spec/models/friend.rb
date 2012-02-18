class Friend
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name, :reserve => ['foo', 'bar']
end
