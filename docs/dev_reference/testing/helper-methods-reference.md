# Helper Methods Reference

## Location

All helper methods are defined in `spec/support/feature_support.rb`.

## Core Philosophy

**DO NOT** write raw Capybara selectors or inspect HTML directly. Use these helper methods:

- They handle AJAX waits automatically
- They scroll elements into view
- They handle visibility issues (hidden fields)
- They provide debug output when things fail
- They work with custom UI components (chosen.js, big select, rich text editors)

## Field Interaction Helpers

### Finding Fields

```ruby
# Get single element by data-attr-name
element = element_for_field('description')

# Get all matching elements (e.g., radio buttons)
elements = elements_for_field('reviewed_yes_no')

# Get field ID
id = id_for_field('title')

# List all current field names
current_form_field_names  # Returns array of field names
```

### Text Fields

```ruby
# Fill in text input or textarea
fill_in_field('description', 'My description text')
fill_in_field('title', 'Proposal Title')

# Works with both simple fields and nested fields
# Automatically handles scrolling into view
```

### Dropdowns

```ruby
# Regular select boxes
select_from_dropdown_field('funding_agency', 'NIH')

# Chosen.js single select
select_from_dropdown_field('co_i_mentor', 'Dr. Smith')

# The helper automatically detects if it's a chosen field
```

### Multi-Select (Chosen.js)

```ruby
# Select multiple values from a multi-select dropdown
select_multiple_from_chosen('topics', ['Cancer', 'Diabetes', 'Treatment'])

# Automatically handles:
# - Opening the chosen dropdown
# - Selecting each item
# - Closing the dropdown
```

### Radio Buttons

```ruby
# Yes/No radio button groups
set_yes_no_field('reviewed_yes_no', 'yes')
set_yes_no_field('requires_revision', 'no')

# Handles hidden radio buttons automatically
# Uses data-attr-name attribute to find the correct field
```

### Checkboxes

```ruby
# Check or uncheck a checkbox
set_checkbox_field('is_selectable', true)   # Check it
set_checkbox_field('completed', false)      # Uncheck it

# Handles hidden checkboxes automatically
```

### Rich Text Editors

```ruby
# Custom rich text editor fields
edit_rich_text_editor_field('description', 'Full description with formatting')

# Handles:
# - Finding the editor component
# - Clicking to focus
# - Entering text
# - Verifying the hidden textarea was updated
```

### Big Select Dialogs

```ruby
# Open big select modal and select an item
select_from_big_select_field('select_grant', 'Grant Title Text')

# Handles:
# - Triggering focus event to open modal
# - Waiting for modal to appear
# - Finding items by key OR text (flexible matching)
# - Clicking the item
# - Verifying the field value was set
# - Debug output if no items found
```

## Section Expansion Helpers

### Master Record Expansion

```ruby
# Expand the master record panel (participant/subject)
expand_master_record(text: 'Grant Aims Proposal Title')

# Handles:
# - Finding the master-expander link
# - Checking if already expanded
# - Clicking to expand if collapsed
# - Waiting for AJAX to load details
# - Showing any alert messages
```

### Model Reference Expansion (mr-expander)

```ruby
# Expand a collapsible model reference section
form = expand_model_reference('Grant Aims')
form = expand_model_reference('Disclosures')

# Returns the form element for use in within blocks
within form do
  fill_in_field('description', text)
end

# Handles:
# - Finding the caret icon
# - Checking if already expanded
# - Clicking to expand if collapsed
# - Waiting for AJAX to load form
# - Scrolling form into view
```

### Embedded Reference Expansion

```ruby
# Expand an embedded add-item-button reference
form = expand_embedded_reference('Grant Funded details')

# Different from mr-expander - these create new embedded forms
# Returns the form element for further interaction
within form do
  set_yes_no_field('reviewed_yes_no', 'yes')
end
```

### Edit Button Handler

```ruby
# Click an edit button within a target element to load AJAX form
form = click_edit_button_within_target(target_element)

# Common pattern:
form = expand_embedded_reference('Grant Funded details')
form = click_edit_button_within_target(form)  # Loads editable form
# NOW form is in edit mode
```

## Navigation Helpers

### Page Loading

```ruby
# Wait for AJAX requests to complete and page to be ready
finish_page_loading

# Wait for UI formatting (no collapsing elements)
finish_form_formatting

# Use these after any AJAX action:
click_button 'Save'
finish_page_loading
```

### Report Tabs

```ruby
# Click a tab in the advanced-form-selections bar
click_report_tab('My Grant Aims')
click_report_tab('Project Action Required')

# Handles:
# - Finding the tab
# - Checking if already active
# - Clicking if not active
# - Waiting for content to load
# - Showing any alert messages
```

### Scrolling

```ruby
# Scroll an element into view
scroll_into_view(element)

# Automatically done by field helpers, but useful for other elements
```

### HTML Snapshots

```ruby
# Save current page HTML to a file
save_html_snapshot('/tmp/debug_page.html')

# Use as last resort for debugging
# Better to use debug_process_status first
```

## Debug Helpers for Development

### Complete Process Status

```ruby
# THE MOST USEFUL DEBUG HELPER
# Shows EVERYTHING about current state:
# - Alert messages
# - User instruction placeholders
# - All form fields (name, type, visible, value)
# - All expandable sections (mr-expanders)
# - All submit buttons

debug_process_status

# Run this when:
# - Developing new specs
# - Field not found errors
# - Form not behaving as expected
# - Understanding workflow state
```

Example output:

```yaml
Available form fields:
- field_name: description
  tag_name: textarea
  visible: true
  value: ''
  is_chosen: false
  is_big_select: false
  is_custom_editor: false
- field_name: funding_agency
  tag_name: select
  visible: true
  value: ''
  is_chosen: true
  options:
  - text: ''
    value: ''
    selected: true
  - text: NIH
    value: NIH
    selected: false
```

