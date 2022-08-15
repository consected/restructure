# Substitutions

Data from activity log and dynamic model records may be substituted into form captions, [message notifications, form dialogs and UI template blocks\}\}`(../message_templates/0_introduction.md).
Substitutions may also be used in calculated `if:` conditions in dynamic definitions.

Simple substitution uses double curly brackets `\{\{substitution_name\}\}` -

Conditional blocks of text and substitutions use `\{\{#if substitution_name\}\}any text, markup or substitutions\{\{else\}\}alternative block\{\{/if\}\}`
The conditional expression evaluates to true if the value is present (not false, nil or blank) and allows the appropriate block of text, markup and
substitutions to remain in the generated result.

## Common substitutions

In addition to the attributes within the current record, the following are available in most circumstances:

### Server constants

- `\{\{base_url\}\}`
- `\{\{admin_email\}\}`
- `\{\{environment_name\}\}`
- `\{\{password_age_limit\}\}`
- `\{\{password_reminder_days\}\}`
- `\{\{password_max_attempts\}\}`
- `\{\{mfa_disabled\}\}`
- `\{\{login_issues_url\}\}`
- `\{\{did_not_receive_confirmation_instructions_url\}\}`
- `\{\{notifications_from_email\}\}`
