class PageSlugLocalizedCustom
  include Mongoid::Document
  include Mongoid::Slug

  attr_accessor :title

  slug :title, localize: true do |obj|
    obj.title.to_url
  end
end
