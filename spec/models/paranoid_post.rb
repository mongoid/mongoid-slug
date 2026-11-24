# frozen_string_literal: true

return unless defined?(Mongoid::Paranoia)

class ParanoidPost
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Slug
  include Mongoid::Slug::Paranoia

  field :title
  slug :title
end
