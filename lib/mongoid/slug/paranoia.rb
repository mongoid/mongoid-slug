module Mongoid
  module Slug
    # Lightweight compatibility shim which adds the :restore callback to
    # older versions of Mongoid::Paranoia
    module Paranoia
      extend ActiveSupport::Concern

      def restore
        run_callbacks(:restore) do
          super
        end
      end

      included do
        define_model_callbacks :restore
        self.class.prepend(Mongoid::Slug::Paranoia)
      end
    end
  end
end
