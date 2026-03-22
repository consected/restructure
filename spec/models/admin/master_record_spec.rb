# frozen_string_literal: true

# Tests for Admin::MasterRecord presenter class (issue #930)
#
# Admin::MasterRecord is a read-only presenter that wraps the masters table
# and the standard Rails models associated with it (player_infos, pro_infos, etc.).
# It drives the "Master Records" admin page under the Definitions section.
#
# These tests verify:
# - .all returns the correct set including masters table and models in order
# - .find returns the correct item by (1-based) position id
# - Each record exposes name, table_name, resource_name and model_class
# - #fields returns the column list from the underlying model class
# - Master metadata methods (crosswalk_attrs, readonly_attrs, TemporaryMasterIds)
#   are available for rendering the masters table details

require 'rails_helper'

RSpec.describe Admin::MasterRecord, type: :model do
  include ModelSupport

  describe '.all' do
    it 'returns exactly 7 entries (masters table + 6 standard models)' do
      records = Admin::MasterRecord.all
      expect(records.length).to eq 7
    end

    it 'returns masters as the first entry' do
      first = Admin::MasterRecord.all.first
      expect(first.table_name).to eq 'masters'
    end

    it 'returns player_infos as the second entry (driven by DefaultSubjectInfoTableName)' do
      second = Admin::MasterRecord.all[1]
      expect(second.table_name).to eq Settings::DefaultSubjectInfoTableName
    end

    it 'returns pro_infos as the third entry (driven by DefaultSecondaryInfoTableName)' do
      third = Admin::MasterRecord.all[2]
      expect(third.table_name).to eq Settings::DefaultSecondaryInfoTableName
    end

    it 'returns player_contacts as the fourth entry (driven by DefaultContactInfoTableName)' do
      fourth = Admin::MasterRecord.all[3]
      expect(fourth.table_name).to eq Settings::DefaultContactInfoTableName
    end

    it 'returns addresses as the fifth entry (driven by DefaultAddressInfoTableName)' do
      fifth = Admin::MasterRecord.all[4]
      expect(fifth.table_name).to eq Settings::DefaultAddressInfoTableName
    end

    it 'returns trackers as the sixth entry' do
      sixth = Admin::MasterRecord.all[5]
      expect(sixth.table_name).to eq 'trackers'
    end

    it 'returns tracker_histories as the seventh entry' do
      seventh = Admin::MasterRecord.all[6]
      expect(seventh.table_name).to eq 'tracker_histories'
    end

    it 'assigns sequential integer ids starting at 1' do
      ids = Admin::MasterRecord.all.map(&:id)
      expect(ids).to eq [1, 2, 3, 4, 5, 6, 7]
    end
  end

  describe '.find' do
    it 'returns the correct record by id 1 (masters)' do
      record = Admin::MasterRecord.find(1)
      expect(record.table_name).to eq 'masters'
    end

    it 'returns the correct record by id 2 (player_infos)' do
      record = Admin::MasterRecord.find(2)
      expect(record.table_name).to eq Settings::DefaultSubjectInfoTableName
    end

    it 'returns the correct record by id 7 (tracker_histories)' do
      record = Admin::MasterRecord.find(7)
      expect(record.table_name).to eq 'tracker_histories'
    end

    it 'raises an error when id is out of range' do
      expect { Admin::MasterRecord.find(99) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#name' do
    it 'returns a humanized name for the record' do
      record = Admin::MasterRecord.find(1)
      expect(record.name).to be_present
      expect(record.name).to be_a String
    end
  end

  describe '#resource_name' do
    it 'returns the resource name string for masters' do
      record = Admin::MasterRecord.find(1)
      expect(record.resource_name).to eq 'masters'
    end

    it 'returns the resource name string for player_infos' do
      record = Admin::MasterRecord.find(2)
      expect(record.resource_name).to include('player_info')
    end
  end

  describe '#model_class' do
    it 'returns the Rails model class for masters' do
      record = Admin::MasterRecord.find(1)
      expect(record.model_class).to eq Master
      expect(record.model_class).to be < ActiveRecord::Base
    end

    it 'returns the Rails model class for player_infos' do
      record = Admin::MasterRecord.find(2)
      expect(record.model_class).to be < ActiveRecord::Base
    end

    it 'returns a class that has column definitions' do
      Admin::MasterRecord.all.each do |record|
        expect(record.model_class.columns).to be_an Array
        expect(record.model_class.columns).not_to be_empty
      end
    end
  end

  describe '#fields' do
    it 'returns an array of ActiveRecord column objects' do
      record = Admin::MasterRecord.find(1)
      expect(record.fields).to be_an Array
      expect(record.fields).not_to be_empty
    end

    it 'includes an id column for every standard model' do
      Admin::MasterRecord.all.each do |record|
        column_names = record.fields.map(&:name)
        expect(column_names).to include('id'), "Expected #{record.table_name} to have an id column"
      end
    end
  end

  describe '#persisted?' do
    it 'returns true so Rails URL helpers work correctly' do
      record = Admin::MasterRecord.find(1)
      expect(record.persisted?).to be true
    end
  end

  describe 'API support methods' do
    describe '#table_or_view_ready?' do
      it 'returns true when the implementation class is defined' do
        record = Admin::MasterRecord.find(1)
        expect(record.table_or_view_ready?).to be true
      end
    end

    describe '#table_columns' do
      it 'returns column objects (same as #fields)' do
        record = Admin::MasterRecord.find(1)
        columns = record.table_columns
        expect(columns).to be_an Array
        expect(columns).not_to be_empty
        # table_columns returns the same ActiveRecord column objects as fields
        column_names = columns.map(&:name)
        expect(column_names).to include('id')
      end
    end

    describe '#base_route_segments' do
      it 'returns the table name as a string' do
        record = Admin::MasterRecord.find(1)
        segments = record.base_route_segments
        expect(segments).to be_a String
        expect(segments).to eq(record.table_name)
      end
    end

    describe '#foreign_key_name' do
      it 'returns master_id for standard models' do
        record = Admin::MasterRecord.find(1)
        expect(record.foreign_key_name).to eq 'master_id'
      end
    end

    describe '#est_record_count' do
      it 'returns an integer count of records' do
        record = Admin::MasterRecord.find(1)
        count = record.est_record_count
        expect(count).to be_an Integer
        expect(count).to be >= 0
      end
    end
  end

  describe 'Master metadata for the informational header' do
    it 'Master.crosswalk_attrs returns the expected crosswalk fields' do
      attrs = Master.crosswalk_attrs
      expect(attrs).to be_an Array
      expect(attrs).not_to be_empty
      expect(attrs).not_to include(:id, :user_id, :created_at, :updated_at)
    end

    it 'Master.readonly_attrs returns the fields that are read-only in the UI' do
      attrs = Master.readonly_attrs
      expect(attrs).to be_an Array
      expect(attrs).not_to be_empty
    end

    it 'Master::TemporaryMasterIds contains negative integer IDs' do
      expect(Master::TemporaryMasterIds).to be_an Array
      expect(Master::TemporaryMasterIds).not_to be_empty
      expect(Master::TemporaryMasterIds.all? { |id| id.is_a?(Integer) && id < 0 }).to be true
    end
  end
end
