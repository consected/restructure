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

Drill down through associations with `\{\{association_name.attribute_name\}\}`

Other options are also available see information [For Conditions and Message Templates](#for-conditions-and-message-templates)

## Data from an embedded form item

When an item is embedded directly in another item through `references:`  or `embed:` configurations in dynamic definitions,
the embedded form data may be accessed in captions, etc, through:

- `\{\{embedded_item.attribute_name\}\}`

## Parse a JSON encoded string

- Parse a JSON string and allow its elements to be accessed:

  - `\{\{<string_is_json_hash>.json_parse.<key_name>\}\}`
  - `\{\{<string_is_json_array>.json_parse.<index>\}\}`
  - `\{\{<string_is_json_hash_with_array>.json_parse.<key_name>.<index>\}\}`

## Parse a YAML encoded string

- Parse a YAML string and allow its elements to be accessed, mirroring `json_parse`:

  - `\{\{<string_is_yaml_hash>.yaml_parse.<key_name>\}\}`
  - `\{\{<string_is_yaml_array>.yaml_parse.<index>\}\}`
  - `\{\{<string_is_yaml_hash_with_array>.yaml_parse.<key_name>.<index>\}\}`


## Drill into Object / JSON fields

Simply name the keys in turn:

- `\{\{save_trigger_results.identity.access_token\}\}`

If you want to return a value that is actually a Hash / Object, a special substitution format
using 3 curly braces is used to avoid the result being cast to a String.

- `\{\{{save_trigger_results.identity.data_structure\}\}}`

This returns a Hash or Object, which may be stored as raw data in a database JSON field for example.
Parts of the full data tree may be extracted and stored in this way.

## Specifying item in an array

When working with object or array fields, or the result of `json_parse` or `yaml_parse`, the following
mechanism allows selection of a specific element:

- `\{\{array.first\}\}`
- `\{\{array.last\}\}`
- `\{\{array.<number>\}\}` - zero based index

For complex items, such as `{ key: [ {}, {subkey: 'value'} ] }` then the following is possible:

`\{\{key.1.subkey\}\}`

## Insert a glyphicon

For example: `\{\{glyphicon_zoom_in\}\}`

## Conditional blocks

Conditional blocks of text and substitutions use `\{\{#if substitution_name\}\}any text, markup or substitutions\{\{else\}\}alternative block\{\{/if\}\}`
The conditional expression evaluates to true if the value is present (not false, nil or blank) and allows the appropriate block of text, markup and
substitutions to remain in the generated result.

Multiple conditions can be chained with `\{\{else if another_substitution_name\}\}` clauses before the optional `\{\{else\}\}` block.

## Conditional is blocks

Conditional `\{\{#is\}\}` blocks compare an attribute value to an expression using an operator:

`\{\{#is attribute_name 'operator' 'expression'\}\}content\{\{/is\}\}`

If the comparison is true, the content is included in the result. An optional `\{\{else\}\}` block is shown when the comparison is false.

`\{\{#is attribute_name 'operator' 'expression'\}\}truthy content\{\{else\}\}falsy content\{\{/is\}\}`

Multiple conditions can be chained using `\{\{else is attribute_name 'operator' 'expression'\}\}` clauses:

`\{\{#is status '==' 'active'\}\}Active\{\{else is status '==' 'pending'\}\}Pending\{\{else\}\}Unknown\{\{/is\}\}`

### Supported operators

For string and list comparisons:

- `===` — true if both are blank, or both equal
- `==` — true if both are blank, or both equal
- `!==` — true unless both are blank or both equal
- `!=` — true unless both are blank or both equal
- `in` — true if the attribute value is contained within the expression (expression treated as a list)
- `!in` — true if the attribute value is NOT contained within the expression
- `includes` — true if the string matches the expression (as a regex pattern) or the array includes the expression
- `!includes` — true if the string does NOT match the expression

For null or blank comparisons:

- variable is null or empty string, use `\{\{#is varname "===" ""\}\}`
- variable is not null or empty string, use `\{\{#is varname "!==" ""\}\}`

For numeric comparisons (attribute must be an integer):

- `>=` — greater than or equal to
- `<=` — less than or equal to
- `>` — greater than
- `<` — less than

### Expression values

The expression can be one of:

- A quoted string: `'value'` or `"value"`
- An integer (no quotes): `42`
- The literal `null` to represent nil/blank
- Another attribute name (substitution tag name), to compare two attribute values at runtime

## For Conditions and Message Templates

Since conditions and message templates are processed on the server side, associations and other server side processable items may be used within substitutions.

Form captions do not have access to this data, so will return blank results.

### Selecting an item from an association

When working with an association, pick a specific element:

- `\{\{association.first\}\}`
- `\{\{association.last\}\}`
- `\{\{association.<number>}\}` - zero based index

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

- Additionally, for the current user, a tag will be added to allow conditional substitutions based on roles the user has:
  - current_user_roles.[each role name underscored]
    for example: current_user_roles.reviewer___special_task for "reviewer - special task" role name

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
  - resource_name
  - item_type_name
  - table_name

- Item definition details
  - definition_resource_name
  - definition_item_type_name
  - default_embed_resource_name

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

### Text formatting

- **capitalize** - Converts the first character to uppercase and the rest to lowercase
  - Example: `"hello WORLD"` → `"Hello world"`
- **titleize** - Converts each word's first character to uppercase (title case)
  - Example: `"hello world testing"` → `"Hello World Testing"`
- **uppercase** - Converts all characters to uppercase
  - Example: `"Hello World"` → `"HELLO WORLD"`
- **lowercase** - Converts all characters to lowercase
  - Example: `"Hello WORLD"` → `"hello world"`
- **underscore** - Converts camelCase or spaces to snake_case format
  - Example: `"firstName"` → `"first_name"`, `"First Name"` → `"first name"`
- **hyphenate** - Converts spaces to hyphens
  - Example: `"hello world test"` → `"hello-world-test"`
- **id_hyphenate** - Converts to a hyphenated identifier (alphanumeric with hyphens, ending with hyphen)
  - Example: `"Hello World!"` → `"hello-world-"`
- **id_underscore** - Converts to an underscored identifier (alphanumeric with underscores, ending with underscore)
  - Example: `"Hello World!"` → `"hello_world_"`
- **initial** - Returns the first character in uppercase
  - Example: `"john"` → `"J"`
- **first** - Returns the first character as-is
  - Example: `"hello"` → `"h"`
- **last** - Returns the last character of string or last element of array
  - Example: `"hello"` → `"o"`, `["a", "b", "c"]` → `"c"`
- **strip** - Removes leading and trailing whitespace
  - Example: `"  hello world  "` → `"hello world"`
- **plaintext** - Converts newlines to `<br>` tags (HTML may be sanitized in some contexts)
  - Example: `"Line 1\nLine 2"` → `"Line 1<br>Line 2"`
- **markup** - Converts Markdown text to HTML
  - Example: `"# Title\n\n**Bold**"` → `"<h1>Title</h1>\n\n<p><strong>Bold</strong></p>"`
- **ignore_missing** - Returns the value or empty string if nil/missing
  - Example: `nil` → `""`, `"present"` → `"present"`
- **no_html_tag** - Pass-through formatter that returns the value unchanged
  - Example: `"any value"` → `"any value"`

### Date and time formatting

- **age** - Calculates age in years from a date value
  - Example: Birth date `1990-03-15` (for someone born March 15, 1990) → `34` (current age)
- **date** - Formats a date according to user's date format preference (e.g., mm/dd/yyyy or dd/mm/yyyy)
  - Example: `2023-12-25` → `12/25/2023` (US format) or `25/12/2023` (UK format)
- **date_time** - Shows date and time as it was set without adjusting to user's timezone, using user's date/time format
  - Example: `2023-12-25 14:30:00 UTC` → `12/25/2023 2:30 pm` (US) or `25/12/2023 14:30` (24-hour)
- **date_time_with_zone** - Forces the stored timezone to user's timezone preference without changing the date
  - Example: `2023-12-25 14:30:00 UTC` → `25/12/2023 2:30 pm` (keeps same date/time, adds user's timezone)
- **date_time_show_zone** - Adjusts date/time to user's timezone and displays the timezone at the end
  - Example: `2023-12-25 14:30:00 UTC` → `25/12/2023 9:30 am Eastern Time (US & Canada)`
- **time** - Time only including hours:minutes in the user's timezone
  - Example: `2023-12-25 14:30:00 UTC` → `9:30 am` (EST) or `14:30` (24-hour format)
- **time_ignore_zone** - Time only including hours:minutes without timezone adjustment
  - Example: `2023-12-25 14:30:00 UTC` → `2:30 pm` or `14:30`
- **time_with_zone** - Forces the time to the user's preferred timezone
  - Example: `2023-12-25 14:30:00 UTC` → `9:30 am` (converted to user's timezone)
- **time_show_zone** - Adjusts time to user's timezone and displays the timezone at the end
  - Example: `2023-12-25 14:30:00 UTC` → `9:30 am Eastern Time (US & Canada)`
- **time_sec** - Time for hours:minutes:seconds
  - Example: `2023-12-25 14:30:45 UTC` → `9:30:45 am` or `14:30:45`
- **dicom_datetime** - Formats date/time in DICOM format (YYYYMMDDHHMMSS+0000)
  - Example: `2023-12-25 14:30:45 UTC` → `20231225143045+0000`
- **dicom_date** - Formats date in DICOM format (YYYYMMDD)
  - Example: `2023-12-25` → `20231225`
- **redcap_date** - Formats date in REDCap format (YYYY-MM-DD)
  - Example: `December 25, 2023` → `2023-12-25`
- **iso8601_datetime** - Formats date/time in ISO 8601 format (YYYY-MM-DDTHH:MM:SS+00:00)
  - Example: `2023-12-25 14:30:45 UTC` → `2023-12-25T14:30:45+00:00`

### Array processing

- **compact** - Removes blank/empty elements from array
  - Example: `["apple", "", "banana", nil, "cherry"]` → `["apple", "banana", "cherry"]`
- **sort** - Sorts array elements in ascending order
  - Example: `["cherry", "apple", "banana"]` → `["apple", "banana", "cherry"]`
- **sort_reverse** - Sorts array elements in descending order
  - Example: `["apple", "banana", "cherry"]` → `["cherry", "banana", "apple"]`
- **uniq** - Removes duplicate elements from array
  - Example: `["apple", "banana", "apple", "cherry"]` → `["apple", "banana", "cherry"]`
- **markdown_list** - Converts array to Markdown unordered list format
  - Example: `["apple", "banana", "cherry"]` → `"- apple\n- banana\n- cherry"`
- **html_list** - Converts array to HTML unordered list format
  - Example: `["apple", "banana", "cherry"]` → `"<ul><li>apple</li>\n  <li>banana</li>\n  <li>cherry</li></ul>"`

### Array joining

- **join_with_space** - Joins array elements with spaces
  - Example: `["hello", "world", "test"]` → `"hello world test"`
- **join_with_comma** - Joins array elements with commas and spaces
  - Example: `["apple", "banana", "cherry"]` → `"apple, banana, cherry"`
- **join_with_csv** - Joins array elements in CSV format with proper escaping for commas and quotes
  - Example: `["John", "Doe, Jr.", "Manager"]` → `"John,\"Doe, Jr.\",Manager"`
- **join_with_semicolon** - Joins array elements with semicolons and spaces
  - Example: `["item1", "item2", "item3"]` → `"item1; item2; item3"`
- **join_with_pipe** - Joins array elements with pipe characters
  - Example: `["field1", "field2", "field3"]` → `"field1|field2|field3"`
- **join_with_dot** - Joins array elements with dots
  - Example: `["www", "example", "com"]` → `"www.example.com"`
- **join_with_at** - Joins array elements with @ symbols (useful for email addresses)
  - Example: `["user", "example.com"]` → `"user@example.com"`
- **join_with_slash** - Joins array elements with forward slashes
  - Example: `["home", "user", "documents"]` → `"home/user/documents"`
- **join_with_newline** - Joins array elements with newlines
  - Example: `["line1", "line2", "line3"]` → `"line1\nline2\nline3"`
- **join_with_2newlines** - Joins array elements with double newlines
  - Example: `["paragraph1", "paragraph2"]` → `"paragraph1\n\nparagraph2"`

### String splitting

- **split_space** - Splits string into array by spaces
  - Example: `"hello world test"` → `["hello", "world", "test"]`
- **split_lines** - Splits string into array by newlines
  - Example: `"line1\nline2\nline3"` → `["line1", "line2", "line3"]`
- **split_comma** - Splits string into array by commas
  - Example: `"apple,banana,cherry"` → `["apple", "banana", "cherry"]`
- **split_csv** - Parses CSV string into array with proper handling of quoted values
  - Example: `"John,\"Doe, Jr.\",Manager"` → `["John", "Doe, Jr.", "Manager"]`
- **split_semicolon** - Splits string into array by semicolons
  - Example: `"item1;item2;item3"` → `["item1", "item2", "item3"]`
- **split_pipe** - Splits string into array by pipe characters
  - Example: `"field1|field2|field3"` → `["field1", "field2", "field3"]`
- **split_dot** - Splits string into array by dots
  - Example: `"www.example.com"` → `["www", "example", "com"]`
- **split_at** - Splits string into array by @ symbols
  - Example: `"user@example.com"` → `["user", "example.com"]`
- **split_slash** - Splits string into array by forward slashes
  - Example: `"home/user/documents"` → `["home", "user", "documents"]`

### Data conversion

- **yaml** - Converts object to YAML format (without document separator)
  - Example: `{"name": "John", "age": 30}` → `"name: John\nage: 30"`
- **json** - Converts object to pretty-formatted JSON
  - Example: `{"name": "John", "age": 30}` → `"{\n  \"name\": \"John\",\n  \"age\": 30\n}"`
- **general_selection_label** - Returns the general selection label in place of the field value, if one exists
  - Example: For a status field with value `"active"` → `"Active"` (shows the display label instead of the code)

### Numeric indexing

Additionally, if the formatter is an integer number the following rules apply:

- if the attribute being applied to is a string, take the left-most characters from position 0 up to and including the number specified (0-based inclusive range)
  - Example: `"Hello World"` with formatter `4` → `"Hello"` (characters 0 through 4)
- if the attribute being applied to is an array, take the specified item (zero based index)
  - Example: `["first", "second", "third"]` with formatter `1` → `"second"` (index 1)
