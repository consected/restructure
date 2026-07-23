# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the generate_document save trigger.
    # Named-entry pattern: keys are validated inside each entry config.
    class GenerateDocument < Base
      trigger_name :generate_document
      pattern :named_entry
      allowed_keys %i[
        content_template_name content_template_text layout_template extra_substitutions
        container filename content_type path skip_existing replace
        store_as_user store_in_app_type if on_complete on_failure
      ]
      standard_hook_key_types
      key_type :string_or_hash, :content_template_name, :content_template_text, :layout_template,
               :filename, :content_type, :path, :store_as_user, :store_in_app_type
      key_type :hash, :extra_substitutions, :container
      key_type :boolean, :skip_existing, :replace
    end
  end
end
