namespace :mongoid_slug do
  desc 'Goes though all documents and sets slug if not already set'
  task set: :environment do |_, args|
    ::Rails.application.eager_load! if defined?(Rails)
    klasses = Mongoid::Config.models.find_all { |c| c.ancestors.include?(Mongoid::Slug) }
    unless klasses.blank?
      models  = args.extras
      klasses = (klasses.map(&:to_s) & models.map(&:classify)).map(&:constantize) if models.any?
      klasses.each do |klass|
        # set slug for objects having blank slug
        klass.each { |object| object.set_slug! unless object.slugs? && object.slugs.any? }
      end
    end
  end
end
