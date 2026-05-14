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
      key_type :hash, :source, :after_processing, :attachments
      key_type :integer, :limit
      key_type :hash_or_array, :on_email, :on_email_complete, :on_email_failure
    end
  end
end
