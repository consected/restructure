# Account Notifications

Users are notified by email when certain events occur related to their accounts:

- **password expiration reminder**: if a password is due to expire within {{password_reminder_days}} days
- **registration confirmation**: containing a verification code to confirm the registered email address (for users that can self-register)
- **password reset instructions**: when a user attempts to reset their password
- **password changed**: whenever a user's password is changed

Additionally, the server administrator is notified whenever a new user or admin is added to the system.

The notifications sent to users are configurable, in the [Message Templates](../message_templates/0_introduction.md) administration panel.

