# frozen_string_literal: true

class NoIndex
  include Mongoid::Document
  include Mongoid::Slug
  field :title

  slug :title, index: false
end
