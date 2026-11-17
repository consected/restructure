# frozen_string_literal: true

require 'rails_helper'

# Tests for issue #1445 (problem 2 - parent-synced fields have no visibility
# in the admin panel).
#
# Dynamic::ActivityLogImplementer.fields_to_sync intersects an activity log's
# attribute names with its parent item type's attribute names (minus a few
# common columns). Fields in this intersection are silently subtracted from
# `item_list` in ActivityLog::ActivityLogsController#edit_form_extras and from
# Dynamic::ActivityLogImplementer.permitted_params, so they never appear on
# activity forms and are never accepted from submitted form data - even when
# explicitly listed in an extra log type's `fields:` or the definition's
# `field_list`.
#
# app/views/admin/activity_logs/_def_details.html.erb now surfaces this via:
#   - a "parent item type" link at the top of the Details panel, to the parent
#     definition's own admin page, when the parent is admin-configurable
#     (a DynamicModel, ExternalIdentifier, or ActivityLog)
#   - a "synced fields" panel naming the parent item type and affected fields
#   - an inline annotation on the matching field(s) in the "activities" panel
#   - a diagnostic message in place of the panel if resolving the synced field
#     set fails (e.g. the implementation class/parent type can't be resolved)
#
# The shipped "Phone Log" seed (ActivityLog::PlayerContactPhone) is a
# real-world instance of this: its field_list includes "data", which also
# exists as an attribute on its parent item type (PlayerContact), so
# fields_to_sync == ["data"].
#
# Assertions are scoped to the specific panel/list-item elements (via
# Nokogiri), rather than matching generic substrings anywhere in the page, so
# they can't be satisfied by unrelated content elsewhere on the page.
RSpec.describe Admin::ActivityLogsController, type: :controller do
  include AdminActivityLogSupport
  include MasterSupport

  render_views

  def object_class
    ActivityLog
  end

  def item
    @activity_log
  end

  before(:context) do
    @path_prefix = '/admin'
  end

  before_each_login_admin

  describe 'the definition details page for an activity log with a parent-synced field' do
    before do
      # Other shared spec support fixtures (e.g. NfsStoreSupport's "AL Filter Test 2") also
      # target item_type: player_contact / rec_type: phone, and only one such definition can
      # be active at a time - disable any others so "Phone Log" can be enabled below.
      ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').where.not(name: 'Phone Log')
                 .update_all(disabled: true)

      SetupHelper.setup_al_player_contact_phones
      @phone_log = ActivityLog.where(name: 'Phone Log').first
      raise 'Phone Log activity log definition not found' unless @phone_log

      @phone_log.force_regenerate = true
      @phone_log.generate_model

      expect(ActivityLog::PlayerContactPhone.fields_to_sync).to eq(['data'])
    end

    it 'links "parent item type" to the Master Records admin page, since PlayerContact is a core model with no admin definition of its own' do
      get :edit, params: { id: @phone_log.id }

      doc = Nokogiri::HTML(response.body)
      link = doc.at_css('.al-parent-item-type a')
      expect(link).not_to be_nil, 'expected a "parent item type" link to be rendered'
      expect(link['href']).to eq(admin_master_records_path)
      expect(link.text).to match(/master record model/i)
    end

    it 'shows "data" as a synced field from the PlayerContact parent item type, with an explanation' do
      get :edit, params: { id: @phone_log.id }

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      panel = doc.at_css('.al-synced-fields')
      expect(panel).not_to be_nil, 'expected the "synced fields" panel to be rendered'

      heading = doc.at_css("[id$='-synced-fields-heading']")
      expect(heading&.text).to match(/synced fields/i)

      expect(panel.at_css('.al-synced-fields__parent-type')&.text&.strip).to eq('player_contact')

      item_texts = panel.css('.al-synced-fields__item').map { |li| li.text.strip }
      expect(item_texts).to eq(['data'])

      explanation = panel.at_css('p')&.text.to_s
      expect(explanation).to match(/hidden from (activity )?forms/i)
      expect(explanation).to match(/not accepted from (submitted )?form data/i)
    end

    it 'annotates the synced "data" field at its point of use in the activities panel field list' do
      get :edit, params: { id: @phone_log.id }

      doc = Nokogiri::HTML(response.body)
      synced_items = doc.css('.activity-list-activity-fields__item--synced').map { |li| li.text.strip }

      expect(synced_items).not_to be_empty
      expect(synced_items.any? { |t| t.start_with?('data') }).to be(true)
      expect(synced_items.any? { |t| t.match?(/synced from parent/i) }).to be(true)
    end
  end

  describe 'the definition details page with a configured synced-field opt-out' do
    before do
      ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').where.not(name: 'Phone Log')
                 .update_all(disabled: true)

      SetupHelper.setup_al_player_contact_phones
      @phone_log = ActivityLog.where(name: 'Phone Log').first
      raise 'Phone Log activity log definition not found' unless @phone_log

      @phone_log.force_regenerate = true
      @phone_log.generate_model
      parsed_options = YAML.safe_load(
        @phone_log.extra_log_types || '{}',
        permitted_classes: [],
        permitted_symbols: [],
        aliases: true
      ) || {}
      parsed_options['_configurations'] ||= {}
      parsed_options['_configurations']['no_sync_fields'] = 'data'
      @phone_log.extra_log_types = String.yaml_dump(parsed_options)
      @phone_log.option_configs(force: true)
      ActivityLog.definition_cache[@phone_log.id] = @phone_log
    end

    it 'shows configured opt-outs separately from effective synced fields for issue #1451' do
      get :edit, params: { id: @phone_log.id }

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      panel = doc.at_css('.al-synced-fields')
      expect(panel).not_to be_nil

      effective_fields = panel.css('.al-synced-fields__item').map { |li| li.text.strip }
      configured_opt_outs = panel.css('.al-no-sync-fields__item').map { |li| li.text.strip }

      expect(effective_fields).not_to include('data')
      expect(configured_opt_outs).to eq(['data'])
    end

    it 'marks a non-overlapping configured opt-out as inactive' do
      parsed_options = YAML.safe_load(
        @phone_log.extra_log_types || '{}',
        permitted_classes: [],
        permitted_symbols: [],
        aliases: true
      ) || {}
      parsed_options['_configurations']['no_sync_fields'] = ['data', 'not_a_real_parent_field']
      @phone_log.extra_log_types = String.yaml_dump(parsed_options)
      @phone_log.option_configs(force: true)
      ActivityLog.definition_cache[@phone_log.id] = @phone_log

      get :edit, params: { id: @phone_log.id }

      doc = Nokogiri::HTML(response.body)
      invalid_item = doc.at_css('.al-no-sync-fields__item--invalid')

      expect(invalid_item).not_to be_nil
      expect(invalid_item.text).to match(/not_a_real_parent_field/)
      expect(invalid_item.text).to match(/opt-out is inactive/i)
    end
  end

  describe 'the "parent item type" link when the parent is a DynamicModel' do
    before do
      admin = @admin

      # Pre-create the tables directly (rather than letting DynamicModel/ActivityLog auto-migrate
      # them) so this spec doesn't depend on the slow migration-generation subprocess.
      ActiveRecord::Base.connection.schema_cache.clear!
      TableGenerators.dynamic_models_table('dm_parent_link_tests', true, 'data', 'notes')

      @dm = DynamicModel.create!(
        current_admin: admin,
        name: 'Dm Parent Link Test',
        table_name: 'dm_parent_link_tests',
        primary_key_name: :id,
        foreign_key_name: :master_id,
        category: :test,
        field_list: 'data, notes'
      )

      ActiveRecord::Base.connection.schema_cache.clear!
      TableGenerators.activity_logs_table('activity_log_dm_parent_link_test_visits', 'dm_parent_link_tests', true, 'data', 'notes')

      @al = ActivityLog.create!(
        current_admin: admin,
        name: 'Al Dm Parent Link Test',
        item_type: @dm.implementation_model_name,
        rec_type: 'visit',
        action_when_attribute: 'created_at',
        field_list: 'data, notes'
      )
      @al.update_tracker_events

      expect(@al.implementation_class.parent_class.definition).to eq(@dm)
    end

    it 'links the parent type to the DynamicModel definition\'s own admin edit page, both at the top and in the synced fields panel' do
      get :edit, params: { id: @al.id }

      expect(response).to have_http_status(:ok)
      expected_href = admin_dynamic_models_path(filter: { id: @dm.id }, perform_action: 'edit')

      doc = Nokogiri::HTML(response.body)

      top_link = doc.at_css('.al-parent-item-type a')
      expect(top_link).not_to be_nil, 'expected a "parent item type" link to be rendered'
      expect(top_link['href']).to eq(expected_href)
      expect(top_link.text).to match(/dynamic model/i)

      panel = doc.at_css('.al-synced-fields')
      expect(panel).not_to be_nil

      panel_link = panel.at_css('a')
      expect(panel_link).not_to be_nil, 'expected the synced fields panel to link the parent type'
      expect(panel_link['href']).to eq(expected_href)
      expect(panel_link.at_css('.al-synced-fields__parent-type')&.text).to eq(@dm.implementation_model_name)

      # The "parent item type" section also notes and can expand-and-scroll-to the synced fields
      # panel below it, reusing the generic scroll-to-expanded data-toggle handler (no new JS)
      note_link = doc.at_css('.al-parent-item-type__synced-note a')
      expect(note_link).not_to be_nil, 'expected a synced-fields note under "parent item type"'
      expected_target = "#al-details-accordion-#{@al.id}-synced-fields-collapse"
      expect(note_link['href']).to eq(expected_target)
      expect(note_link['data-toggle']).to eq('collapse')
      expect(note_link['data-target']).to eq(expected_target)
      expect(note_link['class']).to include('scroll-to-expanded')
      # "collapsed" is required, not cosmetic: _fpa_form_utils.js's scroll-to-expanded handler
      # only scrolls when the clicked link itself starts in that state.
      expect(note_link['class']).to include('collapsed')
    end
  end

  describe 'the definition details page for an activity log with no parent-synced fields' do
    it 'does not render a synced-fields panel or mark any field as synced' do
      # Use a field ("notes_only_field") that does not exist on PlayerContact,
      # guaranteeing fields_to_sync is empty - unlike the shared
      # "activity_log_player_contact_emails" table name (used by other setup
      # helpers with an overlapping "data" column), which may already exist from
      # an earlier test run and so cannot be relied on to stay column-free.
      # PlayerContact only accepts rec_type values from its own fixed classification
      # list (Classification::GeneralSelection); "facebook" is a valid value that is
      # not otherwise used by any shipped activity log fixture.
      rec_type = 'facebook'
      table_name = "activity_log_player_contact_#{rec_type}s"

      # Ensure "facebook" is a valid PlayerContact rec_type classification - it is normally
      # provided by app-type specific configs rather than the base test seeds.
      gs = Classification::GeneralSelection.find_or_initialize_by(item_type: 'player_contacts_type', value: rec_type)
      gs.update!(name: 'Facebook', create_with: true, lock: true, current_admin: @admin) unless gs.admin

      ActiveRecord::Base.connection.schema_cache.clear!
      TableGenerators.activity_logs_table(table_name, 'player_contacts', true, 'notes_only_field')

      al = ActivityLog.create!(
        name: table_name,
        item_type: 'player_contact',
        rec_type:,
        action_when_attribute: 'created_at',
        field_list: 'notes_only_field',
        current_admin: @admin
      )
      al.update_tracker_events

      expect(al.implementation_class.fields_to_sync).to be_empty

      get :edit, params: { id: al.id }

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      expect(doc.at_css('.al-synced-fields')).to be_nil
      expect(doc.css('.activity-list-activity-fields__item--synced')).to be_empty
    end
  end

  describe 'the definition details page when synced field resolution fails' do
    before do
      ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').where.not(name: 'Phone Log')
                 .update_all(disabled: true)

      SetupHelper.setup_al_player_contact_phones
      @phone_log = ActivityLog.where(name: 'Phone Log').first
    end

    it 'shows a diagnostic message instead of breaking the details page' do
      # Simulate a definition whose synced fields can't be resolved (e.g. its parent item type
      # can't be constantized). Stubbing fields_to_sync on the specific implementation class
      # (rather than ActivityLog#implementation_class generally) avoids affecting other
      # unrelated parts of the same edit page that also resolve implementation_class for every
      # activity log definition (e.g. populating item type dropdowns).
      allow(ActivityLog::PlayerContactPhone).to receive(:fields_to_sync).and_raise(StandardError, 'boom')

      get :edit, params: { id: @phone_log.id }

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML(response.body)
      panel = doc.at_css('.al-synced-fields')
      expect(panel).not_to be_nil

      expect(panel.at_css('.al-synced-fields__error')&.text).to match(/boom/)
    end
  end
end
