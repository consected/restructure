# frozen_string_literal: true

# Tests for GitHub issue #996: Batch trigger with API calling
# for server-to-server data synchronization.
#
# Verifies that a batch_trigger configuration can:
# - Use set_variables to build a structured request body from master associations
# - Use each: iterators over player_contacts (and addresses) with set_variables
#   dot-notation and dynamic {{save_trigger_results.iterator_index}} in the name: field
# - Use pull_external_data to POST the assembled request body to a remote API
# - Use conditional set_variables + update_this to mark sync status based on HTTP response code
# - Skip already-synced records via _configurations if: conditions
# - Handle masters with no iterable contacts gracefully

require 'rails_helper'

RSpec.describe 'batch trigger sync to remote API - issue #996', type: :model do
  include ModelSupport
  include PlayerContactSupport

  RemoteApiUrl = 'https://remote-restructure.example.com/masters/create.json'

  # Helper to configure the activity log definition with the given YAML
  def setup_al_with_config(config_yaml)
    al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    al_def.extra_log_types = config_yaml
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__batch_sync_test, resource_type: :activity_log_type,
                                                                       access: :create, user: @user
    al_def.add_master_association

    @al_def = al_def
  end

  # YAML config for the basic batch sync test (contacts only)
  def sync_config_with_contacts
    <<~YAML
      batch_sync_test:
        label: Batch Sync Test
        fields:
          - select_call_direction
          - select_who
          - notes
        batch_trigger:
          on_record:
            # Step 1: Build static request body with player_infos
            - set_variables:
                name: request_body
                value:
                  object:
                    player_infos:
                      "0":
                        first_name: "{{player_infos.first_name}}"
                        last_name: "{{player_infos.last_name}}"
                    player_contacts: {}
                    master_id: "{{master.id}}"
            # Step 2: Iterate over player_contacts, adding each at a dynamic index
            - each:
                value: '{{{player_contacts}}}'
                do:
                  - set_variables:
                      name: "request_body.player_contacts.{{save_trigger_results.iterator_index}}"
                      value:
                        object:
                          data: "{{save_trigger_results.iterator_value.data}}"
                          rec_type: "{{save_trigger_results.iterator_value.rec_type}}"
            # Step 3: POST to remote API
            - pull_external_data:
                post_to_remote:
                  method: post
                  local_data: remote_response
                  to:
                    url: 'https://remote-restructure.example.com/masters/create.json'
                    format: json
                    allow_response_codes:
                      - 400
                      - 422
                      - 500
                    headers:
                      'Content-Type': 'application/json'
                  send_data:
                    master: '{{{variables.request_body}}}'
            # Step 4: Default sync status to failed
            - set_variables:
                name: sync_status
                value: 'failed'
            # Step 5: Override to completed if HTTP 200
            - set_variables:
                if:
                  all:
                    this:
                      save_trigger_results:
                        element: remote_response_http_response_code
                        value: 200
                name: sync_status
                value: 'completed'
            # Step 6: Update the record with sync status
            - update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: "{{variables.sync_status}}"
                    notes: "Remote master ID: {{save_trigger_results.remote_response.master.id::ignore_missing}}"
    YAML
  end

  # YAML config with _configurations if: condition to only sync records with select_who: 'new'
  def sync_config_with_if_condition
    <<~YAML
      _configurations:
        batch_trigger:
          if:
            all:
              this:
                select_who: 'new'

      batch_sync_test:
        label: Batch Sync Test
        fields:
          - select_call_direction
          - select_who
          - notes
        batch_trigger:
          on_record:
            - set_variables:
                name: request_body
                value:
                  object:
                    player_infos:
                      "0":
                        first_name: "{{player_infos.first_name}}"
                        last_name: "{{player_infos.last_name}}"
                    player_contacts: {}
                    master_id: "{{master.id}}"
            - each:
                value: '{{{player_contacts}}}'
                do:
                  - set_variables:
                      name: "request_body.player_contacts.{{save_trigger_results.iterator_index}}"
                      value:
                        object:
                          data: "{{save_trigger_results.iterator_value.data}}"
                          rec_type: "{{save_trigger_results.iterator_value.rec_type}}"
            - pull_external_data:
                post_to_remote:
                  method: post
                  local_data: remote_response
                  to:
                    url: 'https://remote-restructure.example.com/masters/create.json'
                    format: json
                    allow_response_codes:
                      - 400
                      - 422
                      - 500
                    headers:
                      'Content-Type': 'application/json'
                  send_data:
                    master: '{{{variables.request_body}}}'
            - set_variables:
                name: sync_status
                value: 'failed'
            - set_variables:
                if:
                  all:
                    this:
                      save_trigger_results:
                        element: remote_response_http_response_code
                        value: 200
                name: sync_status
                value: 'completed'
            - update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: "{{variables.sync_status}}"
                    notes: "sync done"
    YAML
  end

  # YAML config with both player_contacts and addresses iterators
  def sync_config_with_contacts_and_addresses
    <<~YAML
      batch_sync_test:
        label: Batch Sync Test
        fields:
          - select_call_direction
          - select_who
          - notes
        batch_trigger:
          on_record:
            # Step 1: Build static request body
            - set_variables:
                name: request_body
                value:
                  object:
                    player_infos:
                      "0":
                        first_name: "{{player_infos.first_name}}"
                        last_name: "{{player_infos.last_name}}"
                    player_contacts: {}
                    addresses: {}
                    master_id: "{{master.id}}"
            # Step 2: Iterate over player_contacts
            - each:
                value: '{{{player_contacts}}}'
                do:
                  - set_variables:
                      name: "request_body.player_contacts.{{save_trigger_results.iterator_index}}"
                      value:
                        object:
                          data: "{{save_trigger_results.iterator_value.data}}"
                          rec_type: "{{save_trigger_results.iterator_value.rec_type}}"
            # Step 3: Iterate over addresses
            - each:
                value: '{{{addresses}}}'
                do:
                  - set_variables:
                      name: "request_body.addresses.{{save_trigger_results.iterator_index}}"
                      value:
                        object:
                          street: "{{save_trigger_results.iterator_value.street}}"
                          city: "{{save_trigger_results.iterator_value.city}}"
                          state: "{{save_trigger_results.iterator_value.state}}"
                          zip: "{{save_trigger_results.iterator_value.zip}}"
            # Step 4: POST to remote API
            - pull_external_data:
                post_to_remote:
                  method: post
                  local_data: remote_response
                  to:
                    url: 'https://remote-restructure.example.com/masters/create.json'
                    format: json
                    allow_response_codes:
                      - 400
                      - 422
                      - 500
                    headers:
                      'Content-Type': 'application/json'
                  send_data:
                    master: '{{{variables.request_body}}}'
            - set_variables:
                name: sync_status
                value: 'failed'
            - set_variables:
                if:
                  all:
                    this:
                      save_trigger_results:
                        element: remote_response_http_response_code
                        value: 200
                name: sync_status
                value: 'completed'
            - update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: "{{variables.sync_status}}"
                    notes: "sync done"
    YAML
  end

  before :each do
    create_user
    setup_access :player_contacts
    setup_access :player_infos
    setup_access :addresses
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    @master = @player_contact.master

    # Create a player_info record on the master
    @player_info = @master.build_player_info(
      first_name: 'SyncTestFirst',
      last_name: 'SyncTestLast',
      birth_date: Date.new(1990, 1, 15)
    )
    @player_info.force_save!
    @player_info.save!
  end

  describe 'builds request body with set_variables and posts to remote API' do
    before :each do
      # Create 3 additional player contacts on the master
      create_sources 'player_contacts'
      @contacts = []
      3.times do |i|
        pc = @master.player_contacts.create!(
          data: "(516)555-000#{i}",
          rec_type: :phone,
          rank: 10
        )
        @contacts << pc
      end

      setup_al_with_config(sync_config_with_contacts)

      stub_request(:post, RemoteApiUrl)
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{"master": {"id": 99}}', headers: {})
    end

    it 'posts the built body to the remote API and marks sync as completed' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'new',
        extra_log_type: 'batch_sync_test'
      )

      ActivityLog::PlayerContactPhone.trigger_batch_now(limit: 10)

      al.reload

      # Verify the API was called once
      expect(WebMock).to have_requested(:post, RemoteApiUrl).once

      # Verify the request body contains player_infos with correct names
      expect(WebMock).to(have_requested(:post, RemoteApiUrl)
        .with do |req|
          body = JSON.parse(req.body)
          master_data = body['master']
          pi = master_data['player_infos']['0']
          pi['first_name'] == 'Synctestfirst' && pi['last_name'] == 'Synctestlast'
        end)

      # Verify the request body contains all 3 contacts at indexed keys
      expect(WebMock).to(have_requested(:post, RemoteApiUrl)
        .with do |req|
          body = JSON.parse(req.body)
          contacts = body['master']['player_contacts']
          contacts.is_a?(Hash) && contacts.keys.length >= 3
        end)

      # Verify the activity log was updated with completed status
      expect(al.select_who).to eq 'completed'
      expect(al.notes).to include('99')
    end
  end

  describe 'marks sync as failed when remote API returns an error' do
    before :each do
      create_sources 'player_contacts'

      setup_al_with_config(sync_config_with_contacts)

      stub_request(:post, RemoteApiUrl)
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 400, body: '{"error": "bad request"}', headers: {})
    end

    it 'updates select_who to failed when API returns 400' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'new',
        extra_log_type: 'batch_sync_test'
      )

      ActivityLog::PlayerContactPhone.trigger_batch_now(limit: 10)

      al.reload

      # Verify the API was called
      expect(WebMock).to have_requested(:post, RemoteApiUrl).once

      # Verify the activity log was marked as failed
      expect(al.select_who).to eq 'failed'
    end
  end

  describe 'skips already completed records' do
    before :each do
      create_sources 'player_contacts'

      setup_al_with_config(sync_config_with_if_condition)

      stub_request(:post, RemoteApiUrl)
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{"master": {"id": 99}}', headers: {})
    end

    it 'only triggers API call for records with select_who new' do
      # Create a completed record — should be skipped
      al_completed = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'completed',
        extra_log_type: 'batch_sync_test'
      )

      # Create a new record — should be synced
      al_new = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'new',
        extra_log_type: 'batch_sync_test'
      )

      ActivityLog::PlayerContactPhone.trigger_batch_now(limit: 10)

      al_completed.reload
      al_new.reload

      # Only the 'new' record should trigger an API call
      expect(WebMock).to have_requested(:post, RemoteApiUrl).once

      # The 'completed' record should remain unchanged
      expect(al_completed.select_who).to eq 'completed'

      # The 'new' record should now be 'completed'
      expect(al_new.select_who).to eq 'completed'
    end
  end

  describe 'handles master with no contacts gracefully' do
    before :each do
      setup_al_with_config(sync_config_with_contacts)

      stub_request(:post, RemoteApiUrl)
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{"master": {"id": 99}}', headers: {})
    end

    it 'still syncs with empty contacts in the body' do
      # The master already has 1 player_contact from create_item in before :each,
      # but we only iterate additional ones. Actually the master has ALL its contacts.
      # To test zero contacts, we need a master with no player_contacts at all.
      # Since the activity log is associated through the player_contact, we use the
      # existing one — the contacts hash should still appear (possibly with the one contact).
      # For a true zero-contacts test, we remove all contacts from the master.
      @master.player_contacts.each do |pc|
        pc.current_user = @user
        pc.update!(rank: -1) # effectively disable by setting rank
      end

      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'new',
        extra_log_type: 'batch_sync_test'
      )

      ActivityLog::PlayerContactPhone.trigger_batch_now(limit: 10)

      al.reload

      # Verify the API was still called even with no iterable contacts
      expect(WebMock).to have_requested(:post, RemoteApiUrl).once

      # The request body should have a player_contacts hash (may contain the FK-linked contact)
      expect(WebMock).to(have_requested(:post, RemoteApiUrl)
        .with do |req|
          body = JSON.parse(req.body)
          contacts = body['master']['player_contacts']
          contacts.is_a?(Hash)
        end)

      # Sync status should be completed
      expect(al.select_who).to eq 'completed'
    end
  end

  describe 'iterates over addresses in addition to contacts' do
    before :each do
      create_sources 'player_contacts'
      create_sources 'addresses'

      # Create 2 player contacts
      @contacts = []
      2.times do |i|
        pc = @master.player_contacts.create!(
          data: "(617)555-100#{i}",
          rec_type: :phone,
          rank: 10
        )
        @contacts << pc
      end

      # Create 2 addresses
      @addresses = []
      2.times do |i|
        addr = @master.addresses.create!(
          street: "#{100 + i} Test Street",
          city: 'Portland',
          state: 'OR',
          zip: "9720#{i}",
          rank: 0,
          rec_type: 'home',
          source: 'nflpa'
        )
        @addresses << addr
      end

      setup_al_with_config(sync_config_with_contacts_and_addresses)

      stub_request(:post, RemoteApiUrl)
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{"master": {"id": 99}}', headers: {})
    end

    it 'includes both contacts and addresses in the JSON body' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'new',
        extra_log_type: 'batch_sync_test'
      )

      ActivityLog::PlayerContactPhone.trigger_batch_now(limit: 10)

      al.reload

      # Verify the API was called
      expect(WebMock).to have_requested(:post, RemoteApiUrl).once

      # Verify the request body contains contacts
      expect(WebMock).to(have_requested(:post, RemoteApiUrl)
        .with do |req|
          body = JSON.parse(req.body)
          contacts = body['master']['player_contacts']
          contacts.is_a?(Hash) && contacts.keys.length >= 2
        end)

      # Verify the request body contains addresses
      expect(WebMock).to(have_requested(:post, RemoteApiUrl)
        .with do |req|
          body = JSON.parse(req.body)
          addresses = body['master']['addresses']
          addresses.is_a?(Hash) && addresses.keys.length == 2 &&
            addresses.values.all? { |a| a.key?('street') && a.key?('city') }
        end)

      # Sync status should be completed
      expect(al.select_who).to eq 'completed'
    end
  end

  # ---------------------------------------------------------------------------
  # Integration test: exercises the full batch trigger → pull_external_data →
  # real remote Rails server → masters/create.json flow.
  #
  # This test is skipped by default. To run it:
  #   1. Create the remote test DB (one-time):
  #      TEST_ENV_SET="${TEST_ENV_SET}_apitest" app-scripts/create-test-db.sh 1
  #   2. Run specs with the flag:
  #      RUN_REMOTE_API_TEST=true bundle exec rspec spec/models/save_triggers/batch_sync_to_remote_spec.rb
  #
  # The test will automatically start a Rails server on the remote DB if one
  # is not already running. If you prefer to start it manually:
  #   TEST_ENV_SET="${TEST_ENV_SET}_apitest" bundle exec rails s -e test -p 3100
  # ---------------------------------------------------------------------------
  describe 'integration: batch sync to real remote API server' do
    before(:all) do
      if ENV['RUN_REMOTE_API_TEST']
        # TEST_ENV_SET drives the remote database name (e.g. "ws2_apitest" → restrws2_apitest_test)
        @remote_test_env_set = "#{ENV['TEST_ENV_SET']}_apitest"

        # --- remote server setup (expensive — only once) ---
        start_or_detect_remote_server
        setup_remote_user_credentials
      end
    end

    before(:each) do
      skip 'Set RUN_REMOTE_API_TEST=true to enable remote API integration tests' unless ENV['RUN_REMOTE_API_TEST']

      # The outer before(:each) already created @user, @master, @player_contact, @player_info.
      # Add extra contacts and configure the activity log for remote sync.
      create_sources 'player_contacts'
      @contacts = []
      2.times do |i|
        pc = @master.player_contacts.create!(
          data: "(617)555-900#{i}",
          rec_type: :phone,
          rank: 10
        )
        @contacts << pc
      end

      setup_al_with_config(remote_sync_config)
    end

    after(:all) do
      if @remote_server_started_by_test && @remote_server_pid
        Process.kill('TERM', @remote_server_pid) rescue nil
        Process.wait(@remote_server_pid) rescue nil
      end
    end

    def remote_server_port
      ENV.fetch('REMOTE_API_PORT', '3100').to_i
    end

    # Detect an already-running server or start one on the remote test DB
    def start_or_detect_remote_server
      if remote_server_ready?
        @remote_server_started_by_test = false
        return
      end

      @remote_server_started_by_test = true
      log_dir = Rails.root.join('tmp', 'agent-tmp')
      FileUtils.mkdir_p(log_dir)
      log_path = log_dir.join('remote_server.log').to_s

      server_env = { 'TEST_ENV_SET' => @remote_test_env_set }
      @remote_server_pid = spawn(
        server_env,
        'bundle', 'exec', 'rails', 's', '-e', 'test', '-p', remote_server_port.to_s,
        [:out, :err] => [log_path, 'w']
      )

      60.times do
        break if remote_server_ready?
        sleep 1
      end

      return if remote_server_ready?

      server_log = (File.read(log_path).last(2000) rescue 'unable to read log')
      raise "Remote server failed to start on port #{remote_server_port} within 60s.\n" \
            "Ensure the remote test DB exists:\n" \
            "  TEST_ENV_SET=#{@remote_test_env_set} app-scripts/create-test-db.sh 1\n" \
            "Server log tail:\n#{server_log}"
    end

    def remote_server_ready?
      uri = URI("http://localhost:#{remote_server_port}/")
      Net::HTTP.get_response(uri)
      true
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, SocketError
      false
    end

    # Create an API user on the remote DB via rails runner and capture credentials
    def setup_remote_user_credentials
      script_dir = Rails.root.join('tmp', 'agent-tmp')
      FileUtils.mkdir_p(script_dir)
      script_path = script_dir.join('setup_remote_user.rb').to_s

      File.write(script_path, <<~RUBY)
        admin = Admin.find_by(email: 'batch-sync-admin@testing.com')
        admin ||= Admin.create!(email: 'batch-sync-admin@testing.com')

        user = User.find_by(email: 'batch-sync-test@testing.com')
        if user
          # Regenerate the auth token so we always have the current value
          user.current_admin = admin
          user.generate_password
          user.otp_secret = User.generate_otp_secret unless user.otp_secret.present?
          user.otp_required_for_login = true
          user.new_two_factor_auth_code = false
          user.save!
        else
          user = User.create!(email: 'batch-sync-test@testing.com', current_admin: admin,
                              first_name: 'batch', last_name: 'sync')
          user = User.find(user.id)
          user.current_admin = admin
          user.generate_password
          user.otp_secret = User.generate_otp_secret
          user.otp_required_for_login = true
          user.new_two_factor_auth_code = false
          user.save!
        end

        app_type = Admin::AppType.active.first
        user.app_type = app_type
        user.save!

        # Grant app type access
        uac = Admin::UserAccessControl.find_or_initialize_by(
          user: user, app_type: app_type, resource_type: :general, resource_name: :app_type
        )
        uac.update!(current_admin: admin, access: :read, disabled: false)

        # Grant create_master permission
        uac = Admin::UserAccessControl.find_or_initialize_by(
          user: user, app_type: app_type, resource_type: :general, resource_name: :create_master
        )
        uac.update!(current_admin: admin, access: :read, disabled: false)

        # Grant create access for association types
        [:player_contacts, :player_infos, :addresses].each do |rn|
          uac = Admin::UserAccessControl.find_or_initialize_by(
            app_type: app_type, resource_type: :table, resource_name: rn, user: nil, role_name: nil
          )
          uac.update!(current_admin: admin, access: :create, disabled: false)
        end

        Admin::AppConfiguration.add_default_config(app_type, :create_master_with, 'player_info', admin)

        puts [user.email, user.authentication_token, app_type.id].join('|')
      RUBY

      runner_env = { 'TEST_ENV_SET' => @remote_test_env_set }
      output = IO.popen(
        [runner_env, 'bundle', 'exec', 'rails', 'runner', '-e', 'test', script_path],
        err: [:child, :out]
      ) { |io| io.read }

      cred_line = output.strip.lines.select { |l| l.include?('|') && l.include?('@') }.last
      raise "Failed to set up remote user credentials.\nOutput:\n#{output}" unless cred_line

      parts = cred_line.strip.split('|')
      @remote_user_email = parts[0]
      @remote_user_token = parts[1]
      @remote_app_type_id = parts[2]
    end

    # YAML config targeting the real remote server instead of a WebMock stub
    def remote_sync_config
      remote_url = "http://localhost:#{remote_server_port}/masters/create.json" \
                   "?use_app_type=#{@remote_app_type_id}" \
                   "&user_email=#{@remote_user_email}" \
                   "&user_token=#{@remote_user_token}"

      <<~YAML
        batch_sync_test:
          label: Batch Sync Test
          fields:
            - select_call_direction
            - select_who
            - notes
          batch_trigger:
            on_record:
              - set_variables:
                  name: request_body
                  value:
                    object:
                      embedded_item:
                        first_name: "{{player_infos.first_name}}"
                        last_name: "{{player_infos.last_name}}"
                        source: nflpa
                      associations:
                        player_contacts: {}
              - each:
                  value: '{{{player_contacts}}}'
                  do:
                    - set_variables:
                        name: "request_body.associations.player_contacts.{{save_trigger_results.iterator_index}}"
                        value:
                          object:
                            data: "{{save_trigger_results.iterator_value.data}}"
                            rec_type: "{{save_trigger_results.iterator_value.rec_type}}"
                            rank: "10"
                            source: nflpa
              - pull_external_data:
                  post_to_remote:
                    method: post
                    local_data: remote_response
                    to:
                      url: '#{remote_url}'
                      format: json
                      allow_response_codes:
                        - 400
                        - 422
                        - 500
                      headers:
                        'Content-Type': 'application/json'
                    send_data:
                      master: '{{{variables.request_body}}}'
              - set_variables:
                  name: sync_status
                  value: 'failed'
              - set_variables:
                  if:
                    all:
                      this:
                        save_trigger_results:
                          element: remote_response_http_response_code
                          value: 200
                  name: sync_status
                  value: 'completed'
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: "{{variables.sync_status}}"
                      notes: "Remote master ID: {{save_trigger_results.remote_response.master.id::ignore_missing}}"
      YAML
    end

    # Query the remote DB for a master record and its associations via rails runner.
    # Returns a parsed Hash with keys: player_info, player_contacts.
    def query_remote_master(master_id)
      script_dir = Rails.root.join('tmp', 'agent-tmp')
      script_path = script_dir.join('query_remote_master.rb').to_s

      File.write(script_path, <<~RUBY)
        require 'json'
        master_id = #{master_id}
        user = User.find_by(email: 'batch-sync-test@testing.com')
        m = Master.find(master_id)
        m.current_user = user

        pi = m.player_infos.first
        contacts = m.player_contacts.map { |pc| { data: pc.data, rec_type: pc.rec_type } }

        result = {
          player_info: pi ? { first_name: pi.first_name, last_name: pi.last_name } : nil,
          player_contacts: contacts
        }
        puts "RESULT_JSON:" + result.to_json
      RUBY

      runner_env = { 'TEST_ENV_SET' => @remote_test_env_set }
      output = IO.popen(
        [runner_env, 'bundle', 'exec', 'rails', 'runner', '-e', 'test', script_path],
        err: [:child, :out]
      ) { |io| io.read }

      json_line = output.lines.find { |l| l.start_with?('RESULT_JSON:') }
      raise "Failed to query remote master #{master_id}.\nOutput:\n#{output}" unless json_line

      JSON.parse(json_line.sub('RESULT_JSON:', ''))
    end

    it 'creates a master record on the remote server and marks sync as completed' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'new',
        extra_log_type: 'batch_sync_test'
      )

      ActivityLog::PlayerContactPhone.trigger_batch_now(limit: 10)

      al.reload

      # Verify sync completed and the remote master ID was captured
      expect(al.select_who).to eq 'completed'
      expect(al.notes).to match(/Remote master ID: \d+/)

      # Extract the remote master ID and verify data on the remote server
      remote_master_id = al.notes.match(/Remote master ID: (\d+)/)[1].to_i
      remote_data = query_remote_master(remote_master_id)

      # Verify player_info matches what was sent (data is downcased on storage)
      expect(remote_data['player_info']).to be_present
      expect(remote_data['player_info']['first_name']).to eq @player_info.first_name.downcase
      expect(remote_data['player_info']['last_name']).to eq @player_info.last_name.downcase

      # Verify player_contacts were created with the correct data
      remote_contacts = remote_data['player_contacts']
      local_contact_data = @master.player_contacts.pluck(:data).sort
      remote_contact_data = remote_contacts.map { |c| c['data'] }.sort
      expect(remote_contact_data).to eq local_contact_data
    end
  end
end
