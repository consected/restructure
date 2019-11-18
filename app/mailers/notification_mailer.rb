class NotificationMailer < ActionMailer::Base

  def send_message_notification mn, logger: Rails.logger

    logger.info "Sending email for #{mn.id}"

    emails = mn.recipient_emails.select {|e|
      e ||= ''
      # Check there is at least one dot in the domain name
      d = e.split('@')
      res = d[1] && d[1].include?('.')

      if res
        # Lookup the user email
        u = User.where(email: e).first

        # We can email if the email address is not a user, or
        # the user is not disabled and is not flagged "do not email"
        res = !u || (!u.disabled && !u.do_not_email)
      end
      res
    }

    options = {
      to: emails,
      from: mn.from_user_email,
      body: mn.generated_text,
      content_type: "text/html",
      subject: mn.subject
    }

    logger.info "Sending email options: #{options}"
    mail(options)
  end
end
