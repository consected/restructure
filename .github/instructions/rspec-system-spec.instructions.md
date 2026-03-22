---
applyTo: 'spec/system/**'
---

# Rspec System Specs project coding standards


## System Specs

System specs are located in `spec/system/`. Follow Best Practices and Development Patterns below when implementing system specs. We write system specs to simulate real user/admin interactions through the UI as much as possible. Interacting with underlying Javascript is discouraged; use Jasmine tests for Javascript-specific behavior. 

The following information builds on For general Rspec standards: [Rspec project coding standards](instructions/rspec.instructions.md)

## Rspec System Spec Best Practices
1. **ALWAYS use helper methods for system specs** - read `spec/support/feature_support.rb` before starting to implement system spec tests
2. **Run `debug_process_status`** when fields/sections can't be found
3. **Wait for AJAX** using `finish_page_loading` and `finish_form_formatting` after interactions
4. **Expand UI sections before accessing fields** - forms load via AJAX
5. **Never write raw Capybara selectors in system specs**
6. **Run the full system spec suite locally before pushing changes** - `app-scripts/parallel_test.sh spec/system`

## Rspec System Specs Helper Methods Quick Reference

| Task | Helper Method | Example |
|------|--------------|------|
| Text input | `fill_in_field(name, value)` | `fill_in_field('description', 'My text')` |
| Dropdown | `select_from_dropdown_field(name, value)` | `select_from_dropdown_field('status', 'Active')` |
| Multi-select | `select_multiple_from_chosen(name, values)` | `select_multiple_from_chosen('tags', ['A', 'B'])` |
| Radio buttons | `set_yes_no_field(name, value)` | `set_yes_no_field('approved', 'yes')` |
| Checkbox | `set_checkbox_field(name, checked)` | `set_checkbox_field('active', true)` |
| Big select | `select_from_big_select_field(name, value)` | `select_from_big_select_field('grant', 'Title')` |
| Expand section | `expand_model_reference(name)` | `form = expand_model_reference('Grant Aims')` |
| Expand master by id | `expand_master_record(master_id: id)` | `expand_master_record(master_id: 123)` |
| Expand master by text | `expand_master_record(text: title)` | `expand_master_record(text: 'Proposal')` |
| Edit button | `click_edit_button_within_target(elem)` | `form = click_edit_button_within_target(form)` |
| Wait for AJAX | `finish_page_loading` | `finish_page_loading` |
| Debug current state | `debug_process_status` | `debug_process_status` |
| Available fields | `available_form_fields` | `available_form_fields` |

### First Steps When Stuck
1. Run `debug_process_status` to see current UI state
2. Check if section needs expanding: `expand_model_reference('Section Name')`
3. Check if edit button needs clicking: `click_edit_button_within_target(form)`
4. Verify show_if conditions are met for hidden fields
5. As last resort: `debug_state('action_name', 'description')` to save HTML snapshot, screenshot and UI status

## Details

### Rspec system test tips

To avoid 2FA logins blocking user tests, the following settings are recommended in test setup (in `before(:all)` block):
```ruby
change_setting('TwoFactorAuthDisabledForUser', true)
```

Never click on elements programmatically using Javascript if they may not be interactable. Instead, use JavaScript to scroll them into view first:
```ruby
edit_link = find('a', text: 'edit tracker record')
scroll_into_view(edit_link) # From the FeatureHelper module
sleep 0.5  # Allow time for scrolling
```
Then click the link:
```ruby
click_link 'edit tracker record'
```
If an HTML snapshot is needed for debugging, use the helper method:
```ruby
save_html_snapshot('/tmp/debug_page.html')
```

To capture console logs and CSP violations from the browser, use the helper methods:

