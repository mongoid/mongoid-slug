# frozen_string_literal: true

class Agent
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia

  field :name
  slug :name, permanent: true
end
