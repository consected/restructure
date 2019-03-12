class NotificationMailer < ActionMailer::Base

  def send_message_notification mn, logger: Rails.logger

    logger.info "Sending email for #{mn.id}"

    options = {
      to: mn.recipient_emails,
      from: mn.from_user_email,
      body: mn.generated_text,
      content_type: "text/html",
      subject: mn.subject
    }

    logger.info "Sending email options: #{options}"
    mail(options)
  end
end
