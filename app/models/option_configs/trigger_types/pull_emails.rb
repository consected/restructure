# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the pull_emails save trigger.
    # Direct-config pattern: top-level keys configure email retrieval, after-processing,
    # and per-email trigger lists (on_email, on_email_complete, on_email_failure).
    class PullEmails < Base
      trigger_name :pull_emails
      pattern :direct_config
      allowed_keys %i[
        source attachments limit after_processing
        on_email on_email_complete on_email_failure
        if on_complete on_failure
      ]
      standard_hook_key_types
      key_type :hash, :source, :after_processing
      # attachments values are resolved via FieldDefaults.substitute_value_recurse
      # (see SaveTriggers::PullEmails#resolved_attachments) before use, so store_as_user/
      # store_in_app_type may be a literal id/name or a conditional Hash reference.
      key_type :hash, :attachments,
               allowed_keys: %i[if container path store_as_user store_in_app_type skip_existing replace],
               key_types: { if: :hash, container: :hash, path: :string_or_hash,
                            store_as_user: :string_or_integer_or_hash, store_in_app_type: :string_or_integer_or_hash,
                            skip_existing: :boolean, replace: :boolean }
      key_type :integer, :limit
      key_type :hash_or_array, :on_email, :on_email_complete, :on_email_failure
    end
  end
end
