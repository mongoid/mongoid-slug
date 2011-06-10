module Rails #:nodoc:
  module Mongoid #:nodoc:
    module Slug #:nodoc:
      class Railtie < Rails::Railtie #:nodoc:
        rake_tasks do
          load 'mongoid/slug/railties/database.rake'
        end
      end
    end
  end
end
