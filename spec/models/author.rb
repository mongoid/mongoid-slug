# frozen_string_literal: true

class Author
  include Mongoid::Document
  include Mongoid::Slug
  field :first_name
  field :last_name
  belongs_to :book, required: false
  has_many :characters,
           class_name: 'Person',
           foreign_key: :author_id
  slug :first_name, :last_name, scope: :book, history: false, max_length: 256
end
