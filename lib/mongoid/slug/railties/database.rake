namespace :slug do
  desc 'Re-calculate slug_size and update to database'
  task :update_slug_size, :model, :needs => :environment do |t, args|
    args[:model].singularize.classify.constantize.update_slug_size
  end
end
