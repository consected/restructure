# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Dynamic model implementation description using both imported apps and direct configurations
RSpec.describe 'Dynamic Definition Generation', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  def generate_test_al(keep_def: nil)
    create_user unless @user
    @user.app_type ||= Admin::AppType.active.first
    @user.email = @admin.email
    @user.current_admin = @admin
    @user.save
    @app_type = @user.app_type

    setup_access :masters, user: @user
    @master = Master.create! current_user: @user
    @master.current_user = @user

    # Clean up old definition
    @als = ActivityLog.active.where(
      name: 'activity_log_player_contacts',
      item_type: 'player_contact',
      process_name: 'embed_test'
    )

    if keep_def
      @al = @als.first
      @al.updated_at = Time.now
      @al.current_admin = @admin
      @al.save!
    else
      @als.each do |al|
        al.update! disabled: true, current_admin: @admin
      end

      yaml = <<~END_YAML
        test1:
          config_trigger:
            on_define:
              create_defaults:
                user_access_control:
                embed:
                  fields:
                    - status
                    - notes
                page_layout:
          embed: default_embed_resource
      END_YAML

      al_att = {
        name: 'activity_log_player_contacts',
        item_type: 'player_contact',
        process_name: 'embed_test',
        schema_name: 'dynamic_test',
        category: 'setup',
        action_when_attribute: 'emailed_when',
        current_admin: @admin,
        extra_log_types: yaml
      }
      @al = ActivityLog.create! al_att
    end

    # setup_access :activity_log__player_contact_embed_tests
    # setup_access :activity_log__player_contact_embed_test__test1, resource_type: :activity_log_type
  end

  before :all do
    Settings::AllowDynamicMigrations = true
    # SetupHelper.setup_al_player_contact_phones
    # ::ActivityLog.define_models
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    @player_contact = create_item(data: rand(10_000_000_000_000_000), rank: 10)
    generate_test_al
    Settings::AllowDynamicMigrations = nil
  end

  it 'creates an activity log with default user access control and embedded item' do
    @master.current_user = @user

    role_name = "user - #{@al.category || @app_type.name}"
    expect(Admin::UserRole.active_app_roles(@user, app_type: @user.app_type).map(&:role_name)).to include role_name

    expect(ActivityLog::PlayerContactEmbedTest.definition.option_configs.first.config_trigger[:on_define]).to be_present
    al = ActivityLog::PlayerContactEmbedTest.create(master: @master, player_contact_id: @player_contact.id, extra_log_type: :test1)
    expect { DynamicModel::SetupEmbedTestTest1Rec }.not_to raise_error
    dm = DynamicModel::SetupEmbedTestTest1Rec.first

    embedded_item = al.embedded_item
    expect(embedded_item).to eq dm

    expect(Admin::PageLayout.last.panel_name).to eq 'setup'
  end

  it 'will not break existing configurations when an activity log with config_trigger is rerun' do
    role_name = "user - #{@al.category || @app_type.name}"
    expect(Admin::UserRole.active_app_roles(@user, app_type: @user.app_type).map(&:role_name)).to include role_name
    expect(ActivityLog::PlayerContactEmbedTest.definition.option_configs.first.config_trigger[:on_define]).to be_present
    al = ActivityLog::PlayerContactEmbedTest.create(master: @master, player_contact_id: @player_contact.id, extra_log_type: :test1)
    expect { DynamicModel::SetupEmbedTestTest1Rec }.not_to raise_error
    dm = DynamicModel::SetupEmbedTestTest1Rec.create(master: @master, @al.foreign_key_field_name => al.id, status: 'done')
    expect(dm.persisted?).to be true

    generate_test_al
    al = ActivityLog::PlayerContactEmbedTest.create(master: @master, player_contact_id: @player_contact.id, extra_log_type: :test1)
    expect { DynamicModel::SetupEmbedTestTest1Rec }.not_to raise_error
    dm = DynamicModel::SetupEmbedTestTest1Rec.create(master: @master, @al.foreign_key_field_name => al.id, status: 'done')
    expect(dm.persisted?).to be true

    # The generator doesn't add the user back into a role if the user role was previously disabled. The aim is to allow the admin to override this setting
    ur = Admin::UserRole.active.find_by(role_name:, user_id: @user.id, app_type: @user.app_type)
    ur.update!(disabled: true, current_admin: @admin)
    generate_test_al
    expect { ActivityLog::PlayerContactEmbedTest.create(master: @master, player_contact_id: @player_contact.id, extra_log_type: :test1) }.to raise_error(FphsException)
    expect { DynamicModel::SetupEmbedTestTest1Rec }.not_to raise_error
    expect { DynamicModel::SetupEmbedTestTest1Rec.create(master: @master, @al.foreign_key_field_name => al.id, status: 'done') }.to raise_error(FphsException)

    ur.update!(disabled: false, current_admin: @admin)
    al = ActivityLog::PlayerContactEmbedTest.create(master: @master, player_contact_id: @player_contact.id, extra_log_type: :test1)
    dm = DynamicModel::SetupEmbedTestTest1Rec.first
    embedded_item = al.embedded_item
    expect(embedded_item).to eq dm
  end

  it 'add configurations using the app import format' do
    rn = DynamicModel::SetupEmbedTestTest1Rec.resource_name
    yaml = <<~END_YAML
      test1:
        config_trigger:
          on_define:
            create_defaults:
              user_access_control:
              embed:
                fields:
                  - status
                  - notes
              page_layout:
            create_configs:
              associated_general_selections:
                - name: Not Started
                  value: not started
                  item_type: '{{default_embed_resource_name}}_status'
                  position: 1600
                - name: Pending
                  value: pending
                  item_type: #{rn}_status
                  position: 1601
                - name: In Progress
                  value: in progress
                  item_type: #{rn}_status
                  position: 1602

        embed: default_embed_resource
    END_YAML

    @al.update!(extra_log_types: yaml)
    gs = Classification::GeneralSelection.where(item_type: "#{rn}_status")
    expect(gs.length).to eq 3
  end
end
