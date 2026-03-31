# frozen_string_literal: true

# Tests for EditFields::SelectFieldHandler sort_order option (Issue #217)
#
# The sort_order option allows configuring how select_record_from_table_*
# and related field types sort their results. By default, results are sorted
# by the first label attribute ascending. The new sort_order option supports:
#   - "label asc" (default behavior)
#   - "label desc" (label descending)
#   - "value asc" (value ascending)
#   - "value desc" (value descending)
#
# Two code paths are tested:
#   1. list_for_defined_attributes - when label_attr and value_attr are named
#      database columns (not :data)
#   2. list_for_complex_attributes - when label_attr or value_attr is :data,
#      requiring in-memory sorting of dynamically computed attributes

require 'rails_helper'

RSpec.describe EditFields::SelectFieldHandler, type: :model do
  include ModelSupport
  include PlayerContactSupport
  include TestFieldsDmSupport

  before(:all) do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    create_user
    create_master
    setup_fields_dm
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', false)
  end

  let(:form_object_instance) do
    DynamicModel::TestWithIdRec.new(master: @master, current_user: @user)
  end

  describe '.list_record_data_for_select with defined attributes (list_for_defined_attributes path)' do
    let(:common_args) do
      {
        value_attr: :value,
        label_attr: :name,
        no_assoc: true
      }
    end

    it 'sorts by label ascending by default when no sort_order is provided' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args
      )

      labels = results.map(&:first)
      expect(labels).to eq(['test name 1', 'test name 2', 'test name 3'])
    end

    it 'sorts by value ascending when sort_order is "value asc"' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args,
        sort_order: 'value asc'
      )

      values = results.map(&:last)
      expect(values).to eq(['test value 1', 'test value 2', 'test value 3'])
    end

    it 'sorts by value descending when sort_order is "value desc"' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args,
        sort_order: 'value desc'
      )

      values = results.map(&:last)
      expect(values).to eq(['test value 3', 'test value 2', 'test value 1'])
    end

    it 'sorts by label descending when sort_order is "label desc"' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args,
        sort_order: 'label desc'
      )

      labels = results.map(&:first)
      expect(labels).to eq(['test name 3', 'test name 2', 'test name 1'])
    end

    it 'sorts by label ascending when sort_order is "label asc" (explicit default)' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args,
        sort_order: 'label asc'
      )

      labels = results.map(&:first)
      expect(labels).to eq(['test name 1', 'test name 2', 'test name 3'])
    end
  end

  describe '.list_record_data_for_select with complex attributes (list_for_complex_attributes path)' do
    let(:common_args) do
      {
        value_attr: :data,
        label_attr: :data,
        no_assoc: true
      }
    end

    it 'sorts by label ascending by default when no sort_order is provided' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args
      )

      labels = results.map(&:first)
      expect(labels).to eq(labels.sort)
    end

    it 'sorts by label descending when sort_order is "label desc"' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args,
        sort_order: 'label desc'
      )

      labels = results.map(&:first)
      expect(labels).to eq(labels.sort.reverse)
    end

    it 'sorts by value descending when sort_order is "value desc"' do
      _human_name, results = described_class.list_record_data_for_select(
        form_object_instance, 'test_with_id_recs',
        **common_args,
        sort_order: 'value desc'
      )

      values = results.map(&:last)
      expect(values).to eq(values.sort.reverse)
    end
  end
end
