class Foo
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  slug  :name
  embeds_many :bars
  embeds_many :sars
end
