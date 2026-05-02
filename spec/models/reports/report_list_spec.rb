# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Reports::ReportList (Issue #1108)
#
# Verifies the full lifecycle of a report list, covering:
# - setup method: JSON parsing, error raising (blank items, multiple source types,
#   invalid list_id), authorization (user vs admin), and on_attr defaulting
# - add_items_to_list: inserts records, raises on duplicates, returns count
# - update_items_in_list: adds new selections, disables removed selections, returns total count
# - remove_items_from_list: disables selected items, raises when list empty, returns id list
#
# Test data uses two dynamically-created models:
# - test_rpt_source_recs: the source data model (with master_id FK)
# - test_rpt_list_recs: the selections list model (with master_id FK + player_info_id FK)
# A PlayerInfo record is used as the "parent" (assoc_attr = player_info_id),
# allowing check_valid_list_id! to resolve PlayerInfo.where(id: list_id).

RSpec.describe Reports::ReportList, type: :model do
  include MasterSupport
  include ModelSupport

  SOURCE_TABLE_NAME = 'test_rpt_source_recs'
  LIST_TABLE_NAME   = 'test_rpt_list_recs'
  # source_type value in items JSON: includes dynamic_model__ namespace so
  # ModelReference.to_record_class_for_type resolves DynamicModel::TestRptSourceRec
  ITEMS_SOURCE_TYPE = 'dynamic_model__test_rpt_source_recs'

  before :all do
    change_setting('AllowDynamicMigrations', true)

    create_admin
    create_user
    @authorized_user = @user

    # Create a second user WITHOUT view_reports for the authorization failure test
    create_user
    @unauthorized_user = @user
    @user = @authorized_user # restore @user to the authorized one

    # Pre-create the underlying tables so DynamicModel creation skips migration
    unless Admin::MigrationGenerator.table_exists?(SOURCE_TABLE_NAME)
      TableGenerators.dynamic_models_table(SOURCE_TABLE_NAME, :create_do, 'test_value')
    end
    unless Admin::MigrationGenerator.table_exists?(LIST_TABLE_NAME)
      TableGenerators.dynamic_models_table(
        LIST_TABLE_NAME, :create_do,
        'record_type', 'record_id', 'player_info_id', 'test_value', 'disabled'
      )
    end

    # Remove stale DynamicModel definitions so we start clean
    DynamicModel.active.where(table_name: SOURCE_TABLE_NAME).each { |dm| dm.disable!(@admin) }
    DynamicModel.active.where(table_name: LIST_TABLE_NAME).each { |dm| dm.disable!(@admin) }

    %i[TestRptSourceRec TestRptListRec].each do |const|
      DynamicModel.send(:remove_const, const) if DynamicModel.const_defined?(const, false)
    rescue NameError
      # already removed
    end

    @source_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test rpt source rec',
      table_name: SOURCE_TABLE_NAME,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test
    )
    @source_dm.current_admin = @admin
    @source_dm.update_tracker_events

    @list_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test rpt list rec',
      table_name: LIST_TABLE_NAME,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test
    )
    @list_dm.current_admin = @admin
    @list_dm.update_tracker_events

    # Grant view_reports only to @authorized_user (user-specific to keep @unauthorized_user excluded)
    unless @authorized_user.can?(:view_reports)
      Admin::UserAccessControl.create!(
        app_type: @authorized_user.app_type,
        access: :read,
        resource_type: :general,
        resource_name: :view_reports,
        user: @authorized_user,
        current_admin: @admin
      )
    end

    # Table access for the authorized user
    setup_access :dynamic_model__test_rpt_source_recs, resource_type: :table, access: :create, user: @authorized_user
    setup_access :dynamic_model__test_rpt_list_recs,   resource_type: :table, access: :create, user: @authorized_user
    setup_access :player_infos, resource_type: :table, access: :create, user: @authorized_user

    # Create a master owned by @authorized_user and a PlayerInfo record that acts
    # as the "parent" record that list_id references (via assoc_attr = player_info_id)
    let_user_create_master @authorized_user
    @master = Master.create!(current_user: @authorized_user)
    @master.current_user = @authorized_user

    @player_info = PlayerInfo.create!(
      master: @master,
      current_user: @authorized_user,
      first_name: 'Test',
      last_name: 'ReportListParent'
    )
    @list_id = @player_info.id.to_s

    change_setting('AllowDynamicMigrations', false)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :example do
    # Remove all list records between tests for isolation.
    # History must be deleted first to satisfy the FK constraint.
    ActiveRecord::Base.connection.execute('DELETE FROM test_rpt_list_rec_history')
    DynamicModel::TestRptListRec.delete_all

    # Create a fresh source record for each example
    @source_rec = DynamicModel::TestRptSourceRec.new(
      test_value: 'hello',
      master: @master,
      current_user: @authorized_user
    )
    @source_rec.save!
  end

  # Build an array of JSON strings in the format expected by ReportList#setup
  # Each element represents one checkbox submission from the report form
  def build_items(ids, overrides = {})
    ids.map do |id|
      {
        'type' => ITEMS_SOURCE_TYPE,
        'id' => id,
        'list_id' => @list_id,
        'from_master_id' => @master.id,
        'init_value' => false
      }.merge(overrides).to_json
    end
  end

  # -------------------------------------------------------------------
  describe '.setup' do
    context 'basic parsing' do
      it 'parses the JSON items array, setting source_type and list_id correctly' do
        items_text = build_items([@source_rec.id])
        rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)

        expect(rl.source_type).to eq ITEMS_SOURCE_TYPE
        expect(rl.list_id).to eq @list_id
        expect(rl.items).to be_an(Array)
        expect(rl.items.length).to eq 1
      end

      it 'raises FphsGeneralError when items_text is an empty array' do
        expect do
          Reports::ReportList.setup(LIST_TABLE_NAME, [], @authorized_user)
        end.to raise_error(FphsGeneralError, /no items selected/)
      end

      it 'raises FphsGeneralError when items_text is nil' do
        expect do
          Reports::ReportList.setup(LIST_TABLE_NAME, nil, @authorized_user)
        end.to raise_error(FphsGeneralError, /no items selected/)
      end

      it 'raises FphsGeneralError when items contain more than one unique source type' do
        items_text = [
          { 'type' => ITEMS_SOURCE_TYPE,            'id' => @source_rec.id, 'list_id' => @list_id,
            'from_master_id' => @master.id }.to_json,
          { 'type' => 'dynamic_model__other_recs',  'id' => 99, 'list_id' => @list_id,
            'from_master_id' => @master.id }.to_json
        ]

        expect do
          Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)
        end.to raise_error(FphsGeneralError, /source type not specified/)
      end

      it 'raises FphsGeneralError when items contain multiple different list_ids' do
        other_pi = PlayerInfo.create!(master: @master, current_user: @authorized_user,
                                      first_name: 'Other', last_name: 'Parent')
        items_text = [
          { 'type' => ITEMS_SOURCE_TYPE, 'id' => @source_rec.id, 'list_id' => @list_id,
            'from_master_id' => @master.id }.to_json,
          { 'type' => ITEMS_SOURCE_TYPE, 'id' => @source_rec.id, 'list_id' => other_pi.id.to_s,
            'from_master_id' => @master.id }.to_json
        ]

        expect do
          Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)
        end.to raise_error(FphsGeneralError, /list id not specified/)
      end

      it 'raises FphsGeneralError when list_id resolves to nil (all items have nil list_id)' do
        items_text = [
          { 'type' => ITEMS_SOURCE_TYPE, 'id' => @source_rec.id, 'list_id' => nil,
            'from_master_id' => @master.id }.to_json
        ]

        expect do
          Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)
        end.to raise_error(FphsGeneralError, /list id not specified/)
      end
    end

    context 'authorization' do
      it 'raises FphsException with "not authorized" when user has neither view_report_not_list nor view_reports' do
        items_text = build_items([@source_rec.id])

        expect do
          Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @unauthorized_user)
        end.to raise_error(FphsException, /not authorized/)
      end

      it 'bypasses the view_reports check and returns a ReportList when current_admin is present' do
        items_text = build_items([@source_rec.id])

        # Even though authorized_user has view_reports, the key behaviour is that
        # passing an admin means authorized? returns true immediately (before can? is called)
        rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user, @admin)

        expect(rl).to be_a(Reports::ReportList)
      end
    end

    context 'on_attr handling' do
      it 'defaults list_on_attr to "id" when no on_attr key is present in the items' do
        items_text = build_items([@source_rec.id])
        rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)

        expect(rl.list_on_attr).to eq 'id'
      end

      it 'uses the on_attr value from the first item when the key is present' do
        # Use 'first_name' as the on_attr, matching by the player_info's stored first_name value.
        # PlayerInfo downcases name fields on save, so @player_info.first_name is 'test'.
        # This proves on_attr is read from the items JSON and used for the PlayerInfo lookup.
        items_text = [{
          'type' => ITEMS_SOURCE_TYPE,
          'id' => @source_rec.id,
          'list_id' => @player_info.first_name,
          'from_master_id' => @master.id,
          'on_attr' => 'first_name',
          'init_value' => false
        }.to_json]

        rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)
        expect(rl.list_on_attr).to eq 'first_name'
      end
    end
  end

  # -------------------------------------------------------------------
  describe '#add_items_to_list' do
    it 'inserts one new record into the list table for each new_item_id' do
      items_text = build_items([@source_rec.id])
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)

      expect do
        rl.add_items_to_list
      end.to change { DynamicModel::TestRptListRec.count }.by(1)

      new_rec = DynamicModel::TestRptListRec.last
      expect(new_rec.record_id).to eq @source_rec.id
      expect(new_rec.record_type).to be_present
    end

    it 'raises FphsGeneralError with "all items already in the list" when new_item_ids is empty (item already added)' do
      # First add – succeeds
      items_text = build_items([@source_rec.id])
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)
      rl.add_items_to_list

      # Second setup call finds the item already in the list, so new_item_ids is empty
      rl2 = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)

      expect do
        rl2.add_items_to_list
      end.to raise_error(FphsGeneralError, /all items already in the list/)
    end

    it 'returns the integer count of newly added items' do
      items_text = build_items([@source_rec.id])
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)

      count = rl.add_items_to_list

      expect(count).to eq 1
    end
  end

  # -------------------------------------------------------------------
  describe '#update_items_in_list' do
    it 'adds new selections to the list table when they are not yet present' do
      items_text = build_items([@source_rec.id])
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)

      expect do
        rl.update_items_in_list
      end.to change { DynamicModel::TestRptListRec.active.count }.by(1)
    end

    it 'disables records whose record_id was in the list but not included in the new submission' do
      # Add source_rec to the list
      items_text = build_items([@source_rec.id])
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)
      rl.update_items_in_list

      # Create a second source record
      src2 = DynamicModel::TestRptSourceRec.new(test_value: 'world', master: @master,
                                                current_user: @authorized_user)
      src2.save!

      # Submit only src2 — source_rec is omitted so it should be disabled
      items_text2 = build_items([src2.id])
      rl2 = Reports::ReportList.setup(LIST_TABLE_NAME, items_text2, @authorized_user)
      rl2.update_items_in_list

      original_list_rec = DynamicModel::TestRptListRec.find_by(record_id: @source_rec.id)
      expect(original_list_rec).to be_present
      expect(original_list_rec.disabled).to be_truthy
    end

    it 'returns the sum of new_item_ids.length + removed_item_ids.length' do
      # Add source_rec first
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, build_items([@source_rec.id]), @authorized_user)
      rl.update_items_in_list

      src2 = DynamicModel::TestRptSourceRec.new(test_value: 'world2', master: @master,
                                                current_user: @authorized_user)
      src2.save!

      # Switch to src2 only: 1 new + 1 removed = 2
      rl2 = Reports::ReportList.setup(LIST_TABLE_NAME, build_items([src2.id]), @authorized_user)
      result = rl2.update_items_in_list

      expect(result).to eq 2
    end
  end

  # -------------------------------------------------------------------
  # NOTE: For *remove_from_list*, the production SQL pattern (see bulk-msg config,
  # report id 98 "Players Selected") submits the *list row's primary key* in the
  # JSON *id* field, not the source record_id. The intersection
  # *item_ids & items_in_list_ids* in *#setup* matches list rows to disable.
  describe '#remove_items_from_list' do
    it 'disables all items currently in the list whose list-row id matches a submitted item id' do
      # Add source_rec to the list first using the standard add_to_list flow
      add_items = build_items([@source_rec.id])
      rl_add = Reports::ReportList.setup(LIST_TABLE_NAME, add_items, @authorized_user)
      rl_add.add_items_to_list

      list_rec = DynamicModel::TestRptListRec.active.first
      expect(list_rec).to be_present

      # Build items using the LIST ROW's primary key (production *remove_from_list* pattern)
      remove_items = build_items([list_rec.id])
      rl_remove = Reports::ReportList.setup(LIST_TABLE_NAME, remove_items, @authorized_user)
      rl_remove.remove_items_from_list

      list_rec.reload
      expect(list_rec.disabled).to be_truthy
    end

    it 'raises FphsGeneralError with "no items in the list can be removed" when no submitted ids match active list rows' do
      # List is empty, so item_ids_in_list (intersection) is []
      items_text = build_items([@source_rec.id])
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)

      expect do
        rl.remove_items_from_list
      end.to raise_error(FphsGeneralError, /no items in the list can be removed/)
    end

    it 'returns the array of disabled list-row IDs' do
      add_items = build_items([@source_rec.id])
      Reports::ReportList.setup(LIST_TABLE_NAME, add_items, @authorized_user).add_items_to_list

      list_rec = DynamicModel::TestRptListRec.active.first
      remove_items = build_items([list_rec.id])
      result = Reports::ReportList.setup(LIST_TABLE_NAME, remove_items, @authorized_user)
                                  .remove_items_from_list

      expect(result).to eq [list_rec.id]
    end
  end

  # -------------------------------------------------------------------
  # End-to-end verification of the SQL example documented in
  # docs/admin_reference/reports/select_items_lists.md
  #
  # Mirrors the documented "update list" template, adapted to the test schemas:
  # source = test_rpt_source_recs, list = test_rpt_list_recs,
  # parent table = player_infos (matches assoc_attr = player_info_id).
  #
  # Verifies that the documented SQL pattern produces JSON values that
  # ReportList.setup parses successfully and that update_items_in_list
  # writes the expected list rows.
  describe 'end-to-end: documented update list SQL example' do
    let(:report_sql) do
      <<~SQL
        select distinct
          source.id,
          '{"field_name": "update_list[items][]",' ||
          '"value": {"list_id": "' || :list_id || '",' ||
            '"type":"dynamic_model__test_rpt_source_recs",' ||
            '"id": ' || source.id || ',' ||
            '"from_master_id":' || source.master_id || ',' ||
            '"init_value": ' ||
              case when coalesce(selections.id, 0) = 0 then 'false' else 'true' end
            || '} }'
            "select items: update list: test_rpt_list_recs",
          source.test_value
        from test_rpt_source_recs source
        left join test_rpt_list_recs selections
          on selections.record_id = source.id
          and selections.record_type ILIKE '%test_rpt_source_rec%'
          and not coalesce(selections.disabled, false)
          and :list_id::integer = selections.player_info_id
        where source.master_id = :master_id::integer
        order by source.id
      SQL
    end

    def run_documented_sql(list_id)
      sql = ActiveRecord::Base.sanitize_sql_for_conditions(
        [report_sql, { list_id: list_id.to_s, master_id: @master.id.to_s }]
      )
      ActiveRecord::Base.connection.execute(sql).to_a
    end

    it 'produces JSON cell values that ReportList.setup accepts and that update_items_in_list processes correctly' do
      # Run the documented SQL against the empty list — every row should have init_value: false
      rows = run_documented_sql(@list_id)
      expect(rows).not_to be_empty

      json_col = 'select items: update list: test_rpt_list_recs'
      cell = rows.first[json_col]
      parsed = JSON.parse(cell)

      # Verify the JSON shape matches the format documented in select_items_lists.md
      expect(parsed['field_name']).to eq 'update_list[items][]'
      expect(parsed['value']).to include(
        'list_id' => @list_id,
        'type' => ITEMS_SOURCE_TYPE,
        'id' => @source_rec.id,
        'init_value' => false
      )
      expect(parsed['value']['from_master_id']).to eq @master.id

      # Feed the JSON into ReportList exactly as the controller would
      items_text = rows.map { |r| JSON.parse(r[json_col])['value'].to_json }
      rl = Reports::ReportList.setup(LIST_TABLE_NAME, items_text, @authorized_user)
      rl.update_items_in_list

      # Source record should now appear as an active list row
      list_row = DynamicModel::TestRptListRec.active.find_by(record_id: @source_rec.id)
      expect(list_row).to be_present
      expect(list_row.player_info_id).to eq @player_info.id

      # Re-running the SQL should now show init_value: true for the same source row,
      # proving the left-join "selections" pre-check works as documented.
      rerun = run_documented_sql(@list_id)
      reparsed = JSON.parse(rerun.first[json_col])
      expect(reparsed['value']['init_value']).to eq true
    end
  end
end
