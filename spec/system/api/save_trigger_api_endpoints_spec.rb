# frozen_string_literal: true

# Tests that the API URL patterns shown in the admin API panels' "save trigger usage"
# sections can actually retrieve and send data via pull_external_data save triggers.
#
# Exercises both the pull_external_data client (save trigger mechanism) and the
# server's REST API endpoints end-to-end.
#
# Dynamic model tests:
# 1. Creates a dynamic model with auto-migrated table in the dynamic_test schema
# 2. Verifies GET show, GET index, and POST create via pull_external_data
#
# Report tests:
# 3. Creates a report with a search attribute (last_name) using use_plain_attribute_names
# 4. Verifies GET report JSON via pull_external_data returns matching results
#
# Create master with associations tests (PR #929):
# 5. POST /masters/create.json with embedded_item and nested associations via pull_external_data
# 6. Verifies transaction rollback when association validation fails

require 'rails_helper'

RSpec.describe 'pull_external_data save trigger API endpoints', type: :system, js: true, driver: $browser_driver do
  include ModelSupport
  include MasterSupport

  TABLE_NAME = 'test_api_trigger_recs'
  SCHEMA_NAME = 'dynamic_test'
  RESOURCE_NAME = :"dynamic_model__#{TABLE_NAME}"

  before(:all) do
    SetupHelper.feature_setup
    create_admin

    # Enable dynamic migrations so the DM create automatically generates the DB table
    change_setting('AllowDynamicMigrations', true)

    # Create the dynamic model definition — after_create generates the DB table via migration,
    # after_save generates the model class, after_create_commit reloads routes
    @dm = DynamicModel.create!(
      table_name: TABLE_NAME,
      schema_name: SCHEMA_NAME,
      name: 'Test API Trigger Records',
      description: 'Test pull_external_data save trigger API endpoints',
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      category: 'test',
      field_list: 'name description notes',
      result_order: 'id',
      current_admin: @admin
    )

    @dm.update_tracker_events

    # Verify model generation succeeded
    dm_class_name = @dm.implementation_class.name
    expect(DynamicModel.const_defined?(dm_class_name)).to be_truthy,
                                                          "DynamicModel::#{dm_class_name} was not generated"

    # Ensure routes are loaded for the new DM so the Capybara server can handle requests
    DynamicModel.routes_load

    # Create a user with API token
    @user, @good_password = create_user(nil, '', create_master: true)
    expect(@user_authentication_token).to be_present

    # Create a master record
    @master = create_master

    # Set up DM access for the user (create access satisfies the :access combo check)
    setup_access RESOURCE_NAME, user: @user
    expect(@user.has_access_to?(:access, :table, RESOURCE_NAME)).to be_truthy

    # Create the implementation class and a target record for GET tests
    @impl_class = @dm.implementation_class
    @target_record = @impl_class.create!(
      current_user: @user,
      master: @master,
      name: 'target record',
      description: 'record to be retrieved by get'
    )

    expect(@target_record).to be_persisted
    expect(@target_record.id).to be_present
  end

  #
  # Capybara test server URL (e.g., "http://127.0.0.1:12345")
  # @return [String]
  def server_url
    "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
  end

  #
  # URL query string for API authentication, matching the pattern in
  # AdminApiDefinitionsHelper#api_save_trigger_example
  # @return [String]
  def api_auth_params
    "use_app_type=#{@user.app_type_id}&user_email=#{@user.email}&user_token=#{@user_authentication_token}"
  end

  #
  # API base path matching AdminApiDefinitionsHelper#api_base_path output
  # @return [String] e.g., "/masters/1/dynamic_model/test_api_trigger_recs"
  def dm_api_base_path
    "/masters/#{@master.id}/dynamic_model/#{TABLE_NAME}"
  end

  #
  # JSON response key from the controller's full_object_name.
  # Uses double underscore (e.g., "dynamic_model__test_api_trigger_rec")
  # @return [String]
  def response_key
    @dm.implementation_class.resource_name.singularize
  end

  #
  # POST param wrapper key from the controller's primary_params_name.
  # Uses single underscore (e.g., "dynamic_model_test_api_trigger_rec")
  # @return [String]
  def param_key
    @dm.implementation_class.resource_name.gsub('__', '_').singularize
  end

  it 'retrieves an existing record via GET using the save trigger URL pattern' do
    # This tests the GET URL pattern from AdminApiDefinitionsHelper#api_save_trigger_example:
    #   url: "{{base_url}}/masters/{{master_id}}/dynamic_model/table_name/{{constants.item_id}}.json
    #         ?use_app_type={{constants.api_app_type}}
    #         &user_email={{constants.api_user_email}}
    #         &user_token={{constants.api_shared_secret}}"

    # Build a trigger item: the record that would "run" the save trigger
    trigger_item = @impl_class.create!(
      current_user: @user,
      master: @master,
      name: 'trigger item get',
      description: 'item that fires the get save trigger'
    )

    config = {
      get_record: {
        local_data: 'get_result',
        from: {
          url: "#{server_url}#{dm_api_base_path}/#{@target_record.id}.json?#{api_auth_params}",
          format: 'json',
          allow_empty_result: false
        }
      }
    }

    trigger = SaveTriggers::PullExternalData.new(config, trigger_item)
    trigger.perform

    # Verify the GET result contains the target record's data
    get_result = trigger_item.save_trigger_results['get_result']
    expect(get_result).to be_present

    # The JSON response format is: { "<response_key>" => { field data }, "_control" => { ... } }
    record_data = get_result[response_key]
    expect(record_data).to be_present
    expect(record_data['id']).to eq @target_record.id
    expect(record_data['name']).to eq 'target record'
    expect(record_data['description']).to eq 'record to be retrieved by get'
    expect(trigger.response_code).to eq 200
  end

  it 'creates a new record via POST using the save trigger URL pattern' do
    # This tests the POST URL pattern from AdminApiDefinitionsHelper#api_save_trigger_example:
    #   url: "{{base_url}}/masters/{{master_id}}/dynamic_model/table_name.json
    #         ?use_app_type={{constants.api_app_type}}
    #         &user_email={{constants.api_user_email}}
    #         &user_token={{constants.api_shared_secret}}"
    #   post_data:
    #     <param_key>:
    #       name: "value"
    #       description: "value"

    trigger_item = @impl_class.create!(
      current_user: @user,
      master: @master,
      name: 'trigger item post',
      description: 'item that fires the post save trigger'
    )

    config = {
      create_record: {
        local_data: 'create_result',
        force_not_editable_save: true,
        method: 'post',
        to: {
          url: "#{server_url}#{dm_api_base_path}.json?#{api_auth_params}",
          format: 'json',
          allow_empty_result: false,
          headers: {
            'Content-Type': 'application/json'
          }
        },
        post_data: {
          param_key => {
            'name' => 'api created record',
            'description' => 'created via post save trigger'
          }
        }
      }
    }

    initial_count = @impl_class.where(master: @master).count

    trigger = SaveTriggers::PullExternalData.new(config, trigger_item)
    trigger.perform

    # Verify the POST result contains the created record's data
    create_result = trigger_item.save_trigger_results['create_result']
    expect(create_result).to be_present
    expect(create_result[response_key]).to be_present

    created_data = create_result[response_key]
    expect(created_data['name']).to eq 'api created record'
    expect(created_data['description']).to eq 'created via post save trigger'
    expect(created_data['id']).to be_present
    expect(trigger.response_code).to eq 200

    # Verify the record was actually created in the database
    new_count = @impl_class.where(master: @master).count
    expect(new_count).to eq initial_count + 1

    created_record = @impl_class.find(created_data['id'])
    expect(created_record.name).to eq 'api created record'
    expect(created_record.master_id).to eq @master.id
  end

  it 'retrieves a list of records via GET index using the save trigger URL pattern' do
    # This tests the index GET URL pattern:
    #   url: "{{base_url}}/masters/{{master_id}}/dynamic_model/table_name.json?..."

    trigger_item = @impl_class.create!(
      current_user: @user,
      master: @master,
      name: 'trigger item index',
      description: 'item that fires the index save trigger'
    )

    config = {
      list_records: {
        local_data: 'index_result',
        from: {
          url: "#{server_url}#{dm_api_base_path}.json?#{api_auth_params}",
          format: 'json',
          allow_empty_result: false
        }
      }
    }

    trigger = SaveTriggers::PullExternalData.new(config, trigger_item)
    trigger.perform

    index_result = trigger_item.save_trigger_results['index_result']
    expect(index_result).to be_present
    expect(trigger.response_code).to eq 200

    # The index response is an array of records (or a hash with the plural key)
    # Verify at least one record is present
    records = index_result.is_a?(Array) ? index_result : index_result.values.first
    expect(records).to be_present
    expect(records.length).to be >= 1
  end

  context 'report API' do
    before(:all) do
      # Grant player_infos create access so we can create test records
      setup_access :player_infos, user: @user

      # Ensure valid source selections exist for player_infos
      gs = Classification::GeneralSelection.active.where(item_type: 'player_infos_source', value: %w[nfl nflpa])
      if gs.empty?
        Classification::GeneralSelection.create!(item_type: 'player_infos_source', name: 'NFL', value: 'nfl',
                                                 current_admin: @admin, create_with: true)
        Classification::GeneralSelection.create!(item_type: 'player_infos_source', name: 'NFLPA', value: 'nflpa',
                                                 current_admin: @admin, create_with: true)
      else
        gs.update_all(create_with: true)
      end
      Rails.cache.clear

      # Create a player_info record with a known last_name for the report query
      @test_last_name = "apitriggertest#{SecureRandom.hex(4)}"
      @player_info = PlayerInfo.create!(
        master: @master,
        current_user: @user,
        first_name: 'api',
        last_name: @test_last_name,
        rank: 10,
        source: 'nflpa',
        birth_date: Date.new(1980, 1, 15)
      )

      # Create a report with use_plain_attribute_names and a last_name search attribute
      report_sql = <<~SQL.squish
        select first_name, last_name, rank, source, birth_date
        from player_infos
        where last_name = :last_name
      SQL

      search_attrs_yaml = <<~YAML
        last_name:
          string:
            label: Last Name
      YAML

      options_yaml = <<~YAML
        view_options:
          use_plain_attribute_names: true
      YAML

      @report = Report.create!(
        current_admin: @admin,
        name: "API Trigger Test Report #{SecureRandom.hex(4)}",
        item_type: 'test',
        sql: report_sql,
        search_attrs: search_attrs_yaml,
        options: options_yaml,
        report_type: 'regular_report',
        searchable: true
      )

      # Grant the user access to view reports and this specific report
      unless @user.has_access_to?(:read, :general, :view_reports)
        Admin::UserAccessControl.create!(
          app_type: @user.app_type, access: :read,
          resource_type: :general, resource_name: :view_reports,
          current_admin: @admin
        )
      end

      Admin::UserAccessControl.create!(
        app_type: @user.app_type, access: :read,
        resource_type: :report, resource_name: @report.alt_resource_name,
        current_admin: @admin
      )
    end

    #
    # Report API base path matching the pattern in _api_panel_report.html.erb
    # @return [String] e.g., "/reports/test__api_trigger_test_report_abc123"
    def report_api_path
      "/reports/#{@report.alt_resource_name}"
    end

    #
    # URL search attributes with plain attribute names (not wrapped in search_attrs[])
    # @return [String] e.g., "last_name=apitriggertest1234abcd"
    def report_search_params
      { last_name: @test_last_name }.to_query
    end

    it 'retrieves report results via GET using the save trigger URL pattern' do
      # This tests the report GET URL pattern from _api_panel_report.html.erb save trigger usage:
      #   url: "{{base_url}}/reports/<alt_resource_name>.json
      #         ?<search_attrs>
      #         &use_app_type={{constants.api_app_type}}
      #         &user_email={{constants.api_user_email}}
      #         &user_token={{constants.api_shared_secret}}"

      trigger_item = @impl_class.create!(
        current_user: @user,
        master: @master,
        name: 'trigger item report',
        description: 'item that fires the report save trigger'
      )

      config = {
        get_report: {
          local_data: 'report_result',
          from: {
            url: "#{server_url}#{report_api_path}.json?#{report_search_params}&#{api_auth_params}",
            format: 'json',
            allow_empty_result: false
          }
        }
      }

      trigger = SaveTriggers::PullExternalData.new(config, trigger_item)
      trigger.perform

      report_result = trigger_item.save_trigger_results['report_result']
      expect(report_result).to be_present
      expect(trigger.response_code).to eq 200

      # Default JSON format is { "results" => [...], "search_attributes" => {...} }
      expect(report_result).to have_key('results')
      results = report_result['results']
      expect(results).to be_present
      expect(results.length).to be >= 1

      # Verify the result contains the expected player_info data
      matching = results.find { |r| r['last_name'] == @test_last_name }
      expect(matching).to be_present
      expect(matching['first_name']).to eq 'api'
      expect(matching['rank']).to eq 10
      expect(matching['source']).to eq 'nflpa'
      expect(matching['birth_date']).to eq '1980-01-15'
    end
  end

  context 'create master with associations API (PR #929)' do
    before(:all) do
      # Ensure general selection sources exist for player_infos, player_contacts, and addresses
      { 'player_infos_source' => { 'CIS' => 'cis' },
        'player_contacts_source' => { 'CIS' => 'cis' },
        'addresses_source' => { 'NFL' => 'nfl' } }.each do |item_type, entries|
        entries.each do |name, value|
          unless Classification::GeneralSelection.active.exists?(item_type:, value:)
            Classification::GeneralSelection.create!(item_type:, name:, value:,
                                                     current_admin: @admin, create_with: true)
          end
        end
      end
      Rails.cache.clear

      # Grant create_master permission
      let_user_create_master

      # Grant create access for association record types
      let_user_create :player_infos
      let_user_create :player_contacts
      let_user_create :addresses

      # Grant create access for the dynamic model used in associations
      let_user_create RESOURCE_NAME

      # Configure create_master_with to allow player_info as the embedded item
      add_user_config(:create_master_with, 'player_info', for_user: @user)
    end

    it 'creates a master record with embedded item and associations via POST save trigger' do
      # This tests the POST /masters/create.json endpoint from PR #929:
      #   url: "{{base_url}}/masters/create.json
      #         ?use_app_type={{constants.api_app_type}}
      #         &user_email={{constants.api_user_email}}
      #         &user_token={{constants.api_shared_secret}}"
      #   post_data:
      #     master:
      #       embedded_item: { first_name, last_name, source }
      #       associations:
      #         player_contacts: { "0": { data, rec_type, rank, source } }
      #         addresses: { "0": { street, city, state, zip, rank, source } }
      #         dynamic_model__<table_name>: { "0": { field1, field2 } }

      trigger_item = @impl_class.create!(
        current_user: @user,
        master: @master,
        name: 'trigger item create master',
        description: 'item that fires the create master save trigger'
      )

      last_master_id = Master.reorder('').last.id

      config = {
        create_master: {
          local_data: 'create_master_result',
          force_not_editable_save: true,
          method: 'post',
          to: {
            url: "#{server_url}/masters/create.json?#{api_auth_params}",
            format: 'json',
            allow_empty_result: false,
            headers: {
              'Content-Type': 'application/json'
            }
          },
          post_data: {
            master: {
              embedded_item: {
                first_name: 'apifirst',
                last_name: 'apilast',
                source: 'cis'
              },
              associations: {
                player_contacts: {
                  '0' => { data: '(617)555-0100', rec_type: 'phone', rank: 10, source: 'cis' }
                },
                addresses: {
                  '0' => { street: '99 api street', city: 'boston', state: 'ma', zip: '02101',
                           rank: 10, source: 'nfl' }
                },
                RESOURCE_NAME => {
                  '0' => { name: 'api assoc dm', description: 'created as association' }
                }
              }
            }
          }
        }
      }

      trigger = SaveTriggers::PullExternalData.new(config, trigger_item)
      trigger.perform

      result = trigger_item.save_trigger_results['create_master_result']
      expect(result).to be_present
      expect(trigger.response_code).to eq 200

      # Verify the master record was created
      expect(result['master']).to be_present, "Expected master in response, got: #{result}"
      expect(result['master']['id']).to be > last_master_id

      new_master = Master.find(result['master']['id'])
      new_master.current_user = @user

      # Verify player_info (embedded item) was created
      player_infos = new_master.player_infos.reload
      expect(player_infos.count).to eq 1
      expect(player_infos.first.first_name).to eq 'apifirst'
      expect(player_infos.first.last_name).to eq 'apilast'

      # Verify player_contact was created
      player_contacts = new_master.player_contacts.reload
      expect(player_contacts.count).to eq 1
      expect(player_contacts.first.data).to eq '(617)555-0100'
      expect(player_contacts.first.rec_type).to eq 'phone'

      # Verify address was created
      addresses = new_master.addresses.reload
      expect(addresses.count).to eq 1
      expect(addresses.first.street).to eq '99 api street'
      expect(addresses.first.city).to eq 'boston'

      # Verify dynamic model record was created
      dm_recs = new_master.send(RESOURCE_NAME.to_s.pluralize).reload
      expect(dm_recs.count).to eq 1
      expect(dm_recs.first.name).to eq 'api assoc dm'
      expect(dm_recs.first.description).to eq 'created as association'
    end

    it 'rolls back all records when an association fails validation' do
      # When any association record fails validation, the entire transaction should roll back:
      # no master, no embedded item, no other associations should be persisted.

      trigger_item = @impl_class.create!(
        current_user: @user,
        master: @master,
        name: 'trigger item rollback',
        description: 'item that fires a failing create master trigger'
      )

      master_count_before = Master.count

      config = {
        create_master_rollback: {
          local_data: 'rollback_result',
          force_not_editable_save: true,
          method: 'post',
          to: {
            url: "#{server_url}/masters/create.json?#{api_auth_params}",
            format: 'json',
            allow_empty_result: false,
            allow_response_codes: [400],
            headers: {
              'Content-Type': 'application/json'
            }
          },
          post_data: {
            master: {
              embedded_item: {
                first_name: 'rollfirst',
                last_name: 'rolllast',
                source: 'cis'
              },
              associations: {
                # Invalid address — rank is required but missing, causing validation failure
                addresses: {
                  '0' => { street: '456 bad street', city: 'boston', state: 'ma', zip: '02101' }
                }
              }
            }
          }
        }
      }

      trigger = SaveTriggers::PullExternalData.new(config, trigger_item)
      trigger.perform

      # When allow_response_codes includes 400, PullExternalData sets response_code
      # but returns nil data (no body parsed). Verify the error response code.
      expect(trigger.response_code).to eq 400

      # No new master record should have been created (transaction rolled back)
      expect(Master.count).to eq master_count_before
    end
  end
end
