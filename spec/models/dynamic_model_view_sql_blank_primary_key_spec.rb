# frozen_string_literal: true

require 'rails_helper'

# Regression tests for issue #1304.
#
# A DynamicModel defined with `view_sql` does not have an underlying database
# view at the time the DynamicModel record is first created (the view is only
# created afterwards, by the migration generated in an `after_create` hook).
# Because `DynamicModel#set_keys_from_columns` only runs `before_create` and
# bails out when the view doesn't exist yet, `primary_key_name` can be left
# blank indefinitely.
#
# Previously, the generated implementation class's `primary_key_name` class
# method did not guard against this blank value (unlike `foreign_key_name`,
# which already defaulted to `nil`), so `definition.primary_key_name.to_sym`
# raised `NoMethodError: undefined method 'to_sym' for nil` while generating
# the implementation class (via `after_save :check_implementation_class`),
# and - if a blank string was stored instead - produced the empty `:""`
# symbol, which was passed as the `:primary_key` option to the class's
# `belongs_to :master` association, causing Postgres to reject the resulting
# SQL with `PG::SyntaxError: zero-length delimited identifier` whenever
# `master` was loaded (e.g. via `UserHandler#current_user=`, as triggered by
# `handle_record_batch_trigger` / `trigger_batch_now`).
RSpec.describe 'Dynamic model view_sql with blank primary_key_name', type: :model do
  include ModelSupport
  include MasterDataSupport

  # The dynamic model/view must be created outside the per-example transaction
  # (before(:all), like the existing 'dynamic models with foreign key as
  # master_id' spec does), otherwise the migration - which runs in a separate
  # thread/connection - deadlocks against the example's open transaction.
  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    @create_error = nil

    begin
      @dm = DynamicModel.create!(
        current_admin: @admin,
        name: 'test blank pk view',
        table_name: 'test_blank_pk_views',
        category: :test,
        schema_name: 'dynamic_test',
        foreign_key_name: 'master_id',
        options: <<~YAML
          _configurations:
            view_sql: |
              select
                id,
                master_id,
                first_name,
                last_name
              from player_infos

          default:
            label: Default
            fields:
              - first_name
              - last_name
            batch_trigger:
              on_record: {}
        YAML
      )
      @dm.current_admin = @admin
      @dm.update_tracker_events
    rescue StandardError => e
      @create_error = e
    end
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :each do
    create_user
  end

  it 'creates a view_sql dynamic model without raising, even though primary_key_name is blank' do
    expect(@create_error).to be_nil
  end

  it 'loads the master association and runs trigger_batch_now without raising PG::SyntaxError' do
    raise "Dynamic model setup failed: #{@create_error}" if @create_error

    dm = DynamicModel.find(@dm.id)

    create_player_info(first_name: 'Blank', last_name: 'PkTest')
    master = @master

    record = dm.implementation_class.find_by(master_id: master.id)
    expect(record).not_to be_nil

    expect { record.master }.not_to raise_error
    expect(record.master).to eq master

    expect { dm.implementation_class.trigger_batch_now(alt_user: @user) }.not_to raise_error
  end
end
