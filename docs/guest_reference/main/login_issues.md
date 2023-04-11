# Trouble Logging In?

If you are having trouble logging in, check you have followed the [login information](README.md), especially if this is your first time logging in.
{{#if mfa_disabled}} {{else}}

You will need an authenticator app installed on your mobile device to complete your account setup and to login in the future.

Two-Factor authenticator apps that are known to work well:

- Duo Mobile
- Google Authenticator
- Microsoft Authenticator
- LastPass Authenticator
- Authy

These should be freely installable from your device’s app store.

The [login information](README.md) provides more information on the use of the two-factor authenticator apps when logging in.

If you know your password is correct but you are still being told that your login information is incorrect, sometimes it is necessary to close the authenticator app on your mobile device and reopen it to get it to refresh correctly.

If you have lost the account in your authenticator app, uninstalled the app or need to set up a new mobile device, the app administrator ({{admin_email}}) should be able to reset your account so you can set up a new two-factor authenticator app.
{{/if}}

---

Still having login issues, or have definitely forgotten your password{{#if mfa_disabled}}: {{else}} or lost your two-factor authentication: {{/if}}[reset your account login]({{login_issues_url}})

---

{{#if allow_users_to_register}}

If you were allowed to register as a user without administrator assistance, you should receive a confirmation email with instructions for your first login.
[Didn't receive confirmation instructions?]({{did_not_receive_confirmation_instructions_url}})

---

{{/if}}

Need help? Contact the app administrator: [{{admin_email}}](mailto:{{admin_email}})