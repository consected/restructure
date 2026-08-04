# frozen_string_literal: true

# Investigation specs for: "an activity log with `embed:` extra options config
# does not create the embedded dynamic model when the extra log type is created
# (but the extra log type activity is created without error)".
#
# Each example below maps to a specific hypothesis raised during the
# investigation. The intent is to *expose* whether the hypothesis is a credible
# bug. If a spec fails or produces a surprising side effect (e.g. orphan
# embedded record), the underlying behaviour warrants a fix.
#
# Background context recorded in /memories/repo/embed_extra_log_type_create_gotchas.md
#
# Scenario being modelled (mirroring the user's real config):
#   - ActivityLog::PlayerContactVcri with two extra_log_types:
#       * `step_1`   — no embed
#       * `embed_step` — has `embed: dynamic_model__test_embed_invs`
#     and `creatable_if: { never: true }`, so it can only be reached via a
#     `create_reference` save_trigger from another activity log row.
#   - The trigger uses `force_create: true` and `force_not_valid: true`.
#
# Hypotheses tested:
#   H1. Happy path via create_reference: embed should be created with FK set.
#   H3. Multiple creatable references (embed plus a sibling `references:`
#       entry) cause `embedded_item(:creating)` to return nil — no embed.
#   H4. The embed dynamic model has its own `valid_if` requiring a non-blank
#       field; `force_not_valid: true` is NOT propagated through
#       `link_new_embedded_item`, so the embed's validation fails on
#       `update!(target_fk => id)`.
#   H5. The embed `resource_name` doesn't resolve in Resources::Models at
#       config load → `clean_embed_def` logs warn-only; later
#       `direct_embed_config` raises FphsException at create time (would
#       prevent parent from creating, so user's "parent created" symptom
#       contradicts this; documented as a sanity check).
#   H6. Same as H1 but the trigger runs from a different parent activity log
#       (`in: referring_record`) — mirrors the user's exact config shape.

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

AlNameEmbedInv = 'Embed Create Reference Investigation'