```ruby
# Set up capture AFTER initial page load, BEFORE navigating to page to debug
visit '/'
setup_browser_console_capture

# Navigate and perform actions you want to debug
visit '/page/to/debug'
finish_page_loading
click_button 'Submit'

# Print captured logs with context description
print_browser_console_logs('After clicking Submit')

# Or retrieve logs programmatically without printing
result = get_browser_console_logs
puts "CSP violations: #{result[:csp_violations].count}"
result[:logs].each { |log| puts log }
```

The capture methods intercept `console.log`, `console.error`, `console.warn`, and CSP violation events.

### Things to Remember
- Standard string / varchar fields downcase data on storage and titleize on display. Keep this in mind when writing system specs that interact with user data fields.
- Some fields rely heavily on Javascript for rendering and interaction (e.g., chosen.js dropdowns, big select dialogs, custom rich text editors). Always use the provided helper methods to interact with these fields.
- Field visibility is controlled by `show_if` rules. Always set prerequisite fields first and allow time for the UI to update.
- Don't navigate directly to edit URLs; always use the UI flow to reach forms (e.g. </masters/123> then click edit button for the appropriate block).
- Route Changes happen when adding dynamic definition configurations - `DynamicModel.routes_reload` should be automatically run after model config changes, but may need manual invocation for some tests to work


### 🔍 Troubleshooting Decision Tree

#### "Field Not Found" Error
1. **Did you expand the section?** → Use `expand_model_reference('Section')` or `expand_embedded_reference('Name')`
2. **Did you click edit button?** → Use `click_edit_button_within_target(form)`
3. **Are show_if conditions met?** → Set prerequisite fields first, add `sleep 1`
4. **Check field name** → Run `available_form_fields` to see actual field names
5. **Still not found?** → Run `debug_process_status` and examine output

#### "Element Not Interactable" Error
1. **Scroll element into view** → Use `scroll_into_view(element)` or helper handles it automatically
2. **Wait for AJAX** → Call `finish_page_loading`
3. **Check if hidden by CSS** → Use helper methods which handle `visible: false`
4. **Check if in collapsed section** → Expand section first
5. **Check if read-only view** → Click edit button to make form editable

#### Empty Big Select / Dropdown
1. **Check database relationships** → Review YAML configuration foreign keys
2. **Verify test data exists** → Check setup creates necessary records
3. **Debug available options** → `puts field.all('option').map(&:text).inspect`
4. **Check query configuration** → Examine `blank_preset_value` in YAML

#### Test Passes Locally But Fails in CI
1. **Timing issues** → Add `finish_page_loading` or `finish_form_formatting` after AJAX interactions
2. **Race conditions** → Add small `sleep` after triggering show_if rules
3. **Different data state** → Ensure setup is idempotent and complete
4. **Browser differences** → Test with both Chrome and Firefox if possible

### Best Practices

Attempt to follow the real user / admin flow through the UI as much as possible, avoiding direct model manipulation except for setup/teardown. Avoid using `visit` to go directly to pages that would not normally be accessible through the UI flow. 

For example:
```ruby
# Don't do this:
visit "/redcap/project_admins/edit/#{project.id}"
# Do this instead:
visit "/redcap/project_admins?filter[id]=#{project.id}&perform_action=edit"
finish_page_loading
# If this doesn't work for some reason, check for Javascript errors
```

Any "edit" button represented by a glyphicon should be clicked in the UI rather than visiting the edit URL directly. These buttons typically have the HTML class something like: "edit-entity glyphicon glyphicon-pencil".

Any link or button that has the HTML attribute `data-remote="true"` (which may appear in a Rails helper like `<%= link_to ..., remote: true %>`) should be clicked in the UI rather than visiting the URL directly. This is because these links typically perform AJAX requests that update parts of the page dynamically.

Don't use Javascript to manipulate or show fields not visible due to `show_if` rules. These are hidden due to the business logic, and if the tests dictate they should be shown then this indicates a bug.

Avoid relying on `skip` or `xit` in spec files. Instead, fix the underlying issues causing test failures. The aim is not to have tests that simply run without errors, but to have tests that accurately verify the functionality.

