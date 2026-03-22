# Message Templates

## Introduction

**Message Templates** provide configurations for message notifications, form dialogs and instructive UI blocks.

Administration is provided in [Admin: Message Templates](/admin/app_configurations)

[Substitutions](substitutions.md) of data can be performed with `\{\{data_attribute\}\}` notation.

### Message Notifications

Message notifications may be used by dynamic definition save triggers, causing a notification to be sent.
They are either an *email* or *sms* **message type**.

Each sent message is generated from a **layout** template providing a common template for styling messages,
and **content** template providing specific content and allowing curly braces as \{\{substitutions\}\}. Read more about [substitutions](../general/substitutions.md).

For emails, layout and content templates are configured as HTML. For the layout, full HTML including `<style>` tags
defining CSS may be used. This means that care must be taken to escape plain text.

For SMS messages, layout and content are plain text.

The content of a message is substituted into its layout in the position indicated by `\{\{main_content\}\}`

### User Account Notifications

Users are notified by email when certain events occur related to their accounts.

These require a layout template, named `general server notification` and the following email content templates:

- `server password expiration reminder`
- `server registration confirmation`
- `server password reset instructions`
- `server password changed`

When a new server is initially set up, these templates are created automatically. They should be edited to match the brand and content required by the organization.

### Dialog Templates

The *dialog* message type provides a mechanism for displaying lengthy sections of text within dynamic definition forms.

A *dialog* only ever has the *content* template type - *layout* types are ignored.

Formatting of the *dialog* content is typically markdown, but will be treated as HTML if one of the following HTML tags
(including appropriate attributes) is present in the text: `p br div ul hr`

### Public and Private Info Pages

The *dialog* message type also provides a mechanism for defining content to be displayed as a public or private information page.

#### Public Info Pages

Public information pages may be viewed by users whether they are logged in or not. Private information pages may only be viewed by
authenticated users.

A public info page is defined by selecting the message type *dialog*, template type *content* and category *public*

The name should be underscored or hyphenated, and represents the page *slug* for URLs used to access the page content:

`{{base_url}}/info_pages/<slug>`

#### Private Info Pages

A private info page is defined by selecting the message type *dialog*, template type *content* and any category, suffixed with
the the string `- info page`.

For example `study-category - info-page`.

The name should be underscored or hyphenated, and represents the page *slug* for URLs used to access the page content:

`{{base_url}}/info_pages/<study-category>__<slug>`

For example: `/info_pages/ipa_screening__intro_call_faq`

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
- `ui new user registration recaptcha error` - error block for user self-registration failure due to reCAPTCHA
- `ui resend confirmation code` - form to request a registration confirmation code to be resent
- `ui user change password` - password change form
- `ui user forgot password` - forgot password form
- `ui admin change password` - password change form
- `ui admin forgot password` - forgot password form
- `ui resend unlock code` - form to request a locked account be unlocked
- `ui 2fa setup` - the page presented when a user has to set up their two-factor authentication app with a QR code
- `ui user preferences caption` - user preferences (timezones / formats) form
- `ui first login` - information for a new user on first login
- `ui user credential text` - configurable text to appear in a user password change template document

### HTML Markup Snippets

- `ui page css - {app type name}` - plain CSS to place in a *style* block in the *head* section
- `ui page js - {app type name}` - plain Javascript to place in a *style* block in the *head* section
