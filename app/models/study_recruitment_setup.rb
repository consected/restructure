# frozen_string_literal: true

# Utilities for managing study recruitment setup state.
# Detects when a dynamic model's initial-call configuration
# still uses legacy select_* field names and needs to be rebuilt.
module StudyRecruitmentSetup
  LEGACY_INITIAL_CALL_FIELDS = %w[select_still_interested select_continue_now].freeze

  # Returns true if the dynamic model's initial-call config still references
  # legacy select_*-prefixed field names (indicating the setup state is stale
  # and should be regenerated).
  # @param dynamic_model [DynamicModel] the initial-call dynamic model record
  # @return [Boolean]
  def self.stale_initial_call_dynamic_model_config?(dynamic_model)
    field_list = dynamic_model.field_list.to_s
    options    = dynamic_model.options.to_s

    LEGACY_INITIAL_CALL_FIELDS.any? do |legacy_field|
      field_list.include?(legacy_field) || options.include?(legacy_field)
    end
  end
end
