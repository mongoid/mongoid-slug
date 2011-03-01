class Caption
  include Mongoid::Document
  include Mongoid::Slug
  field :identity
  field :title
  field :medium
  slug lambda { |doc|
    [doc.identity.gsub(/\s*\([^)]+\)/, ''), doc.title].join(' ')
  }
end
