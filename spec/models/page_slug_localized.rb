class PageSlugLocalized
  include Mongoid::Document
  include Mongoid::Slug
  field :title, localize: true
  field :content
  field :order, :type => Integer
  slug  :title, localize: true
  default_scope ->{ asc(:order) }
end
