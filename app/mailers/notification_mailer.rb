# frozen_string_literal: true

#
# Perform mailing to valid users and non-user email addresses
class NotificationMailer < ActionMailer::Base
  MIME_EXT_MAP = {
    'image/png' => 'png',
    'image/jpeg' => 'jpg',
    'image/gif' => 'gif',
    'image/svg+xml' => 'svg',
    'image/webp' => 'webp',
    'image/tiff' => 'tiff',
    'image/bmp' => 'bmp'
  }.freeze

  DATA_URI_IMG_REGEX = /(<img\b[^>]*?\s)src=(['"])(data:(image\/[^;'"]+);base64,([A-Za-z0-9+\/=\s]+?))\2([^>]*?>)/im.freeze

  # Maximum decoded size (bytes) for an inline data-URI image. Images exceeding this
  # limit are skipped and left as-is to prevent memory exhaustion.
  MAX_DATA_URI_IMAGE_BYTES = (10 * 1024 * 1024).freeze
  #
  # Send a message notification
  # Filter invalid addresses and disabled users. Opted-out users are omitted; if they are the only
  # recipients and email delivery is not required, nothing is sent and no error is raised.
  # Addresses that do not match users remain acceptable since there is no preference to check.
  # @param [Messaging::MessageNotification] notify
  # @param [Logger] logger - Rails logger
  # @return [Mail::Message]
  def send_message_notification(notify)
    Rails.logger.info "Sending email for #{notify.id}"
    messages = []
    do_not_email_recipients = []
    emails = filter_emailable_recipients(notify, messages, do_not_email_recipients)

    if notify.from_user_email.blank?
      raise FphsException,
            'No FROM user set in notification. Check NotificationsFromEmail setting'
    end

    if emails.empty?
      if do_not_email_only?(notify, do_not_email_recipients)
        Rails.logger.info "No email sent for notification #{notify.id}: all recipients opted out"
        return
      end

      raise FphsException,
            "No TO emails set in notification for #{notify.recipient_emails}.\n#{messages.join("\n")}"
    end

    options = {
      to: emails,
      from: notify.from_user_email,
      subject: notify.subject
    }

    logger.info "Sending email options: #{options}"
    return if Rails.env.test? && !Settings::TestMail

    # Add any resolved attachments (e.g. calendar .ics files)
    notify.resolved_attachments.each do |att|
      attachments[att[:filename]] = {
        mime_type: att[:mime_type],
        content: att[:content]
      }
    end

    html = Settings::ProcessInlineDataUriImages ? embed_inline_data_uri_images(notify.generated_text) : notify.generated_text

    mail(options) do |format|
      format.html { render html: html.html_safe }
    end
  end

  #
  # Check there is at least one dot in the domain name
  # which we will consider is a valid fully qualified domain name
  # This removes '@test' and '@template'
  # @param [String] email
  # @return [Boolean]
  def fully_qualified_domain_name?(email)
    domain = email.split('@', 2)
    domain.last&.include?('.')
  end

  private

  # Select the addresses that can be emailed. Reasons for exclusion are appended to `messages` for the error text.
  # Opted-out users are also collected in `do_not_email_recipients`, so the caller can tell that apart from
  # other unsendable reasons (disabled user, no FQDN), which must still be treated as errors.
  def filter_emailable_recipients(notify, messages, do_not_email_recipients)
    notify.recipient_emails.select do |email|
      email ||= ''
      res = fully_qualified_domain_name?(email)

      if res
        user = User.find_by(email: email&.downcase)
        res = !user || !user.disabled
        if res && user&.do_not_email
          res = false
          do_not_email_recipients << email
        end

        unless res
          msg = "send_message_notification email #{email} - " \
                "can not send disabled: #{user&.disabled} or do not email: #{user&.do_not_email}"
          Rails.logger.info msg
          messages << msg
        end
      else
        msg = "send_message_notification email #{email} - " \
              'can not send due to no FQDN'
        Rails.logger.info msg
        messages << msg
      end
      res
    end
  end

  # True only when every recipient was excluded because of "do not email" and sending was not required.
  # Any other excluded recipient (disabled, invalid address) means the length differs, so an error is raised.
  def do_not_email_only?(notify, do_not_email_recipients)
    !notify.require_email_sent && do_not_email_recipients.present? &&
      do_not_email_recipients.length == notify.recipient_emails.length
  end

  #
  # Replace <img src="data:<mime>;base64,..."> tags with MIME inline attachments.
  # Each matching data URI is decoded, attached as a MIME inline part, and the src
  # attribute is rewritten to the corresponding cid: reference.
  # Images larger than MAX_DATA_URI_IMAGE_BYTES (decoded) are skipped with a warning.
  # @param [String] html
  # @return [String]
  def embed_inline_data_uri_images(html)
    return html unless Settings::ProcessInlineDataUriImages

    n = 0
    html.gsub(DATA_URI_IMG_REGEX) do
      leading_attrs = Regexp.last_match(1)
      quote = Regexp.last_match(2)
      mime_type = Regexp.last_match(4)
      payload = Regexp.last_match(5)
      trailing_attrs = Regexp.last_match(6)

      begin
        decoded_bytes = Base64.strict_decode64(payload.gsub(/\s/, ''))

        if decoded_bytes.bytesize > MAX_DATA_URI_IMAGE_BYTES
          Rails.logger.warn "embed_inline_data_uri_images: skipping oversized image for #{mime_type} (#{decoded_bytes.bytesize} bytes)"
          next Regexp.last_match(0)
        end

        ext = MIME_EXT_MAP.fetch(mime_type, 'bin')
        n += 1
        filename = "inline-#{n}-#{SecureRandom.hex(4)}.#{ext}"
        attachments.inline[filename] = { mime_type: mime_type, content: decoded_bytes }
        "#{leading_attrs}src=#{quote}#{attachments[filename].url}#{quote}#{trailing_attrs}"
      rescue ArgumentError => e
        Rails.logger.warn "embed_inline_data_uri_images: skipping malformed base64 for #{mime_type}: #{e.message}"
        Regexp.last_match(0)
      end
    end
  end
end
