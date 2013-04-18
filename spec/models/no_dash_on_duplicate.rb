class NoDashOnDuplicate
	include Mongoid::Document
  include Mongoid::Slug
  field :title

	slug  :title, history: true, no_dash: true
end