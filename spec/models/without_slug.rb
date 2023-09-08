# frozen_string_literal: true

class WithoutSlug
  include Mongoid::Document

  field :_id, type: Integer
end
