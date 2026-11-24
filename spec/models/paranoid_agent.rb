# frozen_string_literal: true

return unless defined?(Mongoid::Paranoia)

class ParanoidAgent
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Slug
  include Mongoid::Slug::Paranoia

  field :name
  slug :name, permanent: true
end
