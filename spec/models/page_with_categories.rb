# frozen_string_literal: true

class PageWithCategories
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  field :content

  field :page_category
  field :page_sub_category

  field :order, type: Integer
  slug :title, scope: %i[page_category page_sub_category]
  default_scope -> { asc(:order) }
end
