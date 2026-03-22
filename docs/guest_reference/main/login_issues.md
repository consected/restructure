# Trouble Logging In?

If you are having trouble logging in, check you have followed the [login information](README.md), especially if this is your first time logging in.
{{#if mfa_disabled}} {{else}}

If you know your password is correct but you are still being told that your login information is incorrect, sometimes it is necessary to close the authenticator app on your mobile device and reopen it to get it to refresh correctly.
{{/if}}

---

Still having login issues, or have definitely forgotten your password: [reset your account login]({{login_issues_url}})
{{#if mfa_disabled}} {{else}}

If you have lost the account in your authenticator app, uninstalled the app or need to set up a new mobile device, the app administrator ({{admin_email}}) should be able to reset your account so you can set up a new two-factor authenticator app.
{{/if}}

---

{{#if allow_users_to_register}}

If you were allowed to register as a user without administrator assistance, you should receive a confirmation email with instructions for your first login.
[Didn't receive confirmation instructions?]({{did_not_receive_confirmation_instructions_url}})

---

{{/if}}

Need help? Contact the app administrator: [{{admin_email}}](mailto:{{admin_email}})
