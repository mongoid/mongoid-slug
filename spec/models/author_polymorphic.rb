class AuthorPolymorphic
  include Mongoid::Document
  include Mongoid::Slug
  field :first_name
  field :last_name
  slug  :first_name, :last_name, :scope => :book_polymorphic
  belongs_to :book_polymorphic
  has_many :characters,
           :class_name => 'Person',
           :foreign_key => :author_id
end
