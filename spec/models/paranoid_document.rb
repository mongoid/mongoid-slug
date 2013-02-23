class ParanoidDocument
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Slug

  field :title
  slug  :title
end
