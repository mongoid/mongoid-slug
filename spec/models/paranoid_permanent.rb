class ParanoidPermanent
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Slug

  field :title
  field :foo

  slug  :title, scope: :foo, permanent: true
end
