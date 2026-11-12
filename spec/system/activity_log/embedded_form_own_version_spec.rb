# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Validation of the product-owner requirement for issue 1481 (Handlebars lazy config):
#
#   An embedded form (a dynamic model embedded in an activity log) must view and edit using ITS OWN
#   definition version, unrelated to the parent item (exactly as if it were not embedded), and a NEW
#   embedded item must use the CURRENT version of the embedded definition. This must hold for field
#   labels, caption_before, dialog_before, show_if and the field list.
#
# The parent activity log and the embedded dynamic model are deliberately on DIFFERENT definition versions:
# the AL is versioned twice and the DM once after the first (old) records are created, so the old parent and
# old embedded record resolve to different version tokens, and the new parent and new embedded record do too.
# The embedded DM definition changes between its versions in every feature under test:
#   old: labels OldLabel*, caption_before all_fields, dialog_before on test1, fields test1/test2/test3,
#        show_if test2 <- test1 'old_trigger', test3 <- test1 'other_old'
#   new: labels NewLabel*, caption_before all_fields, dialog_before on test1, fields test1/test2/test4,
#        show_if test2 <- test1 'new_trigger', test4 <- test1 'other_new'
#
# Only observable outcomes are asserted (rendered text, element presence, visibility after show_if),
# so the same examples run unchanged on code before and after the Handlebars lazy-config phases.
#   (a) NEW parent form containing a NEW embedded form
#   (b) EDIT of an old parent (old embedded record) and of a new parent (new embedded record) on the same page
#   (c) SHOW (read-only) of the same two records on the same page
# Each case collects every feature assertion (aggregate_failures) so one run reports each feature separately.
describe 'Activity log embedded form uses its own definition version (issue 1481)',
         js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include FeatureSupport
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  # rubocop:disable Lint/ConstantDefinitionInBlock
  AlNameOwnVer = 'Embed Own Ver 1481'
  AlProcessOwnVer = 'aa_own_version'
  # Edit requests resolve the AL from the player contact item (ActivityLog.implementation_class_for), which does not
  # carry a process name, so the broad match is used: the first enabled AL for the item type ordered by process name.
  # The AL has no rec_type (an AL with both rec_type and process name is not associated with the app type), and the
  # process name sorts before those of other specs' ALs so this one is found for the test player contact.
  OwnVerContactRecType = 'email'
  OwnVerItemType = "player_contact_#{AlProcessOwnVer}"
  AlFkOwnVer = "activity_log_#{OwnVerItemType}_id"
  OwnVerDmTable = 'own_ver1481_embed_recs'
  OwnVerResource = "activity_log__#{OwnVerItemType.pluralize}"
  OwnVerAlType = 'own_ver_activity'
  OwnVerWait = 60
  OwnVerShortWait = 3

  OwnVerDmOptionsOld = <<~END_YAML
    default:
      label: Own Ver DM
      fields:
        - test1
        - test2
        - test3
      labels:
        test1: OldLabelOne
        test2: OldLabelTwo
        test3: OldLabelThree
      caption_before:
        all_fields:
          caption: OldCaptionBeforeAllFields
        test1:
          caption: OldCaptionBeforeOne
          show_caption: OldCaptionBeforeOne
          keep_label: true
      dialog_before:
        all_fields:
          name: own_ver_1481_dialog_old
          label: Old dialog button
      show_if:
        test2:
          test1: old_trigger
        test3:
          test1: other_old
  END_YAML

  OwnVerDmOptionsNew = <<~END_YAML
    default:
      label: Own Ver DM
      fields:
        - test1
        - test2
        - test4
      labels:
        test1: NewLabelOne
        test2: NewLabelTwo
        test4: NewLabelFour
      caption_before:
        all_fields:
          caption: NewCaptionBeforeAllFields
        test1:
          caption: NewCaptionBeforeOne
          show_caption: NewCaptionBeforeOne
          keep_label: true
      dialog_before:
        all_fields:
          name: own_ver_1481_dialog_new
          label: New dialog button
      show_if:
        test2:
          test1: new_trigger
        test4:
          test1: other_new
  END_YAML
  # rubocop:enable Lint/ConstantDefinitionInBlock

  def setup_embed_target_model
    TableGenerators.dynamic_models_table(OwnVerDmTable, :drop_do)
    TableGenerators.dynamic_models_table(OwnVerDmTable, :create_do, 'test1', 'test2', 'test3', 'test4', AlFkOwnVer)

    DynamicModel.active.where(table_name: OwnVerDmTable).each { |dm| dm.disable!(@admin) }

    DynamicModel.create!(current_admin: @admin, name: 'own ver1481 embed recs',
                         table_name: OwnVerDmTable, schema_name: 'dynamic_test', category: :test,
                         options: OwnVerDmOptionsOld)
                .update_tracker_events
  end

  def setup_dialog_templates
    { 'own_ver_1481_dialog_old' => 'Dialog message from the old embedded definition',
      'own_ver_1481_dialog_new' => 'Dialog message from the new embedded definition' }.each do |name, text|
      next if Admin::MessageTemplate.active.dialog_templates.find_by(name:)

      Admin::MessageTemplate.create!(name:, message_type: 'dialog', template_type: 'content',
                                     template: text, current_admin: @admin)
    end
  end

  def al_extra_log_types(who_label)
    <<~END_DEF
      #{OwnVerAlType}:
        label: Own ver activity
        fields:
          - select_call_direction
          - select_who
        labels:
          select_who: #{who_label}
        editable_if:
          always: true
        embed: dynamic_model__#{OwnVerDmTable}
    END_DEF
  end

  def setup_activity_log
    SetupHelper.setup_al_gen_tests AlNameOwnVer, AlProcessOwnVer, 'player_contact'

    al = ActivityLog.active.where(name: AlNameOwnVer).first
    raise "Activity Log #{AlNameOwnVer} not set up" if al.nil?

    al.extra_log_types = al_extra_log_types('AlWhoLabelOld')
    al.current_admin = @admin
    al.save!

    @activity_log = al
    @implementation_class = al.implementation_class
  end

  def setup_access_for_user
    setup_access :player_contacts, user: @user
    setup_access :player_infos, user: @user
    setup_access OwnVerResource.to_sym, user: @user
    setup_access "dynamic_model__#{OwnVerDmTable}".to_sym, user: @user
    # The activity log type resource names are only valid once the app type is associated with the new definitions
    Admin::AppType.reset_memo_associated_items!
    ActivityLog.reset_all_option_configs_resource_names!
    ActivityLog.reset_active_model_configurations!
    @activity_log.option_configs.each do |c|
      setup_access c.resource_name, resource_type: :activity_log_type, user: @user
    end
  end

  before :all do
    @prev_disable_vdef = Settings::DisableVDef
    change_setting('DisableVDef', false)

    SetupHelper.feature_setup

    @admin = create_admin.first
    create_user(create_master: false)
    @app_type = @user.app_type

    setup_dialog_templates
    setup_embed_target_model
    setup_activity_log
    setup_access_for_user

    @al_page_layout = Admin::PageLayout.create!(
      layout_name: 'master',
      panel_name: 'own-ver-embeds-1481',
      panel_label: 'Own Ver Embeds 1481',
      panel_position: 99,
      app_type: @app_type,
      current_admin: @admin,
      options: "contains:\n  resources:\n    - #{OwnVerResource}\nview_options:\n  initial_show: true\n"
    )

    @master = Master.create!(current_user: @user)
    @master.current_user = @user
    @master.player_infos.create!(first_name: 'OwnVer1481', last_name: 'Test', source: 'nflpa')
    @player_contact = @master.player_contacts.create!(
      current_user: @user, data: 'ownver1481@example.com', rec_type: OwnVerContactRecType, rank: 10
    )

    DynamicModel.define_models
    ActivityLog.define_models
    DynamicModel.routes_reload
    Rails.application.routes_reloader.reload!
  end

  after :all do
    change_setting('DisableVDef', @prev_disable_vdef)
    if @al_page_layout
      ActiveRecord::Base.connection.execute(
        "DELETE FROM page_layout_history WHERE page_layout_id = #{@al_page_layout.id}"
      )
      @al_page_layout.destroy
    end

    # Keep the definitions from leaking into the Handlebars templates compiled by later specs
    ActivityLog.where(name: AlNameOwnVer).find_each { |al| al.update_column(:disabled, true) }
    DynamicModel.where(table_name: OwnVerDmTable).find_each { |dm| dm.update_column(:disabled, true) }
    ActivityLog.define_models
    DynamicModel.define_models
  end

  before :each do
    Admin::AppConfiguration.clear_memo!
    HandlebarsPrecompiler.cleanup_tmp_dir
    HandlebarsPrecompiler.cleanup_compiled_output
    Rails.cache.delete('server_cache_version')
    login
  end

  # ===================================================================
  # Data and definition helpers
  # ===================================================================

  def create_al_record
    @implementation_class.create!(
      extra_log_type: OwnVerAlType,
      select_call_direction: 'to player',
      select_who: 'user',
      player_contact: @player_contact,
      master: @master,
      current_user: @user
    )
  end

  def embedded_dm_for(al_record)
    DynamicModel.active.find_by(table_name: OwnVerDmTable).implementation_class.find_by(AlFkOwnVer => al_record.id)
  end

  def set_embedded_values(al_record, **values)
    dm_rec = embedded_dm_for(al_record)
    raise "No auto-created embedded DM for AL #{al_record.id}" unless dm_rec

    dm_rec.current_user = @user
    dm_rec.update!(**values)
    dm_rec
  end

  # Replace the embedded DM definition options. Pre-populates the version memo from the test thread, since
  # the server thread cannot see the uncommitted history row inserted by the trigger.
  def bump_dm_definition(options)
    sleep 2
    dm = DynamicModel.active.find_by(table_name: OwnVerDmTable)
    change_setting('AllowDynamicMigrations', false)
    dm.current_admin = @admin
    dm.options = options
    dm.save!
    dm.all_versions
    change_setting('AllowDynamicMigrations', true)
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    AppControl.restart_server
  end

  def bump_al_definition(who_label)
    sleep 2
    change_setting('AllowDynamicMigrations', false)
    @activity_log.extra_log_types = al_extra_log_types(who_label)
    @activity_log.current_admin = @admin
    @activity_log.save!
    @activity_log.all_versions
    change_setting('AllowDynamicMigrations', true)
    ActivityLog.define_models
    Application.refresh_dynamic_defs
    AppControl.restart_server
  end

  # Old parent + old embedded record (AL v1 / DM v1), then DM v2, AL v2, AL v3 and a new parent + new embedded
  # record (AL v3 / DM v2). Parent and embedded tokens differ for both records.
  def build_versioned_records
    @old_al = create_al_record
    @old_dm = set_embedded_values(@old_al, test1: 'old_trigger', test2: 'old two value', test3: 'old three value')

    bump_dm_definition(OwnVerDmOptionsNew)
    bump_al_definition('AlWhoLabelMid')
    bump_al_definition('AlWhoLabelNew')

    @new_al = create_al_record
    @new_dm = set_embedded_values(@new_al, test1: 'new_trigger', test2: 'new two value', test4: 'new four value')

    expect_distinct_parent_and_embedded_versions
  end

  def expect_distinct_parent_and_embedded_versions
    # vdef_version is "v<history id>" for a record on an older definition version and "v<live token>" for one on
    # the current version, so it is the identifier the browser uses for each record's definition state.
    tokens = { old_al: reload_vdef(@old_al), old_dm: reload_vdef(@old_dm),
               new_al: reload_vdef(@new_al), new_dm: reload_vdef(@new_dm) }
    puts_debug_plain("version tokens: #{tokens.inspect}", force: true)
    # Records on the current version only have a distinct token once the lazy-config phases are in place
    expect(tokens[:old_al]).not_to eq tokens[:old_dm]
    expect(tokens[:old_al]).not_to eq tokens[:new_al]
    expect(tokens[:old_dm]).not_to eq tokens[:new_dm]
  end

  def reload_vdef(record)
    record.class.find(record.id).vdef_version
  end

  # ===================================================================
  # Browser helpers
  # ===================================================================

  def clear_caches_and_navigate
    Admin::AppConfiguration.clear_memo!
    HandlebarsPrecompiler.cleanup_tmp_dir
    HandlebarsPrecompiler.cleanup_compiled_output
    Rails.cache.delete('server_cache_version')
    page.driver.browser.execute_cdp('Network.clearBrowserCache')
    navigate_to_master(@master.id)
    expand_master_record_tab(OwnVerResource)
    page.has_css?('body.status-compiled', wait: 60)
  end

  def al_item_block(al_record)
    find("#activity-log--#{OwnVerItemType.hyphenate}-own-ver-activity-#{@master.id}-#{al_record.id}",
         wait: OwnVerWait)
  end

  def open_edit_form_for(al_record)
    block = al_item_block(al_record)
    expect(block).to have_text('AlWhoLabel', wait: OwnVerWait)
    btn = find("a.edit-entity[href$='/#{OwnVerItemType.pluralize}/#{al_record.id}/edit']", wait: OwnVerWait)
    scroll_into_view(btn)
    btn.click
    form = find("form#edit_activity_log_#{OwnVerItemType}_#{al_record.id}", wait: OwnVerWait)
    finish_form_formatting
    form
  end

  def open_new_form
    btn = find("a.add-item-button[href$='new?extra_type=own-ver-activity']", visible: :all, wait: OwnVerWait)
    scroll_into_view(btn)
    btn.click
    finish_page_loading
    form = find("form.new_activity_log_#{OwnVerItemType}", wait: OwnVerWait)
    finish_form_formatting
    form
  end

  def edit_container_css(field)
    "li.edit-field-container[data-edit-field-name='#{field}']"
  end

  def show_container_css(field)
    "li.result-field-container[data-field-name='#{field}']"
  end

  def set_trigger(form, value)
    within(form) { fill_in_field('test1', value) }
    sleep 0.5
  end

  # Edit / new form assertions for the embedded form inside `form` at the given definition version
  # (:old or :new). `trigger_values` lists [value, visible_fields, hidden_fields] show_if steps.
  def expect_embedded_edit_version(form, version, label)
    own = version == :old ? 'Old' : 'New'
    other = version == :old ? 'New' : 'Old'
    present_fields = version == :old ? %w[test1 test2 test3] : %w[test1 test2 test4]
    absent_field = version == :old ? 'test4' : 'test3'

    aggregate_failures "#{label} (edit)" do
      expect(form).to have_css("#{edit_container_css('test1')} label", text: "#{own}LabelOne", wait: OwnVerWait),
                      "#{label}: label from #{own} definition (labels)"
      expect(form).to have_no_css("label", text: "#{other}LabelOne", wait: OwnVerShortWait),
                      "#{label}: no label from #{other} definition (labels)"
      expect(form).to have_css("[data-cb-field-name='all_fields']", text: "#{own}CaptionBeforeAllFields",
                                                                    wait: OwnVerShortWait),
                      "#{label}: all_fields caption_before from #{own} definition"
      expect(form).to have_css("[data-cb-field-name='test1']", text: "#{own}CaptionBeforeOne", wait: OwnVerShortWait),
                      "#{label}: field caption_before from #{own} definition"
      expect(form).to have_no_text("#{other}CaptionBefore", wait: OwnVerShortWait),
                      "#{label}: no caption_before from #{other} definition"
      expect(form).to have_text(/Dialog message from the #{own.downcase} embedded definition/i, wait: OwnVerShortWait),
                      "#{label}: dialog_before from #{own} definition"
      expect(form).to have_no_text(/Dialog message from the #{other.downcase} embedded definition/i,
                                   wait: OwnVerShortWait),
                      "#{label}: no dialog_before from #{other} definition"
      present_fields.each do |f|
        expect(form).to have_css("[data-attr-name='#{f}']", visible: :all, wait: OwnVerShortWait),
                        "#{label}: field list includes #{f}"
      end
      expect(form).to have_no_css("[data-attr-name='#{absent_field}']", visible: :all, wait: OwnVerShortWait),
                      "#{label}: field list does not include #{absent_field}"
    end
  end

  # show_if steps: each step sets test1 then checks the visibility of the conditional fields
  def expect_edit_show_if_steps(form, label, steps)
    aggregate_failures "#{label} (edit show_if)" do
      steps.each do |value, visible, hidden|
        set_trigger(form, value) if value
        visible.each do |f|
          expect(form).to have_css(edit_container_css(f), wait: OwnVerShortWait),
                          "#{label}: show_if shows #{f} with test1=#{value.inspect}"
        end
        hidden.each do |f|
          expect(form).to have_no_css(edit_container_css(f), wait: OwnVerShortWait),
                          "#{label}: show_if hides #{f} with test1=#{value.inspect}"
        end
      end
    end
  end

  def expect_embedded_show_version(block, version, label)
    own = version == :old ? 'Old' : 'New'
    other = version == :old ? 'New' : 'Old'
    present_fields = version == :old ? %w[test1 test2 test3] : %w[test1 test2 test4]
    absent_field = version == :old ? 'test4' : 'test3'
    visible_cond = version == :old ? 'test2' : 'test2'
    hidden_cond = version == :old ? 'test3' : 'test4'

    aggregate_failures "#{label} (show)" do
      expect(block).to have_css("#{show_container_css('test1')} small.ctlabel", text: "#{own}LabelOne",
                                                                                wait: OwnVerWait),
                      "#{label}: label from #{own} definition (labels)"
      expect(block).to have_no_css('small.ctlabel', text: "#{other}LabelOne", wait: OwnVerShortWait),
                      "#{label}: no label from #{other} definition (labels)"
      expect(block).to have_css("[data-cb-field-name='test1']", text: "#{own}CaptionBeforeOne",
                                                                wait: OwnVerShortWait),
                      "#{label}: caption_before (show_caption) from #{own} definition"
      expect(block).to have_no_text("#{other}CaptionBefore", wait: OwnVerShortWait),
                      "#{label}: no caption_before from #{other} definition"
      # dialog_before is an edit / new form feature only: no dialog state is ever sent to the client for show mode.
      present_fields.each do |f|
        expect(block).to have_css(show_container_css(f), visible: :all, wait: OwnVerShortWait),
                        "#{label}: field list includes #{f}"
      end
      expect(block).to have_no_css(show_container_css(absent_field), visible: :all, wait: OwnVerShortWait),
                      "#{label}: field list does not include #{absent_field}"
      expect(block).to have_css(show_container_css(visible_cond), wait: OwnVerShortWait),
                      "#{label}: show_if shows #{visible_cond}"
      expect(block).to have_no_css(show_container_css(hidden_cond), wait: OwnVerShortWait),
                      "#{label}: show_if hides #{hidden_cond}"
    end
  end

  # ===================================================================
  # (a) NEW parent form with a NEW embedded form
  # ===================================================================
  describe '(a) new parent form with a new embedded form' do
    it 'uses the current embedded definition for labels, caption_before, dialog_before, field list and show_if',
       :aggregate_failures do
      build_versioned_records
      clear_caches_and_navigate

      form = open_new_form
      expect(form).to have_css('label', text: 'AlWhoLabelNew', wait: OwnVerWait)

      expect_embedded_edit_version(form, :new, 'new embedded form')
      # New embedded record: test1 is blank, so neither conditional field is shown until the trigger is set.
      expect_edit_show_if_steps(
        form, 'new embedded form',
        [[nil, [], %w[test2 test4]],
         ['old_trigger', [], %w[test2 test4]],
         ['new_trigger', %w[test2], %w[test4]],
         ['other_new', %w[test4], %w[test2]]]
      )
    end
  end

  # ===================================================================
  # (b) EDIT existing parents: old parent / old embedded and new parent / new embedded on one page
  # ===================================================================
  describe '(b) edit forms of existing parents' do
    it 'edits the old embedded record on its own old version and the new one on the current version',
       :aggregate_failures do
      build_versioned_records
      clear_caches_and_navigate

      old_form = open_edit_form_for(@old_al)
      expect(old_form).to have_css('label', text: 'AlWhoLabelOld', wait: OwnVerWait)
      expect_embedded_edit_version(old_form, :old, 'old embedded record')
      expect_edit_show_if_steps(
        old_form, 'old embedded record',
        [[nil, %w[test2], %w[test3]],
         ['other_old', %w[test3], %w[test2]],
         ['new_trigger', [], %w[test2 test3]],
         ['old_trigger', %w[test2], %w[test3]]]
      )

      new_form = open_edit_form_for(@new_al)
      expect(new_form).to have_css('label', text: 'AlWhoLabelNew', wait: OwnVerWait)
      expect_embedded_edit_version(new_form, :new, 'new embedded record')
      expect_edit_show_if_steps(
        new_form, 'new embedded record',
        [[nil, %w[test2], %w[test4]],
         ['other_new', %w[test4], %w[test2]],
         ['old_trigger', [], %w[test2 test4]],
         ['new_trigger', %w[test2], %w[test4]]]
      )
    end
  end

  # ===================================================================
  # (c) SHOW (read-only) of the same two records on one page
  # ===================================================================
  describe '(c) show mode of existing parents' do
    it 'shows the old embedded record on its own old version and the new one on the current version',
       :aggregate_failures do
      build_versioned_records
      clear_caches_and_navigate

      old_block = al_item_block(@old_al)
      expect(old_block).to have_text('AlWhoLabelOld', wait: OwnVerWait)
      expect_embedded_show_version(old_block, :old, 'old embedded record')

      new_block = al_item_block(@new_al)
      expect(new_block).to have_text('AlWhoLabelNew', wait: OwnVerWait)
      expect_embedded_show_version(new_block, :new, 'new embedded record')
    end
  end
end
