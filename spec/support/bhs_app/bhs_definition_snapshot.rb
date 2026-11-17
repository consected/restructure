# frozen_string_literal: true

# Captures the state of shared dynamic definitions (activity logs, dynamic models,
# external identifiers and app types) and the settings changed by the BHS spec,
# so they can be restored in after(:all). Without this, BhsImportConfig disables
# and renames existing definitions and the BHS spec disables dynamic models, which
# breaks later specs that share the same test database (e.g. PLAY-IPA, Study Recruitment).
module BhsDefinitionSnapshot
  RESTORED_COLUMNS = %i[disabled name label external_id_attribute].freeze
  SNAPSHOT_SETTINGS = %w[TwoFactorAuthDisabledForUser].freeze

  def self.definition_classes
    [ActivityLog, DynamicModel, ExternalIdentifier, Admin::AppType]
  end

  def self.restored_columns_for(klass)
    RESTORED_COLUMNS.select { |column| klass.column_names.include?(column.to_s) }
  end

  def self.setting_value(name)
    Settings.const_defined?(name, false) ? Settings.const_get(name) : nil
  end

  # @return [Hash] { definitions: { klass => { id => { column => value } } }, settings: { name => value } }
  def self.capture
    definitions = definition_classes.to_h do |klass|
      columns = restored_columns_for(klass)
      rows = klass.unscoped.pluck(:id, *columns).map { |id, *values| [id, columns.zip(values).to_h] }
      [klass, rows.to_h]
    end

    { definitions:, settings: SNAPSHOT_SETTINGS.to_h { |name| [name, setting_value(name)] } }
  end

  # Disables definitions created since the snapshot, restores the captured columns,
  # then regenerates the runtime classes so later specs see the original definitions.
  def self.restore(snapshot)
    definition_classes.each do |klass|
      touch = klass.column_names.include?('updated_at') ? { updated_at: Time.current } : {}
      captured_ids = snapshot[:definitions][klass].keys

      klass.unscoped.where.not(id: captured_ids).where(disabled: [false, nil])
           .update_all({ disabled: true }.merge(touch))

      snapshot[:definitions][klass].each do |id, values|
        klass.unscoped.where(id:).update_all(values.merge(touch))
      end
    end

    snapshot[:settings].each { |name, value| change_setting(name, value) }

    # Clear memos explicitly: up_to_date? treats changes within 2 seconds as unchanged
    [ActivityLog, DynamicModel, ExternalIdentifier].each do |klass|
      klass.reset_active_model_configurations! if klass.respond_to?(:reset_active_model_configurations!)
    end
    SetupHelper.reload_configs
  end
end
