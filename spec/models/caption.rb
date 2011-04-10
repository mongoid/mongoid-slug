class Caption
  include Mongoid::Document
  include Mongoid::Slug
  field :identity
  field :title
  field :medium

  # A fairly complex scenario, where we want to create a slug out of an
  # identity field, which comprises name of artist and some more bibliographic
  # info in parantheses, and the title of the work.
  #
  # We are only interested in the name of the artist so we remove the
  # paranthesized details.
  slug :identity, :title do |doc|
    [doc.identity.gsub(/\s*\([^)]+\)/, ''), doc.title].join(' ')
  end
end
