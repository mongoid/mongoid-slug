class Caption
  include Mongoid::Document
  include Mongoid::Slug
  field :identity
  field :title
  field :medium
  slug :identity, :title do |doc|
    [doc.identity.gsub(/\s*\([^)]+\)/, ''), doc.title].join(' ')
  end
end
