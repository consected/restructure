# frozen_string_literal: true

require 'rails_helper'
require 'timeout'

# Regression coverage for thread-safe version memoization and historical definition IDs.
AlNameGenTestVh = 'Gen Test ELT VH'
# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Definition versioning', type: :model do
  include ModelSupport
  include PlayerContactSupport

  def al_name
    AlNameGenTestVh
  end

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTestVh, 'elt_vh', 'player_contact'
  end

  before :each do
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)

    @activity_log = al = ActivityLog.active.where(name: al_name).first
    @working_data = '(111)222-3333 ext 7654321'

    raise "Activity Log #{al_name} not set up" if @activity_log.nil?

    @activity_log.current_admin = @admin

    @activity_log.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1 v1
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v1
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    @orig_num_versions = @activity_log.all_versions.length
    c1 = @activity_log.option_configs[0]
    c2 = @activity_log.option_configs[1]
    setup_access al.resource_name, resource_type: :table, user: @user
    setup_access c1.resource_name, resource_type: :activity_log_type, user: @user
    setup_access c2.resource_name, resource_type: :activity_log_type, user: @user

    @player_contact.current_user = @user
  end

  def latest_history_item
    qres = Admin::MigrationGenerator.connection.execute <<~END_SQL
      select * from activity_log_history
      order by id desc
      limit 1
    END_SQL

    qres.first.to_h
  end

  def all_versions
    @activity_log.all_versions
  end

  it 'returns the latest history id for the live definition without instantiating versions (issue #1481)' do
    latest_version_id = @activity_log.all_versions_query(limit: 1).first.fetch('id').to_i
    expect(@activity_log).not_to receive(:all_versions)

    expect(@activity_log.current_def_version).to eq(latest_version_id)
  end

  it 'keeps the live definition version nil while exposing its history id as a template token' do
    expect(@activity_log.def_version).to be_nil
    expect(@activity_log.current_def_version).to eq(@activity_log.all_versions_query(limit: 1).first.fetch('id').to_i)
    expect(@activity_log.template_version_token).to eq(@activity_log.current_def_version)
    expect(Dynamic::TemplateVersionTokens.resource_token(@activity_log)).to eq(@activity_log.current_def_version)
    expect(@activity_log.versioned(Time.current + 100.years)).to be_nil

    historical_definition = @activity_log.all_versions.last
    expect(historical_definition.def_version).to eq(@activity_log.all_versions_query.last.fetch('id').to_i)
    expect(Dynamic::TemplateVersionTokens.resource_token(historical_definition)).to eq(historical_definition.def_version)
  end

  it 'uses the live template token and historical history id for record state slots' do
    record_class = @activity_log.implementation_class
    live_record = record_class.allocate
    allow(live_record).to receive(:def_version).and_return(nil)
    allow(live_record).to receive(:current_definition).and_return(@activity_log)
    allow(live_record).to receive(:versioned_definition).and_return(@activity_log)

    expect(live_record.vdef_version).to eq("v#{@activity_log.template_version_token}")
    expect(@player_contact.vdef_version).to eq('v0')

    historical_definition = @activity_log.all_versions.last
    historical_record = record_class.allocate
    allow(historical_record).to receive(:versioned_definition).and_return(historical_definition)

    expect(historical_record.vdef_version).to eq("v#{historical_definition.def_version}")
  end

  it 're-resolves a persisted record when its memoized definition is live' do
    definition = @activity_log
    historical_definition = definition.all_versions.last
    record = definition.implementation_class.allocate
    allow(record).to receive(:id).and_return(-1)
    allow(record).to receive(:persisted?).and_return(true)
    allow(record).to receive(:created_at).and_return(Time.current)
    allow(record).to receive(:current_definition).and_return(definition)
    allow(definition).to receive(:use_current_version).and_return(false)
    allow(record.class).to receive(:definition).and_return(definition)
    allow(definition).to receive(:versioned).and_return(nil, historical_definition)

    expect(record).to be_persisted
    expect(record.versioned_definition).to equal(definition)
    expect(record.versioned_definition).to equal(historical_definition)
    expect(definition).to have_received(:versioned).twice
  end

  it 'uses v0 for non-versioned models and definitions with no history' do
    expect(@player_contact.def_version).to be_nil
    expect(@player_contact.vdef_version).to eq('v0')
    expect(ActivityLog.new.current_def_version).to be_nil
    expect(Dynamic::TemplateVersionTokens.resource_token(@player_contact)).to eq(0)
    expect(Dynamic::TemplateVersionTokens.resource_token(ActivityLog.new)).to eq(0)
  end

  it 'derives a stable token from updated_at when a definition has no history rows' do
    definition = ActivityLog.new
    updated_at = Time.utc(2026, 1, 1, 0, 0, 0, 123_456)
    allow(definition).to receive(:id).and_return(1)
    allow(definition).to receive(:updated_at).and_return(updated_at)
    allow(definition).to receive(:all_versions_query).with(limit: 1).and_return([])
    allow(definition).to receive(:uses_current_definition_version?).and_return(false)

    expected_token = (updated_at.to_r * 1_000_000).to_i
    expect(definition.template_version_token).to eq(expected_token)
    expect(definition.template_version_token).to eq(expected_token)
  end

  it 'keeps live template tokens current while definition versioning is disabled' do
    previous_setting = Settings::DisableVDef
    change_setting('DisableVDef', true)
    definition = ActivityLog.find(@activity_log.id)
    latest_history_id = definition.all_versions_query(limit: 1).first.fetch('id').to_i

    expect(definition.def_version).to be_nil
    expect(definition.current_def_version).to eq(latest_history_id)
    expect(definition.template_version_token).to eq(latest_history_id)
    expect(definition.versioned(Time.current)).to equal(definition)
  ensure
    change_setting('DisableVDef', previous_setting)
  end

  it 'clears the current version memo after save and touch' do
    previous_setting = Settings::DisableVDef
    change_setting('DisableVDef', false)
    definition = ActivityLog.find(@activity_log.id)
    definition.current_admin = @admin
    allow(definition).to receive(:all_versions_query).and_call_original
    definition.current_def_version
    definition.current_def_version
    expect(definition).to have_received(:all_versions_query).with(limit: 1).once

    definition.touch
    definition.current_def_version
    expect(definition).to have_received(:all_versions_query).with(limit: 1).twice

    definition.extra_log_types = "#{definition.extra_log_types}\n# memo invalidation"
    definition.save!
    definition.current_def_version
    expect(definition).to have_received(:all_versions_query).with(limit: 1).thrice
  ensure
    change_setting('DisableVDef', previous_setting)
  end

  it 'changes the activity-log item-type token when rec_type changes without changing maximum id' do
    item_type = @activity_log.item_type
    previous_maximum_id = ActivityLog.where(item_type:).maximum(:id)
    previous_token = Dynamic::TemplateVersionTokens.activity_log_item_type_token(item_type)

    @activity_log.update_columns(rec_type: 'phone', updated_at: Time.current)

    expect(ActivityLog.where(item_type:).maximum(:id)).to eq(previous_maximum_id)
    expect(Dynamic::TemplateVersionTokens.activity_log_item_type_token(item_type)).not_to eq(previous_token)

    @activity_log.reload
    @activity_log.current_admin = @admin
    @activity_log.disable!(@admin)

    expect(ActivityLog.where(item_type:).maximum(:id)).to eq(previous_maximum_id)
    expect(Dynamic::TemplateVersionTokens.activity_log_item_type_token(item_type)).not_to eq(previous_token)
  end

  it 'does not lose cached versions when invalidated during a lookup' do
    previous_setting = Settings::DisableVDef
    change_setting('DisableVDef', false)

    versions_key = @activity_log.send(:versions_memo_key)
    cached_versions = @activity_log.all_versions
    read_started = Queue.new
    continue_read = Queue.new
    memo_class = Class.new(Hash) do
      attr_accessor :blocked_key, :read_started, :continue_read

      def [](key)
        value = super
        if key == blocked_key && !@has_blocked_read
          @has_blocked_read = true
          read_started << true
          continue_read.pop
        end
        value
      end
    end
    memo = memo_class.new
    memo[versions_key] = cached_versions
    memo.blocked_key = versions_key
    memo.read_started = read_started
    memo.continue_read = continue_read
    ActivityLog.all_versions_memo = memo
    allow(@activity_log).to receive(:all_versions_query).and_return([])

    reader = Thread.new do
      @activity_log.versioned(Time.current + 100.years)
      @activity_log.all_versions
    end

    Timeout.timeout(5) { read_started.pop }
    clear_started = Queue.new
    clearer = Thread.new do
      clear_started << true
      ActivityLog.clear_all_versions_memo
    end
    Timeout.timeout(5) { clear_started.pop }
    Timeout.timeout(5) { Thread.pass until clearer.status == 'sleep' }
    continue_read << true

    expect(Timeout.timeout(5) { reader.value }).to be_a(Array)
    Timeout.timeout(5) { clearer.value }
  ensure
    continue_read << true if continue_read
    [reader, clearer].compact.each do |thread|
      thread.kill if thread.alive?
      thread.join
    end
    ActivityLog.clear_all_versions_memo
    change_setting('DisableVDef', previous_setting) unless previous_setting.nil?
  end

  it 'does not cache a version list computed before memo invalidation' do
    versions_key = @activity_log.send(:versions_memo_key)
    history_id_attribute = @activity_log.send(:history_id_attr)
    history_row = lambda do |version_id|
      {
        'id' => version_id,
        history_id_attribute => @activity_log.id,
        'created_at' => Time.current,
        'updated_at' => Time.current
      }
    end

    continue_query = nil
    reader = nil
    [
      ['process-wide clear', -> { ActivityLog.clear_all_versions_memo }],
      ['record reset', -> { @activity_log.send(:reset_all_versions) }]
    ].each_with_index do |(invalidation_name, invalidate), index|
      query_started = Queue.new
      continue_query = Queue.new
      query_count = 0
      stale_version_id = 90_001 + (index * 2)
      fresh_version_id = stale_version_id + 1

      allow(@activity_log).to receive(:all_versions_query) do
        query_count += 1
        if query_count == 1
          query_started << true
          continue_query.pop
          [history_row.call(stale_version_id)]
        else
          [history_row.call(fresh_version_id)]
        end
      end
      ActivityLog.clear_all_versions_memo

      reader = Thread.new { @activity_log.all_versions }
      Timeout.timeout(5) { query_started.pop }
      invalidate.call
      continue_query << true

      stale_versions = Timeout.timeout(5) { reader.value }
      expect(stale_versions.first.def_version).to eq(stale_version_id)
      expect(ActivityLog.all_versions_memo).not_to have_key(versions_key),
        "expected #{invalidation_name} to prevent caching the in-flight result"
      expect(@activity_log.all_versions.first.def_version).to eq(fresh_version_id)
    end
  ensure
    continue_query << true if continue_query
    reader&.kill if reader&.alive?
    reader&.join
    ActivityLog.clear_all_versions_memo
  end

  it 'resolves an older record to its historical version after another worker edits the definition' do
    ActivityLog.up_to_date?
    stale_versions = @activity_log.all_versions
    stale_update_marker = ActivityLog.instance_variable_get(:@prev_latest_update)
    record_created_at = Time.current
    sleep 2

    worker_definition = ActivityLog.find(@activity_log.id)
    worker_definition.current_admin = @admin
    worker_definition.extra_log_types = "#{worker_definition.extra_log_types}\n# edited on another worker"
    worker_definition.save!

    # A save on this process updates its own markers, so restore what a second worker would still hold
    ActivityLog.all_versions_memo = ActivityLog.all_versions_memo.merge(
      @activity_log.send(:versions_memo_key) => stale_versions
    )
    ActivityLog.instance_variable_set(:@prev_latest_update, stale_update_marker)
    ActivityLog.refresh_outdated

    historical = @activity_log.versioned(record_created_at)

    expect(historical).not_to be_nil
    expect(historical.def_version).to eq(@activity_log.all_versions_query.second.fetch('id').to_i)
  end

  it 'manages definition versions' do
    v1 = latest_history_item
    at_1 = DateTime.now
    expect(all_versions.length).to eq @orig_num_versions
    sleep 2

    @activity_log.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1 v2
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v2
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    v2 = latest_history_item
    at_2 = DateTime.now
    expect(all_versions.length).to eq(@orig_num_versions + 1)

    c1 = @activity_log.option_configs[0]
    expect(c1.label).to eq 'Step 1 v2'

    c1 = @activity_log.option_configs[1]
    expect(c1.label).to eq 'Step 2 v2'

    sleep 2
    expect(all_versions.length).to eq(@orig_num_versions + 1)

    # Save an instance using v2
    @player_contact.current_user = @user
    al_v2 = @player_contact.activity_log__player_contact_elt_vhs.create!(select_call_direction: 'from staff',
                                                                         extra_log_type: 'step_2',
                                                                         select_who: 'abc',
                                                                         master: @player_contact.master)

    new_al = ActivityLog::PlayerContactEltVh.find(al_v2.id)
    c1 = new_al.versioned_definition.option_configs[1]
    expect(c1.label).to eq 'Step 2 v2'

    sleep 2

    ##### Add a new version

    @activity_log.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1 v3
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v3
        fields:
          - select_call_direction
          - select_who

      step_3:
        label: Step 3 v3
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    v3 = latest_history_item
    at_3 = DateTime.now

    c1 = @activity_log.option_configs[0]
    expect(c1.label).to eq 'Step 1 v3'

    c1 = @activity_log.option_configs[1]
    expect(c1.label).to eq 'Step 2 v3'

    c1 = @activity_log.option_configs[2]
    expect(c1.label).to eq 'Step 3 v3'
    sleep 2

    # al_v3 = @player_contact.activity_log__player_contact_elt_vhs.create!(select_call_direction: 'from staff',
    #                                                                   extra_log_type: 'step_3',
    #                                                                   select_who: 'abc')

    expect(all_versions.length).to eq(@orig_num_versions + 2)

    all_versions
    @activity_log.versioned(at_1)
    expect(@activity_log.versioned(at_1)).to eq all_versions[2]
    expect(@activity_log.versioned(at_2)).to eq all_versions[1]
    expect(@activity_log.versioned(at_3)).to be nil # since it is the current version and this is what is returned

    expect(@activity_log.versioned(DateTime.now + 99.years)).to be nil # simulates *use_def_version_at*

    new_al = ActivityLog::PlayerContactEltVh.find(al_v2.id)
    c1 = new_al.versioned_definition.option_configs[1]
    expect(c1.label).to eq 'Step 2 v2'

    ##### Force use of the current version

    sleep 2

    @activity_log.extra_log_types = <<~END_DEF
      _configurations:
        use_current_version: true

      step_1:
        label: Step 1 v4
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2 v4
        fields:
          - select_call_direction
          - select_who

      step_3:
        label: Step 3 v4
        fields:
          - select_call_direction
          - select_who
    END_DEF

    @activity_log.save!
    v4 = latest_history_item
    at_4 = DateTime.now

    c1 = @activity_log.option_configs[0]
    expect(c1.label).to eq 'Step 1 v4'

    c1 = @activity_log.option_configs[1]
    expect(c1.label).to eq 'Step 2 v4'

    c1 = @activity_log.option_configs[2]
    expect(c1.label).to eq 'Step 3 v4'
    sleep 2

    # al_v3 = @player_contact.activity_log__player_contact_elt_vhs.create!(select_call_direction: 'from staff',
    #                                                                   extra_log_type: 'step_3',
    #                                                                   select_who: 'abc')

    expect(all_versions.length).to eq(@orig_num_versions + 3)

    all_versions
    @activity_log.versioned(at_1)
    expect(@activity_log.versioned(at_1)).to eq all_versions[3]
    expect(@activity_log.versioned(at_2)).to eq all_versions[2]
    expect(@activity_log.versioned(at_3)).to be all_versions[1]
    expect(@activity_log.versioned(at_4)).to be nil # since it is the current version and this is what is returned

    # Instance should be using definition v4 - since use_current_version is set
    new_al = ActivityLog::PlayerContactEltVh.find(al_v2.id)
    c1 = new_al.versioned_definition.option_configs[1]
    expect(c1.label).to eq 'Step 2 v4'

    al_v4 = @player_contact.activity_log__player_contact_elt_vhs.create!(select_call_direction: 'from staff',
                                                                         extra_log_type: 'step_2',
                                                                         select_who: 'abc',
                                                                         master: @player_contact.master)

    c4 = al_v4.versioned_definition.option_configs[1]
    expect(c4.label).to eq 'Step 2 v4'
  end

  # Issue #1343 - the admin versions panel must not load unbounded history for
  # definitions with very large numbers of versions (which can time out behind
  # a proxy). Rows are inserted directly via SQL (rather than repeated saves)
  # so a large history can be simulated quickly.
  describe 'admin panel version display limiting (issue #1343)' do
    def insert_history_rows(count)
      count.times do |i|
        Admin::MigrationGenerator.connection.execute <<~SQL
          insert into activity_log_history (activity_log_id, name, created_at, updated_at)
          values (
            #{@activity_log.id},
            'test_version_#{i}',
            now() - interval '#{count - i} minutes',
            now() - interval '#{count - i} minutes'
          )
        SQL
      end
    end

    it 'limits all_versions_query results to the most recent rows when a limit is given' do
      insert_history_rows(120)

      unlimited = @activity_log.all_versions_query
      limited = @activity_log.all_versions_query(limit: 100)

      expect(unlimited.length).to eq(@orig_num_versions + 120)
      expect(limited.length).to eq(100)
      expect(limited).to eq(unlimited.first(100))
    end

    it 'reports the full version count independent of any display limit' do
      insert_history_rows(120)

      expect(@activity_log.all_versions_count).to eq(@orig_num_versions + 120)
      expect(@activity_log.all_versions_query(limit: 50).length).to eq(50)
    end
  end
end
