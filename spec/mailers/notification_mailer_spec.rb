# frozen_string_literal: true

# Tests for NotificationMailer#embed_inline_data_uri_images (issue #1148)
# Covers the private helper that converts <img src="data:image/...;base64,..."/> tags
# in the generated HTML into proper MIME inline attachments referenced by cid: URLs.
# Also covers the Settings::ProcessInlineDataUriImages setting (default true) that
# controls whether the transformation is applied.
# Includes MIME structure validation tests that confirm the generated email
# serialises to a well-formed RFC-2387 multipart/related message with matching
# Content-ID headers, mirroring the structure of tmp/agent-tmp/inline_image_example.eml.

require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport

  # Minimal valid 1x1 red pixel PNG encoded in base64
  PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwADhQGAWjR9awAAAABJRU5ErkJggg=='

  def setup_mailer_test
    create_admin
    @rec_user, = create_user
    create_user
    seed_database
    ActivityLog.define_models
    setup_access :player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    expect(@player_contact.master).to be_a Master

    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, user: @user
    @activity_log = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'from player', select_who: 'user', master: @player_contact.master
    )

    t = '<html><head></head><body>{{main_content}}</body></html>'
    @layout = Admin::MessageTemplate.create!(
      name: 'test mailer layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin
    )
  end

  # Build a MessageNotification whose content template is the given HTML string.
  # Calls mn.generate before returning so generated_text is set.
  def create_notification_with_content(content_html)
    content = Admin::MessageTemplate.create!(
      name: "test content #{SecureRandom.hex(4)}",
      message_type: :email,
      template_type: :content,
      template: content_html,
      current_admin: @admin
    )
    mn = Messaging::MessageNotification.create!(
      app_type: @user.app_type,
      user: @user,
      recipient_user_ids: [@rec_user],
      layout_template_name: @layout.name,
      content_template_name: content.name,
      item_type: @activity_log.class.name,
      item_id: @activity_log.id,
      master: @activity_log.master,
      message_type: :email,
      subject: 'Test Subject'
    )
    mn.generate
    mn
  end

  # Extract the HTML body from a mail that may be single-part or multipart/related
  def html_body(mail)
    (mail.html_part || mail).body.decoded
  end

  describe 'embed_inline_data_uri_images data URI conversion (issue #1148)' do
    before :example do
      setup_mailer_test
      change_setting('TestMail', true)
      change_setting('ProcessInlineDataUriImages', true)
    end

    after :example do
      change_setting('TestMail', false)
      change_setting('ProcessInlineDataUriImages', nil)
    end

    it 'converts a single PNG data URI image to an inline attachment with a cid: reference in the body' do
      content_html = %(<p>Look at this:</p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/>)
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      inline_attachments = mail.attachments.select(&:inline?)
      expect(inline_attachments.size).to eq(1)

      # The decoded bytes of the attachment must match the original base64 data
      expect(Base64.strict_encode64(inline_attachments.first.body.decoded)).to eq(PNG_BASE64)

      body = html_body(mail)
      expect(body).to include('src="cid:')
      expect(body).not_to include('src="data:')
    end

    it 'converts multiple data URI images to distinct inline attachments each with a unique cid' do
      img1 = %(<img src="data:image/png;base64,#{PNG_BASE64}" alt="img1"/>)
      img2 = %(<img src="data:image/png;base64,#{PNG_BASE64}" alt="img2"/>)
      content_html = "<p>Two images: #{img1} #{img2}</p>"
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      inline_attachments = mail.attachments.select(&:inline?)
      expect(inline_attachments.size).to eq(2)

      # Each attachment must have a unique Content-ID
      cids = inline_attachments.map(&:content_id)
      expect(cids.uniq.size).to eq(2)

      # Both img tags must be rewritten with cid: references
      expect(html_body(mail).scan('src="cid:').size).to eq(2)
    end

    it 'rewrites only the data URI image and leaves the https image src unchanged' do
      data_img = %(<img src="data:image/png;base64,#{PNG_BASE64}" alt="data"/>)
      https_img = '<img src="https://example.com/img.png" alt="remote"/>'
      content_html = "<p>#{data_img}#{https_img}</p>"
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      body = html_body(mail)
      expect(body).to include('src="https://example.com/img.png"')
      expect(body).not_to include('src="data:')

      inline_attachments = mail.attachments.select(&:inline?)
      expect(inline_attachments.size).to eq(1)
    end

    it 'assigns the correct file extension to the inline attachment filename based on MIME type' do
      [
        ['image/jpeg', '.jpg'],
        ['image/gif', '.gif'],
        ['image/svg+xml', '.svg']
      ].each do |mime_type, expected_ext|
        content_html = %(<p><img src="data:#{mime_type};base64,#{PNG_BASE64}" alt="test"/></p>)
        mn = create_notification_with_content(content_html)

        mail = NotificationMailer.send_message_notification(mn)

        inline_attachments = mail.attachments.select(&:inline?)
        expect(inline_attachments.size).to eq(1), "Expected 1 inline attachment for MIME type #{mime_type}"
        expect(inline_attachments.first.filename).to end_with(expected_ext),
          "Expected filename to end with #{expected_ext} for MIME type #{mime_type}"
      end
    end

    it 'leaves a malformed base64 data URI unchanged and does not raise an exception or add an attachment' do
      malformed = '<img src="data:image/png;base64,!!!INVALID!!!" alt="broken"/>'
      content_html = "<p>Bad image: #{malformed}</p>"
      mn = create_notification_with_content(content_html)

      expect do
        mail = NotificationMailer.send_message_notification(mn)
        expect(html_body(mail)).to include('data:image/png;base64,!!!INVALID!!!')
        expect(mail.attachments.select(&:inline?).size).to eq(0)
      end.not_to raise_error
    end

    it 'performs no transformation when Settings::ProcessInlineDataUriImages is false' do
      change_setting('ProcessInlineDataUriImages', false)

      content_html = %(<p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/></p>)
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      body = html_body(mail)
      expect(body).to include('src="data:image/png;base64,')
      expect(body).not_to include('src="cid:')
      expect(mail.attachments.select(&:inline?).size).to eq(0)
    end

    it 'includes both a .ics calendar attachment and an inline image attachment in the same email' do
      calendar_data = {
        'method' => 'REQUEST',
        'summary' => 'Test Meeting',
        'dtstart' => '2026-05-01 10:00:00',
        'dtend' => '2026-05-01 11:00:00',
        'organizer' => 'org@example.com'
      }
      content_html = %(<p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/></p>)
      content = Admin::MessageTemplate.create!(
        name: "cal test content #{SecureRandom.hex(4)}",
        message_type: :email,
        template_type: :content,
        template: content_html,
        current_admin: @admin
      )
      mn = Messaging::MessageNotification.create!(
        app_type: @user.app_type,
        user: @user,
        recipient_user_ids: [@rec_user],
        layout_template_name: @layout.name,
        content_template_name: content.name,
        item_type: @activity_log.class.name,
        item_id: @activity_log.id,
        master: @activity_log.master,
        message_type: :email,
        subject: 'Test Subject',
        extra_substitutions: { calendar_invite: calendar_data }
      )
      mn.generate
      mn.resolve_attachments

      mail = NotificationMailer.send_message_notification(mn)

      ics_attachment = mail.attachments['calendar.ics']
      expect(ics_attachment).not_to be_nil
      expect(ics_attachment.content_type).to include('text/calendar')
      expect(ics_attachment.inline?).to be false

      inline_attachments = mail.attachments.select(&:inline?)
      expect(inline_attachments.size).to eq(1)
      expect(inline_attachments.first.inline?).to be true
    end
  end

  describe 'MIME structure validation (issue #1148)' do
    before :example do
      setup_mailer_test
      change_setting('TestMail', true)
      change_setting('ProcessInlineDataUriImages', true)
    end

    after :example do
      change_setting('TestMail', false)
      change_setting('ProcessInlineDataUriImages', nil)
    end

    it 'produces a multipart/related part in the serialised message so that cid: references resolve' do
      content_html = %(<p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/></p>)
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      # The mail must be multipart
      expect(mail.multipart?).to be true

      # The serialised message must declare multipart/related — the Mail gem only
      # emits this in to_s, not directly via mail.parts at the runtime object level.
      expect(mail.to_s).to match(/Content-Type:\s*multipart\/related/i),
        'Expected multipart/related in the serialised MIME message for CID image resolution'

      # Additionally, the inline attachment must be present and the HTML must reference it
      inline_att = mail.attachments.find(&:inline?)
      expect(inline_att).not_to be_nil
      bare_cid = inline_att.content_id.delete('<>').strip
      expect(html_body(mail)).to include("cid:#{bare_cid}")
    end

    it 'sets Content-Disposition: inline on the image attachment' do
      content_html = %(<p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/></p>)
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      inline_att = mail.attachments.find(&:inline?)
      expect(inline_att).not_to be_nil
      expect(inline_att.content_disposition).to match(/\Ainline/i)
    end

    it 'has a Content-ID on the inline attachment that matches the cid: reference in the HTML body' do
      content_html = %(<p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/></p>)
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      inline_att = mail.attachments.find(&:inline?)
      expect(inline_att).not_to be_nil

      # Mail gem stores Content-ID as "<id@host>"; strip angle brackets to get bare cid
      raw_cid = inline_att.content_id                          # e.g. "<abc123@host>"
      bare_cid = raw_cid.delete('<>').strip                    # e.g. "abc123@host"

      body = html_body(mail)
      expect(body).to include("src=\"cid:#{bare_cid}\""),
        "Expected HTML body to contain src=\"cid:#{bare_cid}\" but got:\n#{body}"
    end

    it 'round-trips the image bytes correctly through base64 encode/decode' do
      original_bytes = Base64.strict_decode64(PNG_BASE64)
      content_html = %(<p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/></p>)
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)

      inline_att = mail.attachments.find(&:inline?)
      expect(inline_att).not_to be_nil
      expect(inline_att.body.decoded).to eq(original_bytes),
        'Decoded attachment bytes must match the original decoded base64 payload'
    end

    it 'serialises to a valid RFC-compliant .eml string with multipart/related and cid: reference' do
      content_html = %(<p><img src="data:image/png;base64,#{PNG_BASE64}" alt="test"/></p>)
      mn = create_notification_with_content(content_html)

      mail = NotificationMailer.send_message_notification(mn)
      eml_string = mail.to_s

      # The serialised message must declare the related content-type
      expect(eml_string).to match(/Content-Type:\s*multipart\/related/i)

      # The serialised message must carry a Content-ID header for the inline part
      expect(eml_string).to match(/Content-ID:/i)

      # The HTML part in the serialised message must reference that CID
      inline_att = mail.attachments.find(&:inline?)
      bare_cid = inline_att.content_id.delete('<>').strip
      expect(eml_string).to include("cid:#{bare_cid}")

      # The original data: URI must NOT appear in the serialised message
      expect(eml_string).not_to include('src="data:')
      expect(eml_string).not_to include("src='data:")

      # Content-Disposition header must say inline for the image part
      expect(eml_string).to match(/Content-Disposition:\s*inline/i)
    end
  end
end