RSpec.describe 'embed via create_reference investigation', type: :model do
  include ActivityLogSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  def al_name
    AlNameEmbedInv
  end

  before :all do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
  end

  after :all do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  before :each do
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones

    # Resolve the parent activity log's expected table name and FK column
    # used by direct embed: foreign_key_field_name => "#{table_name.singularize}_id"
    @al_table = 'activity_log_player_contact_vcris'
    @al_fk = "#{@al_table.singularize}_id"

    setup_embed_target_models
    setup_activity_log_with_embed
    @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @master = @player_contact.master
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  # Build two embed-target dynamic models:
  #   - test_embed_invs (WITH the expected FK column) — happy path target
  #   - test_embed_validifs (WITH FK column, plus `valid_if` requiring
  #       a non-blank field) — exposes H4 force_not_valid gap
  def setup_embed_target_models
    %w[test_embed_invs test_embed_validifs].each do |tn|
      unless Admin::MigrationGenerator.table_exists? tn
        TableGenerators.dynamic_models_table(tn, :create_do, 'test1', 'test2', @al_fk)
      end
    end

    DynamicModel.active.where(table_name: %w[test_embed_invs test_embed_validifs])
                .each { |dm| dm.disable!(@admin) }

    DynamicModel.create!(current_admin: @admin, name: 'test embed invs',
                         table_name: 'test_embed_invs',
                         schema_name: 'dynamic_test', category: :test)
                .update_tracker_events

    validif_opts = <<~YAML
      default:
        label: With valid_if
        valid_if:
          on_create:
            all:
              this:
                test1:
                  not_blank: true
    YAML
    DynamicModel.create!(current_admin: @admin, name: 'test embed validifs',
                         table_name: 'test_embed_validifs',
                         schema_name: 'dynamic_test', category: :test,
                         options: validif_opts)
                .update_tracker_events

    let_user_create :dynamic_model__test_embed_invs
    let_user_create :dynamic_model__test_embed_validifs
  end

  # Configure ActivityLog::PlayerContactVcri with several extra_log_types,
  # each exercising a different hypothesis.
  def setup_activity_log_with_embed
    SetupHelper.setup_al_gen_tests AlNameEmbedInv, 'vcri', 'player_contact'

    al = ActivityLog.active.where(name: al_name).first
    raise "Activity Log #{al_name} not set up" if al.nil?

    al.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1 (source)
        fields:
          - select_call_direction
          - select_who

      embed_step:
        label: Embed Step (target with embed)
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__test_embed_invs
        creatable_if:
          never: true

      embed_step_validif:
        label: Embed Step - embed has valid_if requiring non-blank field
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__test_embed_validifs
        creatable_if:
          never: true

      embed_step_with_refs:
        label: Embed Step - embed alongside another creatable reference
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__test_embed_invs
        references:
          player_contacts:
            from: master
            add: many
        creatable_if:
          never: true

      embed_step_bad_resource:
        label: Embed Step - resource_name does not resolve
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__this_resource_does_not_exist
        creatable_if:
          never: true
    END_DEF

    al.current_admin = @admin
    al.save!
    al.force_option_config_parse

    @activity_log = al

    setup_access :activity_log__player_contact_vcris, user: @user
    al.option_configs.each do |c|
      setup_access c.resource_name, resource_type: :activity_log_type, user: @user
    end
  end

  # Build a source activity log row (extra_log_type: step_1) that we can use
  # as the @item in a SaveTriggers::CreateReference invocation. This mimics
  # the user's setup where the trigger fires from a source extra_log_type's
  # save_trigger block (in: referring_record).
  def source_log
    al = @player_contact.activity_log__player_contact_vcris.build(
      select_call_direction: 'from staff',
      extra_log_type: 'step_1',
      select_who: 'tester'
    )
    al.current_user = @user
    al.save!
    al
  end

  # Run a create_reference trigger that creates a new activity_log row with
  # the requested extra_log_type, in the referring_record. Returns the
  # newly created activity log instance from save_trigger_results.
  def fire_create_reference(target_extra_log_type, source:, force_not_valid: true)
    config = {
      activity_log__player_contact_vcri: {
        in: 'this',
        with: { extra_log_type: target_extra_log_type },
        force_create: true,
        force_not_valid: force_not_valid
      }
    }
    trigger = SaveTriggers::CreateReference.new(config, source)
    trigger.perform
    source.save_trigger_results['created_items'].last
  end

  # ------------------------------------------------------------------
  # Specs
  # ------------------------------------------------------------------

  describe 'H1: happy path via create_reference' do
    it 'creates the embed record with the parent FK set' do
      src = source_log
      new_al = fire_create_reference('embed_step', source: src)

      expect(new_al).to be_persisted
      expect(new_al.extra_log_type.to_s).to eq 'embed_step'
      expect(new_al.direct_embed?).to be_truthy

      new_al.current_user = @user
      embed_class = DynamicModel::TestEmbedInv
      embed_records = embed_class.where(@al_fk => new_al.id)

      expect(embed_records.count).to eq(1),
                                     "Expected exactly one embed record linked via #{@al_fk}=#{new_al.id}, " \
                                     "found #{embed_records.count}. " \
                                     'If 0: link_new_embedded_item silently failed or the embed branch was not taken.'
    end
  end

  describe 'H3: multiple creatable references alongside embed' do
    # When the extra_log_type has both `embed:` and a `references:` block
    # with another creatable item, `creatable_model_references` will return
    # more than one creatable entry, and `embedded_item(:creating)` returns
    # nil in the cmrs.length > 1 branch. Result: no embed is built.
    it 'fails to create the embed when there are siblings in references:' do
      src = source_log
      new_al = fire_create_reference('embed_step_with_refs', source: src)

      expect(new_al).to be_persisted

      embed_class = DynamicModel::TestEmbedInv
      embed_count = embed_class.where(@al_fk => new_al.id).count

      expect(embed_count).to eq(0),
                             'H3 prediction: with multiple creatable references, no embed is built. ' \
                             'If this fails (embed was created), the cmrs>1 branch does not apply to direct_embed.'
    end
  end

  describe 'H4: embed has valid_if; force_not_valid not propagated' do
    # The trigger sets force_not_valid: true. In create_reference.rb that is
    # only applied to the parent's `ignore_configurable_valid_if` and to the
    # `prep_embedded_item` flow. It is NOT propagated to the new embedded
    # item built by `link_new_embedded_item`, so the embed's own valid_if
    # rules still run, and `update!(target_fk => id)` raises RecordInvalid.
    #
    # That raise should roll back the parent's transaction too. So either:
    #   - the parent is NOT created (H4 confirmed), or
    #   - somehow the embed save is bypassed silently.
    it 'either rolls back the parent create or fails to create the embed' do
      src = source_log

      created_al = nil
      error = nil
      begin
        created_al = fire_create_reference('embed_step_validif', source: src)
      rescue StandardError => e
        error = e
      end

      embed_class = DynamicModel::TestEmbedValidif

      if error
        # Parent create was rolled back due to the embed validation failure.
        # This is the H4-confirmed branch. The user's report ("parent created
        # without error") therefore does NOT match H4 for their case, but
        # this captures the propagation gap.
        expect(error).to be_a(ActiveRecord::RecordInvalid)
          .or be_a(FphsException)
          .or be_a(FphsCalcConditionError)
        expect(embed_class.where(master_id: @master.id).count).to eq 0
      else
        # Parent supposedly persisted; check whether the embed exists.
        expect(created_al).to be_persisted
        embed_count = embed_class.where(@al_fk => created_al.id).count
        # Document the silent-no-embed case if it occurs.
        expect(embed_count).to eq(1),
                               'Parent created but no embed exists. H4 partially confirmed: ' \
                               'force_not_valid did not propagate to the embed and the failure was silent.'
      end
    end
  end

  describe 'H5: embed resource_name does not resolve in Resources::Models' do
    # clean_embed_def only logs a warning when the resource is not found,
    # leaving option_type_config.embed populated. At create time,
    # direct_embed_config raises FphsException "embed_resource not found".
    # This rolls back the parent. If the user's symptom is "parent created
    # without error", H5 cannot be their cause — this spec asserts the
    # expected raise so we know the behaviour is consistent.
    it 'raises FphsException at create time and prevents the parent from being created' do
      src = source_log

      expect do
        fire_create_reference('embed_step_bad_resource', source: src)
      end.to raise_error(FphsException, /embed_resource not found/)

      # Confirm no row was created under the embed_step_bad_resource type
      bad = src.master.activity_log__player_contact_vcris
               .where(extra_log_type: 'embed_step_bad_resource')
      expect(bad.count).to eq 0
    end
  end

  describe 'H6: same as H1 but reachable only via creatable_if: never + create_reference' do
    # Exact shape of user's config: creatable_if never, and reached via a
    # create_reference trigger using force_create + force_not_valid.
    it 'creates the embed when reached via referring_record trigger' do
      src = source_log

      config = {
        activity_log__player_contact_vcri: {
          in: 'this',
          with: { extra_log_type: 'embed_step' },
          force_create: true,
          force_not_valid: true
        }
      }
      trigger = SaveTriggers::CreateReference.new(config, src)
      trigger.perform

      new_al = src.save_trigger_results['created_items'].last
      expect(new_al).to be_persisted
      expect(new_al.extra_log_type.to_s).to eq 'embed_step'

      new_al.current_user = @user
      embed_class = DynamicModel::TestEmbedInv
      embeds = embed_class.where(@al_fk => new_al.id)

      expect(embeds.count).to eq(1),
                              'H6: with creatable_if:never + force_create via create_reference, ' \
                              'the embed should still be created and FK-linked.'
    end
  end
end
