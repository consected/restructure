# frozen_string_literal: true

# Tests for issue #924: Ensure API to create a master record can also create
# all related associated records in a single API call.
#
# The POST /masters/create.json endpoint should accept nested parameters for
# associated records (player_info, player_contacts, addresses, scantrons, and
# dynamic models) namespaced under `master[associations]`, and create them all
# within a single database transaction.
#
# If any associated record fails validation, the entire transaction should
# roll back — no master record or associated records should be persisted.
#
# These tests use curl to exercise the real HTTP API, mirroring the pattern
# established in api_token_spec.rb.

require 'rails_helper'

describe 'API create master with associated records - Issue #924', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterSupport
  include DynamicModelSupport

  before(:all) do
    ActionController::Base.allow_forgery_protection = true

    SetupHelper.feature_setup

    change_setting('TwoFactorAuthDisabledForUser', true)

    create_admin
    @user, @good_password = create_user(nil, '', create_master: true)
    expect(@user_authentication_token).to be_present
    @good_email = @user.email

    # Set up user access to create player_infos, player_contacts, addresses, and scantrons
    let_user_create :player_infos
    let_user_create :player_contacts
    let_user_create :addresses
    let_user_create :scantrons

    # Configure create_master_with to include player_info (the standard first embedded item)
    add_user_config(:create_master_with, 'player_info', for_user: @user)

    g = Classification::GeneralSelection.new item_type: 'player_contacts_source', name: 'CIS', value: 'cis', current_admin: @admin
    g.already_taken(:item_type, :value) || g.save

    g = Classification::GeneralSelection.new item_type: 'player_infos_source', name: 'CIS', value: 'cis', current_admin: @admin
    g.already_taken(:item_type, :value) || g.save

    g = Classification::GeneralSelection.new item_type: 'addresses_source', name: 'CIS', value: 'cis', current_admin: @admin
    g.already_taken(:item_type, :value) || g.save

    # Set up a test dynamic model for API testing
    setup_test_api_dynamic_model
  end

  after(:all) do
    ActionController::Base.allow_forgery_protection = false
  end

  #
  # Set up a dynamic model table and definition for testing API-based creation
  # of dynamic model records alongside master records.
  def setup_test_api_dynamic_model
    table_name = 'test_api_recs'
    schema_name = 'dynamic_test'

    unless Admin::MigrationGenerator.table_exists? table_name
      TableGenerators.dynamic_models_table(table_name, :create_do, 'test_field', 'test_field2')
    end

    DynamicModel.active.where(table_name:).reload.each { |dm| dm.disable!(@admin) }
    begin
      DynamicModel.send(:remove_const, :TestApiRec) if DynamicModel.const_defined?(:TestApiRec, false)
    rescue NameError
      # Constant may have been removed by another parallel test
    end

    @test_api_dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'test api recs',
      table_name:,
      schema_name:,
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test
    )
    @test_api_dm.current_admin = @admin
    @test_api_dm.update_tracker_events

    setup_access :dynamic_model__test_api_recs, user: @user
  end

  def server_url
    "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
  end

  #
  # Make a POST curl request to create a master record with associated records.
  # Sends JSON body for clean nested attribute handling.
  # @param form_params [Hash] form parameters to send as JSON body
  # @param options [Hash] override default connection options
  # @return [String] raw response body
  def curl_api_create_master(form_params = {}, options = {})
    options.reverse_merge!(
      server: server_url,
      app_type: @user.app_type_id,
      user_email: @user.email,
      user_token: @user_authentication_token
    )

    json_body = form_params.to_json

    curl = <<~END_STR
      curl -XPOST -s \
      -H "Content-Type: application/json" \
      "#{options[:server]}/masters/create.json?\
      use_app_type=#{options[:app_type]}&\
      user_email=#{options[:user_email]}&\
      user_token=#{options[:user_token]}" \
      -d '#{json_body}'
    END_STR

    `#{curl}`
  end

  describe 'creating a master with all associated records in one API call' do
    it 'creates a master record with player_info, multiple player_contacts, address, scantron, and dynamic model' do
      last_master_id = Master.reorder('').last.id
      scantron_id = rand(Scantron.external_id_range)

      form_params = {
        master: {
          # Player info (embedded item for create_master_with)
          embedded_item: {
            first_name: 'testfirst',
            last_name: 'testlast',
            source: 'cis'
          },
          # Associated records namespaced under `associations`
          associations: {
            # Player contacts (two records with different ranks)
            player_contacts: {
              '0' => { data: '(617)555-0100', rec_type: 'phone', rank: 10, source: 'cis' },
              '1' => { data: '(617)555-0200', rec_type: 'phone', rank: 5, source: 'cis' }
            },
            # Address
            addresses: {
              '0' => { street: '123 test street', city: 'boston', state: 'ma', zip: '02101', rank: 10, source: 'cis' }
            },
            # Scantron (external identifier)
            scantrons: {
              '0' => { scantron_id: scantron_id }
            },
            # Dynamic model
            dynamic_model__test_api_recs: {
              '0' => { test_field: 'api test value', test_field2: 'api test value 2' }
            }
          }
        }
      }

      res = curl_api_create_master(form_params)
      expect(res).to be_present

      jres = JSON.parse(res)

      # The master record should be created successfully
      expect(jres['master']).to be_present, "Expected master in response, got: #{jres}"
      expect(jres['master']['id']).to be > last_master_id

      new_master_id = jres['master']['id']
      master = Master.find(new_master_id)
      master.current_user = @user

      # Verify player_info was created
      player_infos = master.player_infos.reload
      expect(player_infos.count).to eq(1)
      expect(player_infos.first.first_name).to eq('testfirst')
      expect(player_infos.first.last_name).to eq('testlast')

      # Verify two player_contacts were created
      player_contacts = master.player_contacts.reload
      expect(player_contacts.count).to eq(2)
      ranks = player_contacts.map(&:rank).sort
      expect(ranks).to eq([5, 10])

      # Verify address was created
      addresses = master.addresses.reload
      expect(addresses.count).to eq(1)
      expect(addresses.first.street).to eq('123 test street')
      expect(addresses.first.city).to eq('boston')
      expect(addresses.first.rank).to eq(10)

      # Verify scantron was created
      scantrons = master.scantrons.reload
      expect(scantrons.count).to eq(1)
      expect(scantrons.first.scantron_id).to eq(scantron_id)

      # Verify dynamic model record was created
      dm_recs = master.dynamic_model__test_api_recs.reload
      expect(dm_recs.count).to eq(1)
      expect(dm_recs.first.test_field).to eq('api test value')
      expect(dm_recs.first.test_field2).to eq('api test value 2')
    end
  end

  describe 'transaction rollback on validation failure' do
    it 'rolls back all records when one associated record fails validation' do
      master_count_before = Master.count
      player_info_count_before = PlayerInfo.count
      player_contact_count_before = PlayerContact.count
      address_count_before = Address.count

      form_params = {
        master: {
          # Valid player info
          embedded_item: {
            first_name: 'rollfirst',
            last_name: 'rolllast',
            source: 'cis'
          },
          # Associated records namespaced under `associations`
          associations: {
            # Valid player contact
            player_contacts: {
              '0' => { data: '(617)555-9999', rec_type: 'phone', rank: 10, source: 'cis' }
            },
            # Invalid address — rank is required but missing.
            # This should cause a validation failure and roll back the entire transaction.
            addresses: {
              '0' => { street: '456 bad street', city: 'boston', state: 'ma', zip: '02101' }
              # No rank — should fail validation
            }
          }
        }
      }

      res = curl_api_create_master(form_params)
      expect(res).to be_present

      jres = JSON.parse(res)

      # The API should return an error
      expect(jres['message']).to be_present, "Expected error message in response, got: #{jres}"

      # No new master record should be created
      expect(Master.count).to eq(master_count_before),
                              'Master record was created despite validation failure — transaction did not roll back'

      # No new player_info should be created
      expect(PlayerInfo.count).to eq(player_info_count_before),
                                  'PlayerInfo was created despite validation failure — transaction did not roll back'

      # No new player_contact should be created
      expect(PlayerContact.count).to eq(player_contact_count_before),
                                     'PlayerContact was created despite validation failure — transaction did not roll back'

      # No new address should be created
      expect(Address.count).to eq(address_count_before),
                               'Address was created despite validation failure — transaction did not roll back'
    end
  end
end
