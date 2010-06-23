class Person
  include Mongoid::Document
  embeds_many :cars
  embeds_one  :pet
end
