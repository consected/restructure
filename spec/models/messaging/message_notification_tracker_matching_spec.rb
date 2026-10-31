# frozen_string_literal: true

# Purpose: Verify configured tracker recipient matching against real dynamic contact associations, including disabled contacts.
require 'rails_helper'

RSpec.describe Messaging::MessageNotificationTracker, type: :model do
  include MasterSupport
  include ModelSupport

  before :all do
    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
    create_admin
    seed_database
    Seeds::TrackerGeneralProtocol.create_protocol_events
    @contact_table_name = "notification_tracker_contact#{SecureRandom.hex(4)}s"
    @contact_model = DynamicModel.new(
      current_admin: @admin,
      name: 'Notification Tracker Contact',
      table_name: @contact_table_name,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'rec_type data rank source disabled',
      options: <<~YAML
        _db_columns:
          disabled:
            type: boolean
        default:
          view_options:
            view_handlers:
              - contact
      YAML
    )
    rec_type_item = "#{@contact_model.model_association_name}_rec_type"
    selector_values = %w[email phone].map do |rec_type|
      [rec_type_item, rec_type.titleize, rec_type]
    end
    selector_values.push(
      ["#{@contact_model.model_association_name}_source", 'Test source', 'test'],
      ["#{@contact_model.model_association_name}_rank", 'Primary', 10]
    )
    selector_values.each do |item_type, name, value|
      Classification::GeneralSelection.create!(current_admin: @admin, item_type:, name:, value:)
    end
    @contact_model.save!
    @contact_model.update_tracker_events
    @contact_association_prefix = @contact_model.model_class.name.ns_underscore
    @email_resource_name = "#{@contact_association_prefix}_emails"
    @phone_resource_name = "#{@contact_association_prefix}_phones"
  end

  after :all do
    @contact_model&.reload&.disable!(@admin)
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :example do
    create_admin
    @user, = create_user
    @app_type = @user.app_type
    setup_access @contact_model.resource_name, user: @user
    @master = create_master(@user)
    @layout = Admin::MessageTemplate.create!(
      name: "tracker matching layout #{SecureRandom.hex(4)}",
      message_type: :email,
      template_type: :layout,
      template: '{{main_content}}',
      current_admin: @admin
    )
    @sms_layout = Admin::MessageTemplate.create!(
      name: "tracker matching sms layout #{SecureRandom.hex(4)}",
      message_type: :sms,
      template_type: :layout,
      template: '{{main_content}}',
      current_admin: @admin
    )
    configure_resources
  end

  def configure_resources(email: @email_resource_name, phone: @phone_resource_name)
    value = { email:, phone: }.to_yaml
    configuration = @app_type.app_configurations.active.find_by(name: 'message notification contact resources')
    if configuration
      configuration.update!(value:, current_admin: @admin)
    else
      add_app_config(@app_type, 'message notification contact resources', value)
    end
  end

  def create_dynamic_contact(master:, rec_type:, data:, disabled: false)
    reflection = Master.reflect_on_association(:"#{@contact_association_prefix}_#{rec_type.pluralize}")
    raise "Missing dynamic contact association for #{rec_type}" unless reflection

    master.current_user = @user
    master.public_send(reflection.name).create!(
      current_user: @user,
      rec_type:,
      data:,
      rank: 10,
      source: 'test',
      disabled:
    )
  end

  def create_notification(master:, recipients:, message_type: :email)
    layout = message_type.to_sym == :sms ? @sms_layout : @layout
    Messaging::MessageNotification.create!(
      app_type: @app_type,
      user: @user,
      master:,
      item_type: UserPreference.name,
      layout_template_name: layout.name,
      content_template_text: 'Notification content',
      message_type:,
      subject: message_type.to_sym == :email ? 'Notification subject' : nil,
      recipient_data: recipients
    )
  end

  def complete_notification(notification)
    notification.update!(status: Messaging::MessageNotification::StatusComplete)
    TrackerHistory.where(item_id: notification.id, item_type: notification.class.name)
  end

  it 'matches email recipients through the real configured dynamic contact association' do
    create_dynamic_contact(master: @master, rec_type: 'email', data: 'recipient@example.test')
    notification = create_notification(master: nil, recipients: ['Recipient@example.test'])

    history = complete_notification(notification).sole

    expect(history.master_id).to eq @master.id
    expect(history.notes).to eq "type: email\nto: Recipient@example.test\nsubject: Notification subject"
  end

  it 'matches formatted dynamic phone contacts to sent E.164 recipients' do
    create_dynamic_contact(master: @master, rec_type: 'phone', data: '(516) 555-0102')
    number = '+15165550102'
    notification = create_notification(master: nil, recipients: [number], message_type: :sms)

    history = complete_notification(notification).sole

    expect(history.master_id).to eq @master.id
    expect(history.notes).to eq "type: sms\nto: #{number}"
  end

  it 'matches UK contacts using the configured country code and trunk prefix' do
    add_app_config(@app_type, 'default phone country code', '44')
    add_app_config(@app_type, 'default phone trunk number', '0')
    create_dynamic_contact(master: @master, rec_type: 'phone', data: '07700 900123')
    number = '+447700900123'
    notification = create_notification(master: nil, recipients: [number], message_type: :sms)

    history = complete_notification(notification).sole

    expect(history.master_id).to eq @master.id
    expect(history.notes).to eq "type: sms\nto: #{number}"
  end

  it 'does not match disabled dynamic contact records' do
    association = Master.reflect_on_association(@email_resource_name.to_sym)
    expect(association.klass.column_names).to include('disabled')
    create_dynamic_contact(master: @master, rec_type: 'email', data: 'retired@example.test', disabled: true)
    notification = create_notification(master: nil, recipients: ['retired@example.test'])

    expect(complete_notification(notification)).to be_empty
  end

  it 'creates one history per matching master with only that master recipient' do
    first_master = @master
    second_master = create_master(@user)
    create_dynamic_contact(master: first_master, rec_type: 'email', data: 'first@example.test')
    create_dynamic_contact(master: second_master, rec_type: 'email', data: 'second@example.test')
    notification = create_notification(master: nil, recipients: %w[first@example.test second@example.test])

    histories = complete_notification(notification).order(:master_id).to_a
    expected_notes = {
      first_master.id => "type: email\nto: first@example.test\nsubject: Notification subject",
      second_master.id => "type: email\nto: second@example.test\nsubject: Notification subject"
    }

    expect(histories.map(&:master_id)).to eq expected_notes.keys.sort
    expect(histories.to_h { |history| [history.master_id, history.notes] }).to eq expected_notes
  end

  it 'does not consult default player contacts when a dynamic contact resource is configured' do
    default_contact_master = create_master(@user)
    create_dynamic_contact(master: @master, rec_type: 'email', data: 'configured@example.test')
    PlayerContact.create!(master: default_contact_master, rec_type: 'email', data: 'configured@example.test', rank: 10)
    notification = create_notification(master: nil, recipients: ['configured@example.test'])

    history = complete_notification(notification).sole

    expect(history.master_id).to eq @master.id
  end

  it 'creates no history when no configured contact matches' do
    notification = create_notification(master: nil, recipients: ['missing@example.test'])

    expect(complete_notification(notification)).to be_empty
  end

  it 'logs and skips an unknown configured association' do
    configure_resources(email: 'unknown_dynamic_contact_emails')
    notification = create_notification(master: nil, recipients: ['missing@example.test'])
    expect(Rails.logger).to receive(:warn).with(a_string_including('unknown_dynamic_contact_emails'))

    expect(complete_notification(notification)).to be_empty
  end

  it 'logs and skips a configured association whose model lacks contact columns' do
    configure_resources(email: 'trackers')
    notification = create_notification(master: nil, recipients: ['missing@example.test'])
    expect(Rails.logger).to receive(:warn).with(a_string_including('invalid contact resource'))

    expect(complete_notification(notification)).to be_empty
  end
end