If changes are made to a spec file, make sure to re-run the tests to verify they still pass. Nothing should be considered "fixed" until the tests pass successfully.


### Development Patterns

These patterns are essential for successful test implementation.

**CRITICAL:** ReStructure provides comprehensive helper methods in `spec/support/feature_support.rb`. **Always use these helpers** rather than writing raw Capybara selectors or inspecting HTML directly. The helpers handle AJAX waits, scrolling, visibility issues, and provide debug output when things fail.

### Common Error Messages and Solutions

#### `Capybara::ElementNotFound: Unable to find field "description"`
**Cause:** Field doesn't exist in current DOM state  
**Solutions:**
1. Expand section: `expand_model_reference('Section Name')`
2. Click edit: `click_edit_button_within_target(target)`
3. Check show_if: Set prerequisite fields first
4. Debug: `debug_process_status` or `available_form_fields`

#### `Selenium::WebDriver::Error::ElementNotInteractableError`
**Cause:** Element exists but can't be clicked/filled  
**Solutions:**
1. Scroll into view: `scroll_into_view(element)`
2. Use helper method (handles visibility): `fill_in_field('name', 'value')`
3. Wait for AJAX: `finish_page_loading`
4. Check if hidden by show_if rules
5. Check if read-only view (click edit button first)

#### `Selenium::WebDriver::Error::StaleElementReferenceError`
**Cause:** Element reference outdated after DOM update  
**Solutions:**
1. Re-find element after AJAX: `element = find('.class')`
2. Use `finish_page_loading` before re-finding
3. Use within block to limit scope: `within target { ... }`
4. Store container, not individual elements

#### Test fails with "Validation errors" but no details shown
**Cause:** Form validation failed silently  
**Solutions:**
1. Check validation: `puts_form_validation_errors`
2. Check alerts: `puts_alerts`
3. Take snapshot: `debug_state('after_submit', 'checking validation')`
4. Verify all required fields filled

#### `Ambiguous match, found 2 elements matching...`
**Cause:** Selector matches multiple elements  
**Solutions:**
1. Use more specific selector with ID or unique class
2. Use `within` block to limit scope: `within '#specific-form' { ... }`
3. Use helper methods which handle specificity
4. Check if duplicate elements exist in DOM

### Using Helper Methods (ALWAYS DO THIS)

**Field Interaction Helpers:**
```ruby
# DO NOT write raw selectors - use helpers!
fill_in_field('description', 'My description')           # Text fields
select_from_dropdown_field('funding_agency', 'NIH')     # Dropdowns (handles chosen.js)
select_multiple_from_chosen('topics', ['Cancer'])       # Multi-select
set_yes_no_field('reviewed_yes_no', 'yes')              # Radio buttons
set_checkbox_field('is_selectable', true)               # Checkboxes
edit_rich_text_editor_field('notes', 'Rich text')      # Custom editors
select_from_big_select_field('select_grant', 'Title')  # Big select dialogs
```

**Section Expansion Helpers:**
```ruby
expand_master_record(text: 'Proposal Title')            # Master record panel
form = expand_model_reference('Grant Aims')             # mr-expander sections
form = expand_embedded_reference('Grant Funded')        # Embedded references
form = click_edit_button_within_target(target_element)  # Edit buttons
```

**Debug Helpers (USE DURING DEVELOPMENT):**
```ruby
debug_process_status              # Shows EVERYTHING: alerts, fields, sections, buttons
user_instructions_placeholders    # User guidance text
available_form_fields            # All fields with types, visibility, values
available_model_reference_expanders  # Expandable sections
available_submit_fields          # Submit buttons
available_report_tabs            # Report tabs
puts_form_validation_errors      # Which fields failed validation
puts_alerts                      # Flash messages
puts_modals                      # Open modals
```

