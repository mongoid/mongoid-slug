module Mongoid
  module Slug

    # Lightweight compatibility shim which adds the :restore callback to
    # older versions of Mongoid::Paranoia
    module Paranoia
      extend ActiveSupport::Concern

      included do

        define_model_callbacks :restore

        def restore_with_callbacks
          run_callbacks(:restore) do
            restore_without_callbacks
          end
        end
        alias_method_chain :restore, :callbacks
      end
    end
  end
end
