class DocumentParanoid
  include Mongoid::Document
  # slug, then paranoia
  include Mongoid::Slug
  include Mongoid::Paranoia

  field :title
  slug :title
end