**Navigation Helpers:**
```ruby
finish_page_loading              # Wait for AJAX
finish_form_formatting           # Wait for UI formatting
click_report_tab('My Grant Aims')  # Click report tabs
scroll_into_view(element)        # Scroll element
save_html_snapshot('/tmp/debug.html')  # Save HTML (last resort)
```

**Enable debug output:**
```bash
app-scripts/headless_rspec.sh spec/system/your_spec.rb -e 'the example to run'
```

### Edit Button AJAX Pattern

Many forms in ReStructure display in **read-only view initially** and require clicking an edit button to load the editable form via AJAX.

**Pattern Recognition:**
- Forms showing as list items (`<li>`) with field values displayed as text
- Edit button (pencil icon) with classes like `edit-entity glyphicon glyphicon-pencil`
- Edit button has `data-remote="true"` attribute
- Specific edit button classes follow pattern: `edit-{resource_name}` (e.g., `edit-activity-log--project-assignment-grant-aim-grant-funded`)

**Implementation using helpers:**
```ruby
# WRONG: Try to fill fields immediately
within '#mr-expander-grant-funded' do
  fill_in 'reviewed_yes_no', with: 'yes'  # ❌ Field doesn't exist yet!
end

# CORRECT: Use helper to expand and click edit button
form = expand_embedded_reference('Grant Funded details')
form = click_edit_button_within_target(form)
finish_page_loading  # Wait for AJAX

# NOW use helpers to fill fields
within form do
  set_yes_no_field('reviewed_yes_no', 'yes')
  set_checkbox_field('is_selectable', true)
end

# CORRECT: Use helper to expand and click edit button
form = expand_embedded_reference('Grant Funded details')
form = click_edit_button_within_target(form)
finish_page_loading  # Wait for AJAX

# NOW use helpers to fill fields
within form do
  set_yes_no_field('reviewed_yes_no', 'yes')
  set_checkbox_field('is_selectable', true)
end
```

**Key Points:**
- Use `expand_embedded_reference` to expand sections
- Use `click_edit_button_within_target` to click edit buttons
- Use field helpers (`set_yes_no_field`, `set_checkbox_field`) for form fields
- Helpers handle scrolling, visibility, and AJAX waits automatically

### Hidden Form Fields (Custom UI Components)

Many form fields use custom styling with `visible: false` CSS, particularly radio buttons and checkboxes. **Use the helper methods** - they handle visibility automatically.

**Implementation using helpers:**
```ruby
# CORRECT: Helpers handle visibility automatically
set_yes_no_field('reviewed_yes_no', 'yes')  # ✅ Handles hidden radio
set_checkbox_field('is_selectable', true)   # ✅ Handles hidden checkbox
```

**Discovery Process (when fields not found):**
1. **Use helper first**: The helper will show available fields in error message
2. **Check process state**: `debug_process_status` or `available_form_fields`
3. **Only inspect HTML as last resort**: `save_html_snapshot('/tmp/debug.html')`

### Collapsible Section Pattern (mr-expander)

Activity log forms often use collapsible sections (`mr-expander`) that load content via AJAX when expanded. Form fields **do not exist** until the section is expanded. **Use the helper method** to handle this automatically.

**Pattern Recognition:**
- Caret icons (▶) with classes `glyphicon-triangle-right`
- Elements with IDs like `#mr-expander-{section-name}` (e.g., `#mr-expander-grant-aims`)
- Attribute `data-remote="true"` on section links
- Attribute `data-toggle-caret="true"`

**Implementation using helpers:**
```ruby
# WRONG: Try to access fields without expanding section
click_link proposal_title
fill_in 'Description', with: text  # ❌ Field doesn't exist yet!

# CORRECT: Use helper to expand section
expand_master_record(text: proposal_title)
form = expand_model_reference('Grant Aims')
finish_page_loading  # Helper handles this, but good practice

# NOW use helpers to fill fields
within form do
  fill_in_field('description', text)
  select_from_dropdown_field('funding_agency', 'NIH')
end
```
**Scroll Elements into View:**
```ruby
scroll_into_view(element)
```

