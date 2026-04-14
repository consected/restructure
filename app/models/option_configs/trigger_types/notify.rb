# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the notify save trigger.
    # Named-entry pattern: config is { arbitrary_label: { actual_keys... } }.
    class Notify < Base
      trigger_name :notify
      pattern :named_entry
      allowed_keys %i[
        type role users emails phones phone_records list_type default_country_code
        from_user_email ignore_no_recipients layout_template content_template
        content_template_text subject calendar_invite attachments extra_substitutions
        importance when on_complete on_failure if app_type user
      ]
      standard_hook_key_types
      key_type :string_or_hash, :type, :role, :list_type, :default_country_code, :layout_template,
               :content_template, :content_template_text, :subject, :importance, :app_type,
               :user
      key_type :scalar_or_array_or_hash, :users, :emails, :phones, :phone_records
      key_type :hash, :from_user_email, :calendar_invite, :extra_substitutions, :when
      key_type :array, :attachments
      key_type :boolean, :ignore_no_recipients
    end
  end
end
