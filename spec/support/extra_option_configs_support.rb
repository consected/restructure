# frozen_string_literal: true

# Shared helpers and constants for ExtraOptionConfigs specs.
# Include this module in any spec that tests configuration classes.
module ExtraOptionConfigsSupport
  # All expected config classes with their managed attributes.
  # Registry key must match the ExtraOptions attribute name.
  # Class names are singular (SaveTrigger not SaveTriggers).
  # AccessIf is split into CreatableIf, EditableIf, ShowableIf.
  EXPECTED_CONFIG_CLASSES = {
    fields: :Fields,
    label: :Label,
    caption_before: :CaptionBefore,
    dialog_before: :DialogBefore,
    labels: :Labels,
    show_if: :ShowIf,
    save_action: :SaveAction,
    view_options: :ViewOptions,
    db_configs: :DbConfigs,
    creatable_if: :CreatableIf,
    editable_if: :EditableIf,
    showable_if: :ShowableIf,
    valid_if: :ValidIf,
    filestore: :Filestore,
    field_options: :FieldOptions,
    embed: :Embed,
    references_config: :References,
    save_trigger: :SaveTrigger,
    batch_trigger: :BatchTrigger,
    config_trigger: :ConfigTrigger,
    preset_fields: :PresetFields,
    set_variables: :SetVariable,
    field_configs: :FieldConfigs
  }.freeze

  # Config classes that use the field-keyed BaseConfiguration pattern
  FIELD_KEYED_CLASSES = %i[CaptionBefore Labels DialogBefore ShowIf FieldOptions DbConfigs PresetFields].freeze

  # Config classes converted to BaseConfiguration with typed or direct attributes
  TYPED_CONFIG_CLASSES = %i[
    BatchTrigger SaveTrigger ViewOptions Filestore ConfigTrigger SaveAction ValidIf SetVariable
    Fields Label CreatableIf EditableIf ShowableIf Embed FieldConfigs
  ].freeze

  # Config classes that use source_attribute to read input from a different ExtraOptions attribute
  SOURCE_ATTRIBUTE_CLASSES = %i[References].freeze

  # Helper: update the DynamicModel with given YAML options and return the first option config
  def config_for(yaml)
    @dm.update!(options: yaml, current_admin: @admin)
    @dm.option_configs.first
  end

  # Helper: return all option configs for the given YAML
  def all_configs_for(yaml)
    @dm.update!(options: yaml, current_admin: @admin)
    @dm.option_configs
  end
end