**Debug Technique (when developing system specs):**
```ruby
# See what sections are available
debug_process_status  # Shows all model reference expanders

# Or specifically:
available_model_reference_expanders  # Lists all expandable sections
```

### Show_if Conditional Field Visibility

Fields may appear or disappear based on other field values via `show_if` configuration rules. This is pure business logic - DO NOT circumvent it by injecting JavaScript or forcibly showing hidden fields.

**Common Pattern:**
```ruby
# Field A controls visibility of Field B
select 'Grant', from: 'funding_source'  # Must select this first
sleep 1  # Allow show_if rules to process

# NOW Field B becomes visible
select_from_big_select_field('select_grant', grant_title)
```

**Key Points:**
- Always set prerequisite fields in the correct order
- Add small sleeps (0.5-1s) after changing fields that trigger show_if rules
- If a field can't be found, check if its show_if conditions are met
- Don't use JavaScript to force-show hidden fields - this indicates a test logic bug
- Check field configuration in YAML to understand dependencies

**Debugging show_if Issues:**
```ruby
# Check if field exists but is hidden
all('input[name*="field_name"]', visible: :all).count  # Should be > 0 if field exists

# If count is 0, field doesn't exist yet (wrong section or conditions not met)
# If count > 0 but field not interactable, check show_if conditions
```

### Search Field Naming Conventions

Search forms use specific field naming patterns that may differ from display labels.

**Discovered Patterns:**
- `search_attrs[title]` - for searching by title (NOT `search_attrs[text]`)
- `search_attrs[description]` - for description searches
- Field names in search forms are often prefixed with `search_attrs[...]`

**Implementation:**
```ruby
# WRONG: Guess the field name
fill_in 'Search', with: title  # ❌ Ambiguous

# CORRECT: Use exact field name
fill_in 'search_attrs[title]', with: title, wait: 5
```

**Discovery Process:**
```bash
# Extract search field names from HTML
irb --noverbose <<EOF
require 'nokogiri';
file = File.open("/tmp/search_page.html", "rb");
page = Nokogiri::HTML(file.read);
result = page.css('input[name*="search_attrs"]');
result.map {|r| r['name']}.join("\n")
EOF
```

### AJAX Timing and Validation

After form submissions, validation happens asynchronously. Always wait for **visible** confirmation text, not hidden text.

**Pattern:**
```ruby
# WRONG: Check for text that might be in non-visible areas
click_button 'Submit Proposal'
expect(page).to have_content('Project Submitted on', wait: 10)  # ❌ May be in collapsed section

# CORRECT: Check for text that's always visible after the action
click_button 'Submit Proposal'
finish_page_loading
expect(page).to have_content('Proposal is awaiting review', wait: 10)  # ✅ Visible status message
```

**Validation Error Handling:**
```ruby
expect_no_validation_errors
```

### Option Value Capitalization

Form option values may have unexpected capitalization that differs from configuration.

**Example:**
```yaml
# Configuration shows:
funding_source:
  - grant
  - no_funding
```

```ruby
# But actual HTML has:
# <option value="Grant">Grant</option>  # Capital G!

# WRONG:
select 'grant', from: 'funding_source'  # ❌ Option not found

# CORRECT:
select 'Grant', from: 'funding_source'  # ✅ Matches HTML exactly
```

**Discovery:**
```ruby
# Check available options
funding_field = find('select[name*="funding_source"]')
options = funding_field.all('option').map(&:text)
puts "Available options: #{options.inspect}"
# Output: ["", "No funding", "Grant", "(other)"]
```

### Table Relationships in Big Select Queries

Big select fields query database tables with specific foreign key relationships. Understanding these relationships is critical.

