{{#if template_block_ui_first_login}}
{{template_block_ui_first_login}}
{{else}}

# Welcome to {{environment_name}}

We hope that you find the application easy to use. Just in case, here are some quick pointers to get you started:

- you can always get to a help page like this by clicking the {{glyphicon_question_sign}} icon in the top navigation bar
- to close a panel (such as this help panel) look for the **×** icon in the top right-hand corner of the panel
- some forms a show a summary view when opened - to edit them, look for the orange {{glyphicon_edit}} icon in the top corner to switch to edit mode
- a range of user actions, such as changing your password and logging out are available from the {{glyphicon_user}} icon in navigation bar

---

If you need more help, contact your study representative or contact app administrator: [{{admin_email}}](mailto:{{admin_email}})
{{/if}}
