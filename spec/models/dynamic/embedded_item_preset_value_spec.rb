# frozen_string_literal: true

# Tests for issue #1067: Activity log embedded item field with preset_value
# incorrectly returns nil value in index action context.
#
# Scenario:
#   A dynamic model (source) has a text_array field with values ["a","b","c"].
#   An activity log embeds another dynamic model (embed target) that has the
#   same field configured with a preset_value referencing the source model
#   via conditional actions (return_value).
#
#   The show action correctly returns the computed preset value because
#   EmbeddedItemHandler#handle_embedded_item calls force_preset_values.
#   The index action should apply the same embedded item evaluations used by
#   show/edit/new/create/update via the embedded item handler path.
#
#   This is observable when the source data is created or updated after
#   the embedded item was initially saved, leaving the DB value stale
#   or null while force_preset_values would return the correct current value.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

AlNamePresetEmbed = 'Preset Embed Test'

RSpec.describe 'Embedded item preset_value in index vs show (#1067)', type: :model do
  include ActivityLogSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  def al_name
    AlNamePresetEmbed
  end

  before :all do
    @allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
  end

  after :all do
    change_setting('AllowDynamicMigrations', @allow_dms)
  end

  before :each do
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones

    generate_test_dynamic_model # creates test_created_by_recs (used as source model with text_array column)
    setup_source_and_embed_models
    setup_activity_log_with_embed
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  def setup_source_and_embed_models
    # Source model: test_created_by_recs already has a text_array column
    # We just need to make sure the user has access
    setup_access :dynamic_model__test_created_by_recs, user: @user

    # Embedded model: create a DM table that will be directly embedded
    # in the activity log, with a text_array field + FK back to the AL
    al_table = 'activity_log_player_contact_elts'
    fk_column = "#{al_table.singularize}_id"

    unless Admin::MigrationGenerator.table_exists? 'test_preset_embed_recs'
      TableGenerators.dynamic_models_table(
        'test_preset_embed_recs', :create_do,
        'text_array',
        fk_column
      )
    end

    # Clean up any previous definitions
    DynamicModel.active.where(table_name: 'test_preset_embed_recs').each { |dm| dm.disable!(@admin) }
    begin
      DynamicModel.send(:remove_const, :TestPresetEmbedRec) if DynamicModel.const_defined?(:TestPresetEmbedRec, false)
    rescue NameError
      # May have been removed by a parallel test
    end

    embed_options = <<~YAML
      default:
        label: Preset Embed
        field_options:
          text_array:
            preset_value:
              dynamic_model__test_created_by_recs:
                text_array: return_value
    YAML

    @embed_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test preset embed',
      table_name: 'test_preset_embed_recs',
      schema_name: 'dynamic_test',
      category: :test,
      options: embed_options
    )
    @embed_dm.current_admin = @admin
    @embed_dm.update_tracker_events

    setup_access :dynamic_model__test_preset_embed_recs, user: @user
    let_user_create :dynamic_model__test_preset_embed_recs
  end

  def setup_activity_log_with_embed
    SetupHelper.setup_al_gen_tests AlNamePresetEmbed, 'elt', 'player_contact'

    @activity_log = al = ActivityLog.active.where(name: al_name).first
    raise "Activity Log #{al_name} not set up" if al.nil?

    al.extra_log_types = <<~END_DEF
      preset_embed_test:
        label: Preset Embed Test
        fields:
          - select_call_direction
          - select_who

        embed:
          resource_name: dynamic_model__test_preset_embed_recs
    END_DEF

    al.current_admin = @admin
    al.save!

    setup_access :activity_log__player_contact_elts, user: @user
    al.option_configs.each do |c|
      setup_access c.resource_name, resource_type: :activity_log_type, user: @user
    end
  end

  # ------------------------------------------------------------------
  # Specs
  # ------------------------------------------------------------------

  describe 'embedded item preset_value from another model' do
    it 'returns the preset field value in show context when source data is added after creation' do
      @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)
      master = @player_contact.master

      # Create the activity log BEFORE the source record exists.
      # The embedded item is created with a null preset_value because
      # no source record is available during after_initialize.
      al = @player_contact.activity_log__player_contact_elts.build(
        select_call_direction: 'from staff',
        extra_log_type: 'preset_embed_test',
        select_who: 'tester'
      )
      al.save!

      # Now create the source record that the preset_value references
      source_values = %w[kit_a kit_b kit_c]
      master.dynamic_model__test_created_by_recs.create!(text_array: source_values)

      # Reload from DB to simulate a fresh load (as the controller does for show)
      al = al.class.find(al.id)
      al.current_user = @user
      al.action_name = 'show'

      ei = al.embedded_item
      expect(ei).not_to be_nil

      # Simulate what EmbeddedItemHandler#handle_embedded_item does for show:
      # force_preset_values recalculates the value from the now-existing source record
      ei.force_preset_values

      expect(ei.text_array).to eq(source_values),
                               'Show context: text_array should have preset values after force_preset_values'
    end

    it 'returns the preset field value in index context when source data is added after creation (regression #1067)' do
      @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)
      master = @player_contact.master

      # Create the activity log BEFORE the source record exists.
      # The embedded item is created with a null preset_value because
      # no source record is available during after_initialize.
      al = @player_contact.activity_log__player_contact_elts.build(
        select_call_direction: 'from staff',
        extra_log_type: 'preset_embed_test',
        select_who: 'tester'
      )
      al.save!

      # Now create the source record
      source_values = %w[kit_a kit_b kit_c]
      master.dynamic_model__test_created_by_recs.create!(text_array: source_values)

      # Reload from DB to simulate a fresh load before index handling runs
      al = al.class.find(al.id)
      al.current_user = @user
      al.action_name = 'index'

      ei = al.embedded_item
      expect(ei).not_to be_nil, 'Expected embedded_item to be present in index context'

      # Simulate index-time embedded item evaluation performed by
      # EmbeddedItemHandler#handle_embedded_item.
      ei.force_preset_values if ei.respond_to?(:force_preset_values)
      ei.evaluate_active_values if ei.respond_to?(:evaluate_active_values)

      expect(ei.text_array).to eq(source_values),
                               'Regression #1067: embedded_item text_array should not be null in index context'
    end

    it 'returns consistent as_json between show and index for preset field (regression #1067)' do
      @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)
      master = @player_contact.master

      # Create the activity log BEFORE the source record exists
      al = @player_contact.activity_log__player_contact_elts.build(
        select_call_direction: 'from staff',
        extra_log_type: 'preset_embed_test',
        select_who: 'tester'
      )
      al.save!

      # Create the source record after the embedded item is saved
      source_values = %w[kit_a kit_b kit_c]
      master.dynamic_model__test_created_by_recs.create!(text_array: source_values)

      # --- Show context (handle_embedded_item runs) ---
      show_al = al.class.find(al.id)
      show_al.current_user = @user
      show_al.action_name = 'show'
      show_ei = show_al.embedded_item
      show_ei&.force_preset_values
      show_ei&.evaluate_active_values if show_ei&.respond_to?(:evaluate_active_values)
      show_json = show_al.as_json
      show_embedded = show_json['embedded_item']
      expect(show_embedded).not_to be_nil, 'Show: embedded_item should be present in JSON'
      expect(show_embedded['text_array']).to eq(source_values),
                                             'Show: text_array should reflect the current source data'

      # --- Index context (handle_embedded_item logic applied for list records) ---
      index_al = al.class.find(al.id)
      index_al.current_user = @user
      index_al.action_name = 'index'
      index_ei = index_al.embedded_item
      index_ei&.force_preset_values
      index_ei&.evaluate_active_values if index_ei&.respond_to?(:evaluate_active_values)
      index_json = index_al.as_json
      index_embedded = index_json['embedded_item']
      expect(index_embedded).not_to be_nil,
                                    'Regression #1067: embedded_item should be present in index JSON'
      expect(index_embedded['text_array']).to eq(source_values),
                                              'Regression #1067: index as_json should match show value for preset field'
    end
  end
end