**Example Issue:**
```yaml
# Big select configuration for Analysis Plans:
select_grant:
  field_type: select_record_id_from_table_view_active_grants
  blank_preset_value:
    dynamic_model__viva_grants:
      activity_log_project_assignment_grant_aim_id: "{{activity_log__project_assignment_grant_aims.id}}"
```

**Problem:** Analysis Plans are `activity_log__project_assignments` (different table), so the query for grants with matching `activity_log_project_assignment_grant_aim_id` returns nothing.

**Lesson:** When big select returns no results:
1. Save the HTML: `File.write('/tmp/big_select.html', page.html)`
2. Check what items are available (may be just `["-1", "big-select-clear"]`)
3. Examine the YAML configuration for the field's query
4. Verify the foreign key relationships match the actual table structure
5. Determine if configuration needs updating or if test approach needs adjustment

### Helper Method Organization

Organize feature spec helpers by responsibility for maintainability:

**Structure:**
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

**Pattern:**
```ruby
# z_grant_aims_main.rb
module GrantAimsFeatureSupport
  ACTIVITY_LOG_NAME = 'Grant Aims'
  APP_TYPE_NAME = 'Projects'
  
  # Include all sub-modules
  include GrantAimsSetup
  include GrantAimsUserSetup
  # ... etc
end

# In spec file:
RSpec.describe 'Grant Aims Process', type: :feature do
  include GrantAimsFeatureSupport
  
  it 'completes full workflow' do
    # Use helpers from included modules
  end
end
```

### 2FA Configuration Ordering

Two-factor authentication settings must be configured BEFORE other setup code.

**Pattern:**
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

## Complete Workflow Examples

### Example 1: Creating Activity Log with Nested Forms

```ruby
# 1. Expand master record
expand_master_record(text: proposal_title)
finish_page_loading

# 2. Expand activity log section (loads via AJAX)
form = expand_model_reference('Grant Aims')
finish_page_loading

# 3. Click edit button to make form editable (if showing read-only view)
form = click_edit_button_within_target(form)
finish_page_loading

# 4. Fill conditional fields in correct order
within form do
  # First, set field that controls show_if visibility
  select_from_dropdown_field('funding_source', 'Grant')
  sleep 1  # Allow show_if rules to process
  
  # Now dependent field becomes visible
  select_from_big_select_field('select_grant', grant_title)
  
  # Fill remaining fields
  fill_in_field('description', 'My description')
  set_yes_no_field('approved', 'yes')
  set_checkbox_field('is_selectable', true)
end

# 5. Submit and verify
click_submit_field('Submit for Review')
finish_page_loading
expect_no_validation_errors
expect(page).to have_content('Submitted successfully', wait: 10)
```

### Example 2: Searching and Editing Records

```ruby
# 1. Navigate to search page
visit '/dynamic_model/grant_aims'
finish_page_loading

# 2. Fill search form with exact field names
fill_in 'search_attrs[title]', with: grant_title, wait: 5
click_button 'Search'
finish_page_loading

# 3. Verify result appears
expect(page).to have_content(grant_title, wait: 10)

# 4. Expand master record
expand_master_record(text: grant_title)
finish_page_loading

# 5. Expand and edit section
form = expand_embedded_reference('Grant Details')
form = click_edit_button_within_target(form)
finish_page_loading

# 6. Update fields
within form do
  fill_in_field('description', 'Updated description')
  select_from_dropdown_field('status', 'Active')
end

# 7. Save changes
click_submit_field('Save')
finish_page_loading
expect_no_validation_errors
```

### Example 3: Debugging When Something Goes Wrong

