# frozen_string_literal: true

require 'rails_helper'

# Issue #1406 repro: dynamic definition `_constants` are lost in `background` save
# trigger blocks.
#
# Root cause hypothesis (per issue discussion): `option_configs` on a definition
# object is memoized (`@option_configs ||= ...`) and only re-parsed when something
# explicitly calls `force_option_config_parse` (normally triggered by an `after_save`
# callback on the DEFINITION record itself). A long-running process (e.g. a
# background worker) that already loaded/parsed the definition BEFORE `_constants`
# (or a `_configurations: use_current_version` setting sourced from a shared config
# library) was added will keep using its stale, already-memoized `options_constants`
# forever, since nothing tells that specific in-memory object to re-parse just
# because the definition record was updated in a different object/process. The
# `after_initialize`-driven self-heal (`evaluate_active_values` -> `option_type_config`)
# does NOT help here because it only forces a parse when `@option_configs` is nil -
# a stale-but-already-parsed object short-circuits and keeps its outdated content.
#
# This spec reproduces that staleness deterministically within a single process by
# installing a definition object that was parsed BEFORE `_constants` existed as the
# class-level `ActivityLog.definition_cache` entry - exactly what a background worker
# process that booted before an admin added `_constants` would have.
RSpec.describe 'Issue #1406 - stale cached definition loses _constants in background job', type: :model do
  include ModelSupport
  include PlayerContactSupport
  include ActiveJob::TestHelper

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before :each do
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    @master = @player_contact.master
    expect(@master).not_to be nil

    al_def = ActivityLog.find_by(id: ActivityLog::PlayerContactPhone.definition.id)
    unless al_def
      SetupHelper.setup_al_gen_tests('Phone Log', nil, 'player_contact', rec_type: 'phone')
      al_def = ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').first
    end

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    # Version 1: no _constants defined yet - represents the config BEFORE an admin
    # added `_constants`.
    al_def.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1
        save_trigger:
          on_save:
            - log:
                message: 'Constant c1 = {{constants.c1}}'
            - background:
                - log:
                    message: 'Background Constant c1 = {{constants.c1}}'
    END_DEF

    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create,
                                                              user: @user
    al_def.add_master_association

    # Simulate a background worker process that booted and parsed this definition
    # BEFORE the admin added `_constants` below - its own in-memory copy has already
    # memoized `options_constants` as blank, and nothing will ever tell it to re-parse.
    @stale_worker_definition = ActivityLog.find(al_def.id)
    @stale_worker_definition.force_option_config_parse
  end

  it 'loses _constants in the background job when the cached definition was parsed before _constants existed' do
    al_def = ActivityLog::PlayerContactPhone.definition

    # Now an admin adds `_constants` - this updates and re-saves the definition
    # record, refreshing ITS OWN in-memory copy (`al_def`/`current_definition` as
    # seen by the current request), but not `@stale_worker_definition` above.
    al_def.extra_log_types = <<~END_DEF
      _constants:
        c1: val1

      step_1:
        label: Step 1
        save_trigger:
          on_save:
            - log:
                message: 'Constant c1 = {{constants.c1}}'
            - background:
                - log:
                    message: 'Background Constant c1 = {{constants.c1}}'
    END_DEF
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now + 1.second
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    logged_messages = []
    allow(Rails.logger).to receive(:info) { |msg| logged_messages << msg }

    @master.activity_log__player_contact_phones.create!(
      select_call_direction: 'to player',
      select_who: 'user',
      extra_log_type: 'step_1',
      player_contact: @player_contact,
      master: @master,
      current_user: @user
    )

    # Swap in the "stale worker" copy - as if this job were picked up by the
    # never-refreshed worker process.
    ActivityLog.definition_cache[al_def.id] = @stale_worker_definition

    perform_enqueued_jobs

    foreground_message = logged_messages.find { |m| m.include?('Constant c1') && !m.include?('Background') }
    background_message = logged_messages.find { |m| m.include?('Background Constant c1') }

    expect(foreground_message).to include('val1')
    expect(background_message).to include('val1')
  end

  # Confirms the fix also holds when the job actually round-trips through the
  # `delayed_job` ActiveJob adapter (YAML serialization to the delayed_jobs table
  # and back), rather than the in-process `:test` adapter used above.
  it 'loses _constants via the real delayed_job adapter too, and the fix corrects it' do
    al_def = ActivityLog::PlayerContactPhone.definition

    al_def.extra_log_types = <<~END_DEF
      _constants:
        c1: val1

      step_1:
        label: Step 1
        save_trigger:
          on_save:
            - log:
                message: 'Constant c1 = {{constants.c1}}'
            - background:
                - log:
                    message: 'Background Constant c1 = {{constants.c1}}'
    END_DEF
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now + 1.second
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    logged_messages = []
    allow(Rails.logger).to receive(:info) { |msg| logged_messages << msg }

    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :delayed_job
    original_delay_jobs = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true

    begin
      @master.activity_log__player_contact_phones.create!(
        select_call_direction: 'to player',
        select_who: 'user',
        extra_log_type: 'step_1',
        player_contact: @player_contact,
        master: @master,
        current_user: @user
      )

      ActivityLog.definition_cache[al_def.id] = @stale_worker_definition

      dj = Delayed::Job.where('handler LIKE ?', '%SaveTriggersBackgroundJob%').last
      expect(dj).not_to be nil

      dj.invoke_job
    ensure
      Delayed::Worker.delay_jobs = original_delay_jobs
      ActiveJob::Base.queue_adapter = original_adapter
    end

    background_message = logged_messages.find { |m| m.include?('Background Constant c1') }
    expect(background_message).to include('val1')
  end
end
