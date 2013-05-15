class Sync
  include Mongoid::Document
  include Mongoid::Slug

  field :username
  slug :username, sync: true
end