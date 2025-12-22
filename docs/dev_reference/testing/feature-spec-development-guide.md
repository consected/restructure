# Feature Spec Development Guide

## Overview

This guide captures learnings from implementing end-to-end feature specs for ReStructure's Activity Log workflows, specifically from the Grant Aims process implementation. These patterns are essential for successful test development of similar workflows.

**IMPORTANT:** ReStructure provides comprehensive helper methods in `spec/support/feature_support.rb` for interacting with the UI. **Always use these helper methods** rather than directly inspecting HTML or using raw Capybara selectors. The helpers handle common patterns (AJAX waits, scrolling, visibility issues) and provide consistent error messages with debug information.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Helper Methods Overview](#helper-methods-overview)
3. [Critical UI Patterns](#critical-ui-patterns)
4. [Common Pitfalls](#common-pitfalls)
5. [Debugging Techniques](#debugging-techniques)
6. [Test Organization](#test-organization)
7. [Example Implementation](#example-implementation)

## Prerequisites

### Test Environment Setup

NOTE: environment or app specific features are excluded from Rspec runs by default. To include them,
use `app-scripts/headless_rspec.sh` and `app-scripts/not_headless_rspec.sh`, or if you ARE NOT an AI agent
use the appropriate environment variable `RUN_APP_SPECS=true`

```bash
# Run once after system reboot
app-scripts/setup-dev-filestore.sh

# Clean test database if needed
app-scripts/clean-test-db.sh

# Run tests - this ensures appropriate environment variables are set to include 
# `spec/system/apps/` and `spec/support/apps/`
app-scripts/headless_rspec.sh exec rspec spec/system/your_spec.rb

# Run with visible browser for debugging - this ensures appropriate environment variables are set to include
# spec/system/apps/ and spec/support/apps
app-scripts/not_headless_rspec.sh spec/system/your_spec.rb
```

### 2FA Configuration

**CRITICAL:** Two-factor authentication settings must be configured BEFORE other setup code:

```ruby
# WRONG:
before(:all) do
  SetupHelper.feature_setup
  change_setting('TwoFactorAuthDisabledForUser', true)  # ❌ Too late!
end

# CORRECT:
before(:all) do
  change_setting('TwoFactorAuthDisabledForUser', true)  # ✅ Before setup
  change_setting('TwoFactorAuthDisabledForAdmin', true)
  SetupHelper.feature_setup
end
```

## Helper Methods Overview

### Core Philosophy: Use Helpers, Not Raw HTML

The `spec/support/feature_support.rb` module provides battle-tested helper methods for all common UI interactions. **Do not** directly search HTML or use raw Capybara selectors when a helper exists.

### Field Interaction Helpers

All fields within edit forms use `data-attr-name` attributes. Use these helpers:

```ruby
# Find field element by name
element_for_field('description')           # Single element
elements_for_field('reviewed_yes_no')      # Multiple elements (radio buttons)

# Fill in text fields
fill_in_field('title', 'My Title')        # Text inputs, textareas

# Select from dropdowns
select_from_dropdown_field('funding_agency', 'NIH')  # Regular or chosen.js

# Multi-select with chosen.js
select_multiple_from_chosen('topics', ['Cancer', 'Diabetes'])

# Radio buttons yes/no fields
set_yes_no_field('reviewed_yes_no', 'yes')

# Checkboxes
set_checkbox_field('is_selectable', true)

# Rich text editors
edit_rich_text_editor_field('description', 'Full description text')

# Big select dialogs
select_from_big_select_field('select_grant', 'Grant Title')
```

**Why use helpers?**

- Handle `visible: :all` automatically when needed
- Scroll elements into view
- Wait for AJAX loading
- Provide debug info when fields not found (lists available fields)
- Work with custom UI components (chosen.js, big select, rich text editors)

**NOTE:** this doesn't apply to report form criteria fields. These use regular form `<label>` tags, and play nicely
with regulary Capybara methods such as `select` and `fill_in`.

### Section Expansion Helpers

```ruby
# Expand master record (participant/subject panel)
expand_master_record(text: 'Grant Aims Proposal')

# Expand model reference (mr-expander sections)
form = expand_model_reference('Grant Aims')  # Returns form element

# Expand embedded reference (nested add buttons)
form = expand_embedded_reference('Grant Funded details')

# Click edit button within a target
form = click_edit_button_within_target(target_element)
```

**Why use helpers?**

- Handle AJAX loading automatically
- Return the correct scoped element for further operations
- Handle both collapsed and already-expanded states
- Scroll sections into view
- Provide debug output showing what sections are available

### Debug Helpers for Spec Development

**Essential for understanding current state during spec development:**

```ruby
# Show complete process status (alerts, instructions, fields, expanders, buttons)
debug_process_status

# Individual debug components:
user_instructions_placeholders    # What users see as guidance
available_form_fields            # All fields with types, visibility, values
available_model_reference_expanders  # All expandable sections
available_submit_fields          # All submit buttons

# Validation errors
puts_form_validation_errors      # Show which fields failed

# Alert messages
puts_alerts                      # Show any flash messages
```

**Use `debug_process_status` liberally** during development:

```ruby
def fill_in_grant_aims_proposal_details(details:)
  expand_master_record(text: details[:title])
  form = expand_model_reference('Grant Aims')
  
  # See what's available before filling
  debug_process_status
  
  within form do
    fill_in_field('ga_title', details[:ga_title])
    fill_in_field('description', details[:description])
    select_from_dropdown_field('select_basic', details[:funding_agency])
  end

  # Fields that we know use "chosen.js" may need to be accessed outside the context of the form
  # They can be identified from the debug_process_status / available_form_fields by output for the field
  # that includes: `is_chosen: true`
  select_from_dropdown_field('select_using_chosen', details[:funding_agency])
  # Multi select forms that use "chosen.js" need to be accessed outside the context of the form
  select_multiple_from_chosen('tag_select_topics', details[:topics])
  # Big select fields have to be used outside the context of the form
  select_from_big_select_field('event_date', date)
  
  within form do
    click_button 'Save'
  end
  puts_form_validation_errors
  # Check state after filling
  debug_process_status
end
```

### Navigation Helpers

```ruby
# Wait for page loading
finish_page_loading              # Wait for AJAX, page ready
finish_form_formatting           # Wait for UI formatting

# Click report tabs
click_report_tab('My Grant Aims')

# Scroll element into view
scroll_into_view(element)

# Save HTML for offline inspection
save_html_snapshot('/tmp/debug_page.html')
```

### Example: Using Helpers vs. Raw HTML

```ruby
# ❌ WRONG: Direct HTML inspection
find('input[name="activity_log_project_assignment_grant_aim[embedded_item][description]"]').fill_in(with: text)

# ✅ CORRECT: Use helper
fill_in_field('description', text)

# ❌ WRONG: Manual section expansion
find('#mr-expander-grant-aims').click
sleep 2

# ✅ CORRECT: Use helper
form = expand_model_reference('Grant Aims')

# ❌ WRONG: Guessing what's available
fill_in 'Some Field', with: value  # May fail with cryptic error

# ✅ CORRECT: Check what's available first
debug_process_status  # Shows all available fields
fill_in_field('actual_field_name', value)
```

### Setting Debug Output

Enable detailed debug output. Override the standard `puts_debug` method like this:

```bash
  def puts_debug(message)
    puts "[FeatureName] [#{current_user_role}] #{message}"
  end
```

## Critical UI Patterns

### 1. Edit Button AJAX Pattern

**Problem:** Many forms display in read-only view initially and require clicking an edit button to load the editable form via AJAX.

**How to Recognize:**

- Forms showing as list items (`<li>`) with field values as text
- Edit button (pencil icon): `edit-entity glyphicon glyphicon-pencil`
- Button has `data-remote="true"` attribute
- Specific class pattern: `edit-{resource_name}`

**Solution:**

```ruby
form = expand_model_reference(label)

# WRONG: Try to fill fields immediately
within form do
  fill_in 'reviewed_yes_no', with: 'yes'  # ❌ Field doesn't exist yet!
end

# CORRECT: Click edit button first
# If we expect the button is there, and assume it is an error if not
form = click_edit_button_within_target(form)
# Otherwise, we can assume that the form may already be showing in edit mode - the button is therefore optional
form = click_edit_button_within_target(form, optional: true)

# NOW fill in fields

within form do
  fill_in 'reviewed_yes_no', with: 'yes'  # Field will now exist!
end
```

### 2. Hidden Form Fields (Custom UI)

**Problem:** Custom-styled form controls (radio buttons, checkboxes) use `visible: false` CSS. Standard Capybara selectors can't find them.

**How to Recognize:**

- Element exists in HTML but Capybara can't find it
- `style="display: none"` in HTML
- Custom JavaScript widgets

**Solution:**

```ruby
# WRONG: Standard selector
choose 'yes'  # ❌ Can't find hidden radio button

# CORRECT: Use visible: :all
within result_target do
  choose 'yes', visible: :all  # ✅ Finds hidden radio
  check 'is_selectable', visible: :all  # ✅ Finds hidden checkbox
end
```

**Discovery Process:**

Simply use `debug_process_status` to see a range of instructions to the user, available fields, available form expanders and submit buttons.

Alternatively:

1. Save HTML: `save_html_snapshot('/tmp/spec-debug-page.html')`
2. Search for field name in HTML
3. Check for `display: none` or hidden CSS
4. Add `visible: :all` to selector

### 3. Collapsible Sections (mr-expander)

**Problem:** Activity log forms use collapsible sections that load content via AJAX. Form fields DO NOT EXIST until expanded.

**How to Recognize:**

- Caret icons (▶): `glyphicon-triangle-right`
- IDs like `#mr-expander-{section-name}`
- Attributes: `data-remote="true"`, `data-toggle-caret="true"`

**Solution:**

```ruby
# WRONG: Try to access fields without expanding
click_link proposal_title
fill_in 'Description', with: text  # ❌ Field doesn't exist yet!

# CORRECT: Expand section first using the helper method
expand_master_record proposal_title

# WRONG: Expand the collapsible section manually
find('#mr-expander-grant-aims').click

# Use the helper method
expand_model_reference(human_label)

# NOW fields exist in DOM
fill_in_field(field_name, value)
```

### 4. Show_if Conditional Visibility

**Problem:** Fields appear/disappear based on other field values via configuration rules.

**Rule:** Don't circumvent show_if logic with JavaScript - if a field should be visible, set the prerequisite fields correctly.

**Solution:**

```ruby
# Field A controls visibility of Field B
select_from_dropdown_field 'funding_source', 'Grant'  # Must set this first

# NOW Field B becomes visible
select_from_big_select_field('select_grant', grant_title)
```

**Debugging:**

```ruby
# Easy way
available_form_fields
# returns fields with `visible: true` or `visible: false`

# Hard way
# Check if field exists but is hidden
count = all('input[name*="field_name"]', visible: :all).count
if count == 0
  # Field doesn't exist (wrong section or prerequisite not met)
elsif count > 0
  # Field exists but hidden (check show_if conditions)
end
```

### 5. Big Select Dialog Interaction

**Problem:** Big select fields open modal dialogs. Clicking isn't enough - must trigger focus event.

**Solution:**

```ruby
select_from_big_select_field(field_name, value)
```

**Empty Big Select Issue:**

If dialog only shows `["-1", "big-select-clear"]`:

1. Check YAML configuration for the field's query
2. Verify foreign key relationships match table structure
3. May indicate configuration issue or need different linking approach

### 6. Search Field Naming

**Problem:** Search field names may differ from display labels.

**Common Patterns:**

The HTML input name will be something like:

- `search_attrs[title]` (NOT `search_attrs[text]`)
- `search_attrs[description]`
- Fields prefixed with `search_attrs[...]`

That is why it is easier just to use:

`fill_in_field(field_name, value)`

**Discovery:**

```ruby
available_form_fields
```

Fallback if you really need to see the HTML:

```bash
# Extract search field names
irb --noverbose <<EOF
require 'nokogiri';
file = File.open("/tmp/search_page.html", "rb");
page = Nokogiri::HTML(file.read);
result = page.css('input[name*="search_attrs"]');
result.map {|r| r['name']}.join("\n")
EOF
```

### 7. AJAX Timing and Validation

**Problem:** Validation happens asynchronously. Must wait for VISIBLE confirmation.

**Solution:**

```ruby
# WRONG: Check for text that might be hidden
click_button 'Submit Proposal'
expect(page).to have_content('Project Submitted on', wait: 10)  # ❌ May be in collapsed section

# CORRECT: Check for always-visible text
click_button 'Submit Proposal'
finish_page_loading
expect(page).to have_content('Proposal is awaiting review', wait: 10)  # ✅ Visible status
```

**Error Handling:**

Check for form validation errors. If we expect none, the following expectation will pass and the testing will continue. Otherwise it will stop, reporting alerts, current field values and form field validation messages.

```ruby
# Handles the expectation around no validation errors after submitting a form
expect_no_validation_errors 
```

### 8. Option Value Capitalization

**Problem:** Option values may have unexpected capitalization.

**Example:**

```yaml
# Config shows:
funding_source:
  - grant
```

```ruby
# But HTML has:
# <option value="Grant">Grant</option>

# WRONG:
select_from_dropdown_field 'funding_source', 'grant'  # ❌

# CORRECT:
select_from_dropdown_field 'funding_source', 'Grant'  # ✅
```

**Discovery:**

```ruby
field = find('select[name*="funding_source"]')
options = field.all('option').map(&:text)
puts "Available: #{options.inspect}"
```

## Common Pitfalls

| Symptom | Cause | Solution |
|---------|-------|----------|
| `Unable to find field "Name"` | mr-expander not expanded | Expand section first |
| `ElementNotInteractableError` | Element hidden or obscured | Use `visible: :all` or scroll |
| `StaleElementReferenceError` | Page updated after finding element | Re-find element |
| `Unable to find option "value"` | Wrong capitalization | Check actual option values |
| Form submits but data not saved | Edit button not clicked | Click edit button for AJAX form |
| Intermittent failures | AJAX timing | Use `finish_page_loading` |
| Empty big select | Query config mismatch | Check table relationships |
| `Ambiguous match, found 2 elements` | Non-specific selector | Use ID, unique class, or within block |

## Debugging Techniques

### Save HTML Snapshots

```ruby
# At any point in test
save_html_snapshot('/tmp/debug_page.html')
```

```bash
# Examine with grep
grep -A 5 'field-name' /tmp/debug_page.html
```

### Extract with Nokogiri

```bash
# Get all field names
irb --noverbose <<EOF
require 'nokogiri';
file = File.open("/tmp/debug_page.html", "rb");
page = Nokogiri::HTML(file.read);
result = page.css('[data-attr-name]');
result.map {|r| r['data-attr-name']}.join("\n")
EOF
```

### List Available Elements

```ruby
# Find sections
all('.mr-expander').each { |e| puts "ID: #{e[:id]}" }

# Find forms
all('form').each { |f| puts "Action: #{f[:action]}" }

# Find inputs in section
within result_target do
  all('input, select, textarea', visible: :all).each do |field|
    puts "Name: #{field[:name]}, Type: #{field[:type]}"
  end
end
```

### Scroll Helper

```ruby
def scroll_into_view(element)
  page.execute_script('arguments[0].scrollIntoView(true);', element)
  sleep 0.5
end
```

## Test Organization

### Recommended Structure

```
spec/support/{feature_name}_feature_support/
├── {feature}_setup.rb          # Database, config import, access controls
├── {feature}_user_setup.rb     # User creation, role assignment
├── {feature}_login.rb          # Authentication flows
├── {feature}_navigation.rb     # Page navigation, waiting helpers
├── {feature}_actions.rb        # UI interactions, form filling
├── {feature}_expectations.rb   # Assertions and validations
└── z_{feature}_main.rb         # Main module that includes all others
```

### Main Module Pattern

```ruby
# z_grant_aims_main.rb
module GrantAimsFeatureSupport
  ACTIVITY_LOG_NAME = 'Grant Aims'
  APP_TYPE_NAME = 'Projects'

  # Include support and helper modules
  include FeatureHelper
  include FeatureSupport
  include MasterDataSupport
  include ModelSupport

  # Include all sub-modules
  include GrantAimsSetup
  include GrantAimsUserSetup
  include GrantAimsLogin
  include GrantAimsNavigation
  include GrantAimsActions
  include GrantAimsExpectations
end

# In spec file:
RSpec.describe 'Grant Aims Process', type: :feature do
  include GrantAimsFeatureSupport
  
  it 'completes full workflow' do
    setup_grant_aims_test
    investigator_creates_proposal(title: 'Test Proposal')
    # ...
  end
end
```

## Example Implementation

### Complete Form Filling Example

```ruby
def fill_in_grant_aims_proposal_details(details)
  puts_debug 'Filling in proposal details'
  result_target = expand_model_reference('Grant Aims')

  debug_process_status

  within result_target do
    expect_field_to_have_value(:ga_title, details[:title])
    edit_rich_text_editor_field('proposal_description', details[:description])
    fill_in_field('alt_co_i', details[:alt_co_i]) if details[:alt_co_i]
    set_yes_no_field('biospecimen_yes_no', details[:biospecimen_yes_no])

    fill_in_field('due_date', details[:due_date])
    select_from_dropdown_field('funding_expected_month', details[:funding_expected_month])
    fill_in_field('funding_expected_year', details[:funding_expected_year])
    select_from_dropdown_field('funding_end_expected_month', details[:funding_end_month])
    fill_in_field('funding_end_expected_year', details[:funding_end_year])
  end
  # Topics field uses chosen dropdown (multi-select)
  select_from_dropdown_field('funding_agency', details[:funding_agency])
  select_multiple_from_chosen('tag_select_topics', details[:topics])
  select_from_big_select_field('event_date', details[:event_date])

  within result_target do
    click_button 'Save'
  end

  expect_no_validation_errors
  puts_debug '✓ Proposal details filled in successfully'
end

```

### Complete Edit Button Example

```ruby
def complete_grant_funded_form(reviewed:, selectable:)
  puts_debug 'Completing Grant Funded form'
  
  # Navigate to Grant Funded section
  grant_funded_link = find('a', text: 'Grant Funded details')
  scroll_into_view(grant_funded_link)
  grant_funded_link.click
  finish_page_loading
  
  # Click edit button to load AJAX form
  edit_button = find('a.edit-activity-log--project-assignment-grant-aim-grant-funded')
  scroll_into_view(edit_button)
  edit_button.click
  finish_page_loading
  
  # Now fill in the form (fields are hidden, need visible: :all)
  result_target = find('#mr-expander-grant-funded')
  within result_target do
    choose reviewed, visible: :all  # Radio button
    check 'is_selectable', visible: :all if selectable  # Checkbox
    
    click_button 'Save'
  end
  
  finish_page_loading
  expect_no_validation_errors
  puts_debug '✓ Grant Funded form completed'
end
```

## Summary

Key takeaways for feature spec development:

1. **Expand sections before accessing fields** (mr-expander pattern)
2. **Click edit buttons for AJAX forms** (not just visit URLs)
3. **Use `visible: :all` for hidden fields** (custom UI components)
4. **Respect show_if rules** (don't force-show fields)
5. **Wait for AJAX** (`finish_page_loading` after navigation or `finish_form_formatting` after interactions)
6. **Use helper for big select** (not just click)
7. **Check actual option values** (capitalization matters)
8. **Validate with visible text** (not hidden confirmation)
9. **Save HTML for debugging** (inspect actual DOM state)
10. **Organize helpers by responsibility** (setup, actions, expectations)

These patterns emerged from real implementation experience and will save significant debugging time on future feature specs.