### User Instructions

```ruby
# Show visible placeholder captions (user guidance)
user_instructions_placeholders

# Returns hash of field_name => instruction text (markdown)
# Shows what the user sees as guidance at this workflow stage
```

Example output:

```
Placeholder: placeholder_not_started
Caption for user:
---
Prepare your grant aims proposal by completing the sections:
[Getting Started](#caret-target-mr-expander-getting-started)
[Grant Aims](#caret-target-mr-expander-grant-aims)
[Disclosures and Relationships](#caret-target-mr-expander-disclosures)
---
```

### Available Form Fields

```ruby
# Get detailed info about all form fields
available_form_fields

# Returns array of hashes with:
# - field_name (data-attr-name)
# - tag_name (input, select, textarea)
# - visible (true/false)
# - value (current value)
# - is_chosen, is_big_select, is_custom_editor flags
# - options (for select fields)
```

### Available Model Reference Expanders

```ruby
# List all expandable sections in current context
available_model_reference_expanders

# Returns array with:
# - type (mr-expander or mr-create)
# - label (section name)
# - id, mr_expander_id
# - visible status
```

### Available Submit Buttons

```ruby
# List all submit buttons
available_submit_fields

# Returns array with:
# - tag_name (input or button)
# - text (button text)
# - value
# - visible status
```

### Validation Errors

```ruby
# Show which fields have validation errors
puts_form_validation_errors

# Outputs:
# - Fields with has-error class
# - Error help messages
# - Field error details
```

### Alert Messages

```ruby
# Show any flash alert messages
puts_alerts

# Checks if alerts present first:
flashed_alert?              # Any alert
flashed_alert?('warning')   # Specific severity

# Get all alert messages:
alert_messages  # Returns array of {severity => text}
```

### Enable Debug Output

```bash
# Enable puts_debug output from all helpers
FEATURE_DEBUG=true bundle exec rspec spec/system/your_spec.rb

# Recommended for Agent development:
app-scripts/headless_rspec.sh spec/system/your_spec.rb
```

## Complete Examples

### Example 1: Filling a Form

```ruby
def fill_in_grant_aims_proposal_details(details:)
  # Expand master record
  expand_master_record(text: details[:title])
  
  # Expand form section
  form = expand_model_reference('Grant Aims')
  
  # See what's available (during development)
  debug_process_status
  
  # Fill fields using helpers
  within form do
    fill_in_field('ga_title', details[:ga_title])
    fill_in_field('description', details[:description])
    select_from_dropdown_field('funding_agency', details[:funding_agency])
    select_multiple_from_chosen('topics', details[:topics])
  end
  
  # Save
  within form do
    click_button 'Save'
  end
  
  finish_page_loading
  puts_alerts  # Show any messages
end
```

### Example 2: Embedded Form with Edit Button

```ruby
def complete_grant_funded_form(reviewed:, selectable:)
  # Expand the embedded reference
  form = expand_embedded_reference('Grant Funded details')
  
  # Click edit button to load AJAX form
  form = click_edit_button_within_target(form)
  finish_page_loading
  
  # See what fields are available
  debug_process_status
  
  # Fill fields
  within form do
    set_yes_no_field('reviewed_yes_no', reviewed)
    set_checkbox_field('is_selectable', selectable)
  end
  
  # Save
  within form do
    click_button 'Save'
  end
  
  finish_page_loading
  puts_alerts
end
```

### Example 3: Debugging When Field Not Found

```ruby
def troubleshoot_missing_field
  # Step 1: Check complete status
  debug_process_status
  # This shows all available fields, sections, buttons
  
  # Step 2: Check if in correct section
  available_model_reference_expanders
  # Shows what sections exist and can be expanded
  
  # Step 3: Try expanding the section
  form = expand_model_reference('Grant Aims')
  
  # Step 4: Check again
  within form do
    available_form_fields
    # Now shows fields inside that section
  end
  
  # Step 5: Try the helper - it will show available fields if not found
  fill_in_field('description', 'test')
  # Error message will list all available fields
end
```

## Best Practices

1. **Always use helpers** - Don't write raw Capybara selectors
2. **Use debug_process_status** liberally during development
3. **Enable FEATURE_DEBUG=true** to see what helpers are doing
4. **Check available fields** when getting "not found" errors
5. **Let helpers handle waits** - Don't add arbitrary sleeps
6. **Expand sections before accessing** fields inside them
7. **Use within blocks** to scope operations to specific forms
8. **Check alerts after actions** with `puts_alerts`

## Helper Method Cheat Sheet

| Task | Helper Method |
|------|---------------|
| Fill text field | `fill_in_field(name, value)` |
| Select dropdown | `select_from_dropdown_field(name, value)` |
| Multi-select | `select_multiple_from_chosen(name, values)` |
| Radio button | `set_yes_no_field(name, 'yes'/'no')` |
| Checkbox | `set_checkbox_field(name, true/false)` |
| Rich text | `edit_rich_text_editor_field(name, value)` |
| Big select | `select_from_big_select_field(name, value)` |
| Expand master | `expand_master_record(text: 'Title')` |
| Expand section | `expand_model_reference('Label')` |
| Expand embedded | `expand_embedded_reference('Label')` |
| Edit button | `click_edit_button_within_target(element)` |
| Wait AJAX | `finish_page_loading` |
| Click tab | `click_report_tab('Tab Name')` |
| Debug all | `debug_process_status` |
| See fields | `available_form_fields` |
| See sections | `available_model_reference_expanders` |
| Save HTML | `save_html_snapshot('/tmp/file.html')` |
