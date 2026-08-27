# frozen_string_literal: true

module OptionConfigs
  module TriggerTypes
    # Descriptor for the create_reference save trigger.
    # Named-entry pattern: config is { model_name: { actual_keys... } }.
    class CreateReference < Base
      trigger_name :create_reference
      pattern :named_entry
      allowed_keys %i[if in force_create force_not_valid with_result with on_complete on_failure
                       to_existing_record this_has_no_master_association]
      standard_hook_key_types
      key_type :string_or_hash, :in
      key_type :boolean, :force_create, :force_not_valid, :this_has_no_master_association
      key_type :hash_or_array, :with_result
      key_type :hash, :with, :to_existing_record

      # in: 'this'/'referring_record' resolve a not-yet-persisted record's id when run
      # from before_save, silently creating an orphaned ModelReference (see issue #1384).
      # Other `in:` targets (master, none, master_with_reference, specific_record) don't
      # depend on this record's own id, so they remain safe within before_save.
      UNSAFE_IN_BEFORE_SAVE = %w[this referring_record].freeze

      class << self
        def before_save_warning(config)
          entries = config.is_a?(Array) ? config : [config]
          unsafe = entries.any? do |entry|
            entry.is_a?(Hash) && entry.values.any? do |sub_config|
              sub_config.is_a?(Hash) && UNSAFE_IN_BEFORE_SAVE.include?(sub_config[:in].to_s)
            end
          end
          return unless unsafe

          "with in: 'this'/'referring_record' can not reliably run within before_save " \
            '(the record has no id yet) - use on_create/on_update instead'
        end
      end
    end
  end
end
