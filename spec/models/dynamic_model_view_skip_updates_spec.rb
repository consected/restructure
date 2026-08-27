# frozen_string_literal: true

require 'rails_helper'

# Regression / feature tests for issue #1203.
#
# A dynamic model view_sql that joins more than one table is not "simply
# updatable" by Postgres, so an UPDATE against it fails unless an INSTEAD OF
# trigger is installed. Setting `_configurations: view_skip_updates: true`
# should install a dummy INSTEAD OF INSERT/UPDATE trigger (ml_app.view_skip_updates)
# on the view, allowing the update to appear to succeed so save triggers can fire.
# Without it (the default), the same kind of joined view remains non-updatable.
RSpec.describe 'Dynamic model view_skip_updates', type: :model do
  include ModelSupport
  include MasterDataSupport

  def view_sql
    <<~SQL
      select
        pi.id,
        pi.master_id,
        pi.first_name,
        pi.last_name,
        m.id as master_ref_id
      from player_infos pi
      inner join masters m on m.id = pi.master_id
    SQL
  end

  def options_yaml(view_skip_updates:)
    <<~YAML
      _configurations:
        view_sql: |
          #{view_sql.gsub("\n", "\n          ")}
        view_skip_updates: #{view_skip_updates}
    YAML
  end

  # Migrations run on a separate connection/thread, so the dynamic models and their
  # views must be created outside the per-example transaction (before(:all)), matching
  # the pattern used by other view_sql specs - otherwise the migration deadlocks
  # against the example's open transaction. Two separate dynamic models (rather than
  # updating one mid-spec) are used to compare true/false behavior.
  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    @create_error = nil

    begin
      @dm_skip = DynamicModel.create!(
        current_admin: @admin,
        name: 'test skip update view',
        table_name: 'test_skip_update_views',
        category: :test,
        schema_name: 'dynamic_test',
        primary_key_name: :id,
        foreign_key_name: :master_id,
        options: options_yaml(view_skip_updates: true)
      )
      @dm_skip.current_admin = @admin
      @dm_skip.update_tracker_events

      @dm_no_skip = DynamicModel.create!(
        current_admin: @admin,
        name: 'test no skip update view',
        table_name: 'test_no_skip_update_views',
        category: :test,
        schema_name: 'dynamic_test',
        primary_key_name: :id,
        foreign_key_name: :master_id,
        options: options_yaml(view_skip_updates: false)
      )
      @dm_no_skip.current_admin = @admin
      @dm_no_skip.update_tracker_events

      # Covers toggling view_skip_updates on an EXISTING view-backed model while its
      # view_sql text stays the same (the skip_view_recreate optimization path) - done
      # here in before(:all), not in an `it` block, since the update's migration runs on
      # a separate thread/connection that would otherwise deadlock against the per-example
      # transaction.
      @dm_toggle = DynamicModel.create!(
        current_admin: @admin,
        name: 'test toggle skip update view',
        table_name: 'test_toggle_skip_update_views',
        category: :test,
        schema_name: 'dynamic_test',
        primary_key_name: :id,
        foreign_key_name: :master_id,
        options: options_yaml(view_skip_updates: true)
      )
      @dm_toggle.current_admin = @admin
      @dm_toggle.update_tracker_events

      @dm_toggle.instance_variable_set(:@ran_migration, false)
      @dm_toggle.instance_variable_set(:@migration_generator, nil)
      @dm_toggle.current_admin = @admin
      @dm_toggle.update!(options: options_yaml(view_skip_updates: false))
      @dm_toggle.update_tracker_events
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

  def trigger_exists?(table_name)
    ActiveRecord::Base.connection.select_value(
      "select count(*) from pg_trigger where tgname = 'view_skip_updates_trig' " \
      "and tgrelid = 'dynamic_test.#{table_name}'::regclass"
    ).to_i.positive?
  end

  it 'creates both dynamic model views without raising' do
    expect(@create_error).to be_nil
  end

  it 'installs the view_skip_updates INSTEAD OF trigger only when configured true' do
    raise "Dynamic model setup failed: #{@create_error}" if @create_error

    expect(trigger_exists?('test_skip_update_views')).to be true
    expect(trigger_exists?('test_no_skip_update_views')).to be false
  end

  it 'allows an UPDATE against the (naturally non-updatable) joined view when view_skip_updates is true' do
    raise "Dynamic model setup failed: #{@create_error}" if @create_error

    create_player_info(first_name: 'Skip', last_name: 'Updates')

    expect do
      ActiveRecord::Base.connection.execute(
        "update dynamic_test.test_skip_update_views set first_name = 'Changed' where id = #{@player_info.id}"
      )
    end.not_to raise_error
  end

  it 'still fails to UPDATE the same kind of joined view when view_skip_updates is not set' do
    raise "Dynamic model setup failed: #{@create_error}" if @create_error

    create_player_info(first_name: 'No', last_name: 'Skip')

    expect do
      ActiveRecord::Base.connection.execute(
        "update dynamic_test.test_no_skip_update_views set first_name = 'Changed' where id = #{@player_info.id}"
      )
    end.to raise_error(ActiveRecord::StatementInvalid, /updatable/i)
  end

  it 'drops the trigger and stops allowing UPDATE once view_skip_updates is toggled off on an existing model' do
    raise "Dynamic model setup failed: #{@create_error}" if @create_error

    expect(trigger_exists?('test_toggle_skip_update_views')).to be false

    create_player_info(first_name: 'Toggled', last_name: 'Off')

    expect do
      ActiveRecord::Base.connection.execute(
        "update dynamic_test.test_toggle_skip_update_views set first_name = 'Changed' where id = #{@player_info.id}"
      )
    end.to raise_error(ActiveRecord::StatementInvalid, /updatable/i)
  end
end
