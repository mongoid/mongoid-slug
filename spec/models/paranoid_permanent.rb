class ParanoidPermanent
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Slug

  field :title
  slug  :title, permanent: true
end
