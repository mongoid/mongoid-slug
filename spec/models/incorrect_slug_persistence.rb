class IncorrectSlugPersistence
 include Mongoid::Document
 include Mongoid::Slug

 field :name
 slug  :name, history: true

 validates_length_of :name, :minimum => 4, :maximum => 5, :allow_blank => true
end
