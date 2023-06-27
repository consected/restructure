# Substitutions

Data from activity log and dynamic model records may be substituted into form captions,
[message notifications, form dialogs and UI template blocks](../message_templates/0_introduction.md).

Substitutions may also be used in calculated `if:` conditions in dynamic definitions.

Simple substitution uses double curly brackets:

`\{\{substitution_name\}\}`

[Formatted substitutions](#formatting-results) add '::', for example:

`\{\{substitution_name::uppercase\}\}`

## Associations in Conditions and Message Templates

Since conditions and message templates are processed on the server side, associations
may be used within substitutions. Form captions do not have access to this data, so will return blank results.

Drill down through associations with `\{\{association_name.attribute_name}\}`

Other options are also available see information [For Conditions and Message Templates](#for-conditions-and-message-templates)

## Data from an embedded form item

When an item is embedded directly in another item through `references:`  or `embed:` configurations in dynamic definitions,
the embedded form data may be accessed in captions, etc, through:

- `\{\{embedded_item.attribute_name\}\}`

## Parse a JSON encoded string

- Parse a JSON string and allow its elements to be accessed:

  - `{\{<string_is_json_hash>.json_parse.<key_name>\}\}`
  - `{\{<string_is_json_array>.json_parse.<index>\}\}`
  - `{\{<string_is_json_hash_with_array>.json_parse.<key_name>.<index>\}\}`

## Drill into Object / JSON fields

Simply name the keys in turn:

- `\{\{save_trigger_results.identity.access_token\}\}`

## Specifying item in an array

When working with object or array fields, or the result of `json_parse`, the following
mechanism allows selection of a specific element:

- `{\{array.first}\}`
- `{\{array.last}\}`
- `{\{array.<number>}\}` - zero based index

For complex items, such as `{ key: [ {}, {subkey: 'value'} ] }` then the following is possible:

`{\{key.1.subkey}\}`

## Insert a glyphicon

For example: `{\{glyphicon_zoom_in}\}`

## Conditional blocks

Conditional blocks of text and substitutions use `\{\{#if substitution_name\}\}any text, markup or substitutions\{\{else\}\}alternative block\{\{/if\}\}`
The conditional expression evaluates to true if the value is present (not false, nil or blank) and allows the appropriate block of text, markup and
substitutions to remain in the generated result.

## For Conditions and Message Templates

Since conditions and message templates are processed on the server side, associations and other server side processable items may be used within substitutions.

Form captions do not have access to this data, so will return blank results.

### Selecting an item from an association

When working with an association, pick a specific element:

- `{\{association.first}\}`
- `{\{association.last}\}`
- `{\{association.<number>}\}` - zero based index

### Other related items

Special names, which are not actual associations but work like them are:

- ids: alternative id / value pairs
- app_protocols: classification protocols for current user's selected working app
- app_configurations: app configurations for current user's selected working app
- parent_item:
- referring_record: the record referring to this item (such as an activity log referring to a dynamic model)
- latest_reference: the most recent reference from the record
- embedded_item: the direct embedded item
- top_referring_record: work up the reference tree until the top accessible item
- constants: as defined with `_constants:` in a dynamic definition

Match model reference, based on the `references:` dynamic definition. This matches by underscored record type
or the resource name. The defined name can also match individual activity log extra log type steps, such as:

`activity_log__player_contact__step_1`

Note the primary name is singular, so don't use:

`activity_log__player_contacts__step_1`

### Common substitutions

In addition to the attributes within the current record, the following are available in most circumstances:

- User the item was created by:
  - created_by_user
  - created_by_user_email

- Last user registered as creating or changing the item:
  - item_user
  - user_email
  - user_preference
  - user_contact_info

- Current user interacting with the item:
  - current_user_instance
  - current_user (attributes)
  - current_user_email
  - user_email (if not already set by user_email above)
  - current_user_preference
  - current_user_contact_info
  - current_user_app_type_id
  - current_user_app_type_name
  - current_user_app_type_label

- Master record related to item:
  - master (full instance)
  - master_id
  - master_created_by_user
  - master_created_by_user_email

- Item details:
  - original_item (full instance)
  - alt_item (full instance if set)
  - data (data attribute)
  - class_name
  - save_trigger_results

### Server constants

- `\{\{base_url\}\}`
- `\{\{admin_email\}\}`
- `\{\{environment_name\}\}`
- `\{\{password_age_limit\}\}`
- `\{\{password_reminder_days\}\}`
- `\{\{password_max_attempts\}\}`
- `\{\{password_min_entropy\}\}`
- `\{\{password_min_length\}\}`
- `\{\{password_regex_requirements\}\}`
- `\{\{password_unlock_time_mins\}\}`
- `\{\{user_session_timeout\}\}`
- `\{\{allow_users_to_register\}\}`
- `\{\{two_factor_auth_issuer\}\}`
- `\{\{mfa_disabled\}\}`
- `\{\{login_issues_url\}\}`
- `\{\{did_not_receive_confirmation_instructions_url\}\}`
- `\{\{notifications_from_email\}\}`
- `\{\{allow_admins_to_manage_admins\}\}`

### Insert message template

To insert the first message template with a matching name:

- `\{\{template_block_<message template name>\}\}`

### Insert an embedded report

Insert and run a report to be embedded directly as a table:

- `\{\{embedded_report_<report resource name>\}\}`

For example:

- `\{\{embedded_report_messaging__players_selected\}\}`

For report queries that can use it, the `list_id` and `list_type` are passed:

- corresponding to the referring record, if there is one, or
- the current record

### "Add item" button

To show an "add item" button (for example, to a search description block) use:

- `\{\{add_item_button_<options>\}\}`

The options are one of:

- `<resource name>` - simply the dynamic definition resource name to add
- `to_master_<resource name>` - add the item to the master for either the referring record or current record
- `to_temporary_master_<resource name>` - add the item to a temporary master record (id: -1)

## Formatting results

Use the following structure `\{\{some_attribute::formatter\}\}`, where formatter is one of:

- capitalize
- titleize
- uppercase
- lowercase
- underscore
- hyphenate
- id_hyphenate
- id_underscore
- initial
- first
- age
- date
- date_time
- date_time_with_zone
- date_time_show_zone
- time
- time_with_zone
- time_show_zone
- time_sec
- dicom_datetime
- dicom_date
- join_with_space
- join_with_comma
- join_with_semicolon
- join_with_pipe
- join_with_dot
- join_with_at
- join_with_slash
- join_with_newline
- join_with_2newlines
- compact
- sort
- sort_reverse
- uniq
- markdown_list
- html_list
- plaintext
- strip
- split_lines
- split_comma
- split_semicolon
- split_pipe
- split_dot
- split_at
- split_slash
- markup
- ignore_missing
- last

Additionally, if the formatter is an integer number the following rules apply:

- if the attribute being applied to is a string, take the left-most characters up to the number specified (zero based)
- if the attribute being applied to is an array, take the specified item (zero based)