```ruby
# When you can't find a field or section:

# Step 1: Check overall page state
debug_process_status
# This shows: alerts, tabs, modals, sections, fields, buttons

# Step 2: Check specific items
available_form_fields          # See all fields with visibility
available_model_reference_expanders  # See expandable sections
available_submit_fields        # See submit buttons
puts_alerts                    # Check for error messages

# Step 3: If still stuck, save state
debug_state('stuck_point', 'cannot find description field')
# This saves HTML snapshot and screenshot

# Step 4: Analyze saved HTML
# In terminal:
# irb --noverbose <<EOF
# require 'nokogiri'
# file = File.open("/tmp/stuck_point.html", "rb")
# page = Nokogiri::HTML(file.read)
# result = page.css('[data-attr-name]')
# result.map {|r| r['data-attr-name']}.join("\n")
# EOF
```

## When Starting a New System Spec

### Setup Checklist

```ruby
RSpec.describe 'My Feature', type: :system do
  before(:all) do
    # ✅ 1. Disable 2FA FIRST (before any other setup)
    change_setting('TwoFactorAuthDisabledForUser', true)
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    
    # ✅ 2. Import configs and setup database
    SetupHelper.feature_setup
    
    # ✅ 3. Create test user with proper access
    @user = create_user('testuser@example.com')
    setup_access(@user, 'Grant Aims', user_type: 'read_write')
    
    # ✅ 4. Create necessary test data
    @grant = create_test_grant
    @proposal = create_test_proposal
  end
  
  before(:each) do
    # ✅ 5. Login for each test
    login_as(@user, scope: :user)
  end
  
  it 'completes the workflow' do
    # ✅ 6. Navigate to feature
    visit '/dashboard'
    finish_page_loading
    
    # Your test code here...
  end
end
```

### During Development

1. ✅ **Run `debug_process_status` liberally** - see what's actually on the page
2. ✅ **Use `debug_state(name, desc)` at key points** - save state for analysis
3. ✅ **Save HTML snapshots when stuck** - `save_html_snapshot('/tmp/debug.html')`
4. ✅ **Check for JavaScript errors** - look in browser console output
5. ✅ **Use helper methods exclusively** - don't write raw Capybara selectors
6. ✅ **Add `finish_page_loading` after AJAX** - ensure DOM is ready
7. ✅ **Follow real user flow** - don't use `visit` to skip steps

### Before Committing

1. ✅ **Run spec to verify it passes** - `bundle exec rspec spec/system/my_spec.rb`
2. ✅ **Remove debug statements** - clean up `debug_process_status`, `debug_state`, etc.
3. ✅ **Remove snapshots and screenshots** - delete temporary debug files
4. ✅ **Remove `skip` or `xit`** - fix issues instead of skipping tests
5. ✅ **Verify test follows real user flow** - no artificial shortcuts with `visit`
6. ✅ **Check test isolation** - ensure test doesn't depend on other tests
7. ✅ **Add comments for complex show_if logic** - explain conditional field dependencies

### Debug Techniques
Print and save state (including HTML snapshot and screenshot) during test development to diagnose issues.
```ruby
debug_state(name, description)
```

#### Extracting results from HTML files using CSS selectors

To extract using CSS selectors from a stored HTML file:

Get the first heading with class `some-classification` tag
```bash
irb --noverbose <<EOF
require 'nokogiri';
file = File.open("/tmp/saved.html", "rb");
page = Nokogiri::HTML(file.read);
first_style_tag = page.css('h1.some-classification')[0];
first_style_tag.text
EOF
```

Get all `data-attr-name` attribute values
```bash
irb  --noverbose <<EOF
require 'nokogiri';
file = File.open("/tmp/grant_aims_expanded.html", "rb");
page = Nokogiri::HTML(file.read);
result = page.css('[data-attr-name]');
result.map {|r| r['data-attr-name']}.join("\n")
EOF
```

#### Extracting results from debug screenshots in system specs
Use screenshots for debugging complex UI issues. To save a screenshot during a system spec test, use the following pattern:
```ruby
take_screenshot(name, description, force: true)
```


