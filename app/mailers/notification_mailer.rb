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
  # Filter out any emails that are either invalid (no fully qualified domain name specified)
  # or where if there is a matching user it is not marked as disabled or "do not email".
  # Emails that do not match users are always acceptable, since we have no record of their preferences
  # and filtering must have been performed elsewhere
  # @param [Messaging::MessageNotification] notify
  # @param [Logger] logger - Rails logger
  # @return [Mail::Message]
  def send_message_notification(notify)
    Rails.logger.info "Sending email for #{notify.id}"
    messages = []

    emails = notify.recipient_emails.select do |email|
      email ||= ''
      res = fully_qualified_domain_name?(email)

      if res
        # Lookup the user email
        user = User.find_by(email: email&.downcase)

        # We can email if the email address is not a user, or
        # the user is not disabled and is not flagged "do not email"
        res = !user || (!user.disabled && !user.do_not_email)

        unless res
          msg = "send_message_notification email #{email} - " \
                "can not send disabled: #{user&.disabled} or do not email: #{user&.do_not_email}"
          Rails.logger.info msg
          messages << msg
        end

        res
      else
        msg = "send_message_notification email #{email} - " \
              'can not send due to no FQDN'
        Rails.logger.info msg
        messages << msg
      end
      res
    end

    if notify.from_user_email.blank?
      raise FphsException,
            'No FROM user set in notification. Check NotificationsFromEmail setting'
    end

    if emails.empty?
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
