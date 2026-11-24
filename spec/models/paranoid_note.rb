# frozen_string_literal: true

return unless defined?(Mongoid::Paranoia)

# A paranoid model that does not include Mongoid::Slug::Paranoia and keeps the slugs of soft-deleted documents.
class ParanoidNote
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Slug

  field :title
  slug :title
end