If an AI Agent can't read the screenshot directly, extract text from the screenshot image using Tesseract OCR:
```bash
tesseract /path/to/screenshot.png stdout
```


#### List Available Elements

Shows a YAML representation of the following information based on the state of the UI:

- error page block, if an error page rather than intended page is shown
- visible alerts
- report tabs
- visible modals
- for a stacked activity log process:
  - available mr-expander sections
  - user instructions placeholders at the top of the primary activity log block
  - available form fields with types, visibility, and current values
  - available submit buttons
  - visible embedded model reference "add" buttons

```ruby
debug_process_status  
```

If you need to dig deeper into the HTML, use Capybara selectors:
```ruby
# Find what sections are available
all('.mr-expander').each do |elem|
  puts_debug "ID: #{elem[:id]}, Text: #{elem.text}"
end

# Find all forms
all('form').each do |form|
  puts_debug "Action: #{form[:action]}, Method: #{form[:method]}"
end

# Find all inputs in a section
within result_target do
  all('input, select, textarea', visible: :all).each do |field|
    puts_debug "Name: #{field[:name]}, Type: #{field[:type]}"
  end
end
```


### Common Pitfalls and Solutions

| Pitfall | Symptom | Solution |
|---------|---------|----------|
| Field not found | `Unable to find field "Name"` | Check if mr-expander section is expanded |
| Element not interactable | `ElementNotInteractableError` | Add `visible: :all` or scroll into view |
| Stale element | `StaleElementReferenceError` | Re-find element after page updates |
| Wrong option selected | `Unable to find option "value"` | Check actual option values (capitalization) |
| Validation not working | Form submits but data not saved | Check if edit button was clicked to load editable form |
| AJAX timing issues | Intermittent failures | Use `finish_page_loading` and proper waits |
| Empty big select | Only shows clear option | Check table relationships in query configuration |
| Ambiguous match | `Ambiguous match, found 2 elements` | Use more specific selector (ID, unique class, within block) |

## UI Pattern Recognition Guide

### How to Identify What Pattern to Use

| If you see in HTML... | Pattern type | Use this helper |
|----------------------|-------------|------------------|
| `<li>` with text values, pencil icon | Edit button AJAX | `click_edit_button_within_target()` |
| Caret icon `▶`, `data-remote="true"` | Collapsible section | `expand_model_reference()` |
| `<select class="use-chosen">` | Chosen dropdown | `select_from_dropdown_field()` |
| `<select multiple>` | Multi-select chosen | `select_multiple_from_chosen()` |
| `<input class="use-big-select">` | Big select dialog | `select_from_big_select_field()` |
| Radio with `visible: false` CSS | Hidden yes/no field | `set_yes_no_field()` |
| Form field appears/disappears | show_if conditional | Set prerequisite + `sleep 1` |
| `data-toggle-caret="true"` | mr-expander section | `expand_model_reference()` |
| Class `edit-entity glyphicon-pencil` | Edit button | `click_edit_button_within_target()` |
| `data-remote="true"` link/button | AJAX action | Click in UI, don't visit URL directly |

### 🚨 CRITICAL: Always Use Helpers

**NEVER write raw Capybara code like this:**
```ruby
find('input[name="description"]').set('value')  # ❌ DON'T DO THIS
find('select#status').select('Active')          # ❌ DON'T DO THIS
find('.glyphicon-pencil').click                 # ❌ DON'T DO THIS
```

**ALWAYS use helper methods:**
```ruby
fill_in_field('description', 'value')           # ✅ DO THIS
select_from_dropdown_field('status', 'Active')  # ✅ DO THIS
form = click_edit_button_within_target(form)    # ✅ DO THIS
```

**Why helpers are critical:**
- Handle AJAX waiting automatically
- Scroll elements into view
- Handle hidden field visibility (`visible: false`)
- Provide detailed error messages with context
- Handle chosen.js, big select, and custom UI components
- Consistent behavior across all tests

