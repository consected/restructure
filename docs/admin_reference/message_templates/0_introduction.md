# Message Templates

## Introduction

**Message Templates** provide configurations for message notifications, form dialogs and instructive UI blocks.

Administration is provided in [Admin: Message Templates](/admin/app_configurations)

### Message Notifications

Message notifications may be used by dynamic definition save triggers, causing a notification to be sent.
They are either an *email* or *sms* **message type**.

Each sent message is generated from a **layout** template providing a common template for styling messages,
and **content** template providing specific content and allowing curly braces as { {substitutions} }.

For emails, layout and content templates are configured as HTML. For the layout, full HTML including `<style>` tags
defining CSS may be used. This means that care must be taken to escape plain text.

For SMS messages, layout and content are plain text.

The content of a message is substituted into its layout in the position indicated by `{ {main_content} }` (without the spaces!)

### Dialog Templates

The *dialog* message type provides a mechanism for displaying lengthy sections of text within dynamic definition forms.

A *dialog* only ever has the *content* template type - *layout* types are ignored.

Formatting of the *dialog* content is typically markdown, but will be treated as HTML if one of the following HTML tags
(including appropriate attributes) is present in the text: `p br div ul hr`

### UI Templates

The *plain* message type with template type *content* is used to configure UI specific messages to the end user. These UI template
blocks are typically dependent on the server environment, and allow for admin configuration of the messages presented to guide
users in the app usage and meet the policies of a specific organization.

Only if a UI template block with the appropriate name is defined will the block appear in the UI. Although not essential, it is
recommended that the category option be set to **ui** to keep the definitions grouped.

The current UI template names are
used in the following forms / pages:

- `ui user login` - user login form
- `ui admin login` - administrator login form
- `ui new user registration` - user self-registration form
- `ui resend confirmation code` - form to request a registration confirmation code to be resent
- `ui change password` - password change form
- `ui resend unlock code` - form to request a locked account be unlocked
- `ui 2fa setup` - the page presented when a user has to set up their two-factor authentication app with a QR code
- `ui user preferences caption` - user preferences (timezones / formats) form
- `ui first login` - information for a new user on first login
