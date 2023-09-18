# frozen_string_literal: true

Mongoid::Slug.use_paranoia = true
class SecretAgent
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia

  field :name
  slug :name, permanent: true
end
Mongoid::Slug.use_paranoia = false
