# frozen_string_literal: true

# Purpose: Verify secure recipient-scoped notification previews, including list notifications tracked on participants.

require 'rails_helper'

RSpec.describe 'Message notification previews', type: :request do
  include MasterSupport
  include ModelSupport
  include UserSupport

  before do
    @admin = create_admin.first
    @user = create_user.first
    @master = create_master(@user)
    @protocol = Classification::Protocol.create!(name: "Preview Protocol #{SecureRandom.hex(4)}", current_admin: @admin)
    @sub_process = @protocol.sub_processes.create!(name: 'Preview Notifications', current_admin: @admin)
    @protocol_event = @sub_process.protocol_events.create!(name: 'Sent', current_admin: @admin)
    sign_in @user
  end

  describe 'GET /masters/:master_id/message_notifications/:id' do
    it 'redirects unauthenticated users to sign in' do
      sign_out :user

      get preview_path(master: @master, notification_id: 1)

      expect(response).to redirect_to('/users/sign_in')
    end

    it 'hides a master the user cannot access in the current app type' do
      grant_notification_read
      notification = create_notification
      add_tracker_history(@master, notification)
      Admin::UserAccessControl.create!(
        app_type: @user.app_type,
        user: @user,
        resource_type: :limited_access,
        resource_name: 'temporary_master',
        access: :limited,
        current_admin: @admin
      )
      @user.clear_has_access_to!

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Email preview content')
    end

    it 'forbids users without message_notifications table read access' do
      notification = create_notification
      add_tracker_history(@master, notification)

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).not_to include('Email preview content')
    end

    it 'does not show a notification without a tracker-history entry for the URL master' do
      grant_notification_read
      notification = create_notification

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Email preview content')
    end

    it 'does not show a notification tracked only against a different master' do
      grant_notification_read
      notification = create_notification
      other_master = Master.new(msid: rand(1_000_000_000), pro_id: rand(1_000_000_000))
      other_master.current_user = @user
      other_master.save!
      add_tracker_history(other_master, notification)

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Email preview content')
    end

    it 'returns not found for a non-numeric notification id' do
      grant_notification_read

      get preview_path(master: @master, notification_id: 'not-a-number')

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a nonexistent notification id' do
      grant_notification_read

      get preview_path(master: @master, notification_id: 9_999_999_999)

      expect(response).to have_http_status(:not_found)
    end

    it 'renders an email preview and only the recipient listed in tracker notes' do
      grant_notification_read
      notification = create_notification(
        recipients: %w[visible@example.test private@example.test],
        content: '<p>Email preview content</p>'
      )
      notification.update_column(:master_id, nil)
      add_tracker_history(@master, notification, recipient: 'visible@example.test')

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'email', 'Notification subject', 'visible@example.test', 'complete', 'Sent',
        formatted_notification_time(notification), 'Email preview content'
      )
      expect(response.body).not_to include('private@example.test')
    end

    it 'renders a list-style notification from the participant master that owns its tracker entry' do
      grant_notification_read
      email = 'list-preview@example.test'
      setup_access :player_contacts, user: @user
      @master.current_user = @user
      contact = @master.player_contacts.create!(
        current_user: @user,
        rec_type: 'email',
        data: email,
        source: 'nflpa',
        rank: 10
      )
      notification = create_notification(
        master: Master.find(-1),
        recipients: [{ list_type: 'dynamic_model__zeus_bulk_message_recipients', id: 1 }],
        content: '<p>List notification preview content</p>'
      )
      notification.update_column(:master_id, -1)
      list_item = double('notification list item', data: email)
      allow(list_item).to receive(:record_item).with(no_exception: true).and_return(contact)
      allow(notification).to receive(:list_item_for)
        .with('dynamic_model__zeus_bulk_message_recipients', 1).and_return(list_item)

      Messaging::MessageNotificationTracker.create_for(notification)

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('list-preview@example.test', 'List notification preview content')
      expect(TrackerHistory.where(item_type: notification.class.name, item_id: notification.id)
                           .pluck(:master_id)).to eq [@master.id]
    end

    it 'renders SMS content as escaped plain text' do
      grant_notification_read
      notification = create_notification(
        message_type: 'sms',
        content: '<script>alert(1)</script> SMS preview content'
      )
      add_tracker_history(@master, notification, recipient: '+15555550123')

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'sms', 'complete', 'Sent', '+15555550123', formatted_notification_time(notification),
        '&lt;script&gt;alert(1)&lt;/script&gt; SMS preview content'
      )
      expect(response.body).not_to include('<script>')
    end

    it 'renders a failed notification with its failed time and content' do
      grant_notification_read
      notification = create_notification(status: 'failed', content: '<p>Failure preview content</p>')
      add_tracker_history(@master, notification)

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'email', 'failed', 'Failed', 'visible@example.test', 'Notification subject',
        formatted_notification_time(notification), 'Failure preview content'
      )
    end

    it 'sanitizes executable markup from email content' do
      grant_notification_read
      notification = create_notification(
        content: '<html><head><title>Unsafe sample</title></head><body><p>Safe email text</p><script>alert(1)</script><img src="x" onerror="alert(2)" onclick="alert(3)"><a href="javascript:alert(4)">Unsafe link</a></body></html>'
      )
      add_tracker_history(@master, notification)

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:ok)
      response_document = Nokogiri::HTML(response.body)
      iframe = response_document.at_css('iframe.message-notification-preview__email')
      expect(iframe).not_to be_nil
      expect(iframe['sandbox']).not_to match(/\ballow-(?:scripts|same-origin|forms)\b/)
      expect(response.body).not_to match(/<script\b|onerror\s*=|onclick\s*=|javascript:/i)

      srcdoc = iframe['srcdoc']
      expect(srcdoc).not_to match(/<script\b|onerror\s*=|onclick\s*=|javascript:/i)
      expect(Nokogiri::HTML(srcdoc).at_css('body').text).to include('Safe email text')
    end

    it 'keeps a full email document and its styles inside the preview iframe' do
      grant_notification_read
      title = 'PRESS App Message Notification'
      notification = create_notification(
        content: '<html><head><title>PRESS App Message Notification</title><style>body {font-family: sans-serif;}</style></head><body><p>Hello</p></body></html>'
      )
      add_tracker_history(@master, notification)

      get preview_path(master: @master, notification_id: notification.id)

      expect(response).to have_http_status(:ok)
      response_document = Nokogiri::HTML(response.body)
      iframe = response_document.at_css('iframe.message-notification-preview__email')
      expect(response_document.at_css('body').text).not_to include(title, 'font-family: sans-serif;')

      srcdoc_document = Nokogiri::HTML(iframe['srcdoc'])
      expect(srcdoc_document.at_css('head base')['target']).to eq('_blank')
      expect(srcdoc_document.at_css('head title').text).to eq(title)
      expect(srcdoc_document.at_css('head style').text).to include('font-family: sans-serif;')
      expect(srcdoc_document.at_css('body').text).to include('Hello')
      expect(srcdoc_document.at_css('body').text).not_to include(title)
    end

    it 'shows the notification subject when the tracker notes do not include it' do
      grant_notification_read
      notification = create_notification
      add_tracker_history(@master, notification)
      TrackerHistory.where(item_type: notification.class.name, item_id: notification.id)
                    .update_all(notes: "type: email\nto: visible@example.test")

      get preview_path(master: @master, notification_id: notification.id)

      subject_label = Nokogiri::HTML(response.body).at_css('dt:contains("Subject")')
      expect(subject_label.next_element.text).to eq('Notification subject')
    end

    it 'shows a placeholder when the tracker notes do not include recipients' do
      grant_notification_read
      notification = create_notification
      add_tracker_history(@master, notification)
      TrackerHistory.where(item_type: notification.class.name, item_id: notification.id)
                    .update_all(notes: "type: email\nsubject: Notification subject")

      get preview_path(master: @master, notification_id: notification.id)

      recipient_label = Nokogiri::HTML(response.body).at_css('dt:contains("To")')
      expect(recipient_label.next_element.text).to eq('(not recorded)')
    end

    it 'shows a placeholder subject for an email that was sent without one' do
      grant_notification_read
      notification = create_notification
      notification.update_column(:subject, nil)
      add_tracker_history(@master, notification)

      get preview_path(master: @master, notification_id: notification.id)

      subject_label = Nokogiri::HTML(response.body).at_css('dt:contains("Subject")')
      expect(subject_label.next_element.text).to eq('(no subject)')
    end
  end

  private

  def grant_notification_read
    setup_access :message_notifications, access: :read, user: @user
  end

  def create_notification(master: @master, message_type: 'email', status: 'complete', content: nil,
                          recipients: %w[visible@example.test private@example.test])
    layout_template = Admin::MessageTemplate.create!(
      name: "preview layout #{SecureRandom.hex(4)}",
      message_type:,
      template_type: :layout,
      template: message_type == 'email' ? '<html><body>{{main_content}}</body></html>' : '{{main_content}}',
      current_admin: @admin
    )
    subject = message_type == 'email' ? 'Notification subject' : nil
    content ||= message_type == 'email' ? '<p>Email preview content</p>' : 'SMS preview content'
    notification = Messaging::MessageNotification.create!(
      app_type: @user.app_type,
      user: @user,
      master:,
      item_type: 'Master',
      item_id: master.id,
      recipient_data: recipients,
      layout_template_name: layout_template.name,
      content_template_text: 'Notification template content',
      message_type:,
      subject:,
      generated_content: content
    )
    notification.update_column(:status, status)
    notification
  end

  def add_tracker_history(master, notification, recipient: 'visible@example.test')
    notes = ["type: #{notification.message_type}", "to: #{recipient}"]
    notes << "subject: #{notification.subject}" if notification.subject.present?
    master.current_user = @user
    master.trackers.create!(
      protocol_id: @protocol.id,
      sub_process_id: @sub_process.id,
      protocol_event_id: @protocol_event.id,
      event_date: Time.current,
      notes: notes.join("\n"),
      item_type: notification.class.name,
      item_id: notification.id
    )
  end

  def preview_path(master:, notification_id:)
    "/masters/#{master.id}/message_notifications/#{notification_id}"
  end

  def formatted_notification_time(notification)
    Formatter::DateTime.format(notification.updated_at, current_user: @user, current_timezone: :user)
  end
end
