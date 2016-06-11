class Author
  include Mongoid::Document
  include Mongoid::Slug
  field :first_name
  field :last_name
  slug :first_name, :last_name, scope: :book, history: false, max_length: 256
  if Mongoid::Compatibility::Version.mongoid6?
    belongs_to :book, required: false
  else
    belongs_to :book
  end
  has_many :characters,
           class_name: 'Person',
           foreign_key: :author_id
end
