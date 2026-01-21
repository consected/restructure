# ReStructure AI Coding Guidelines

## 🚨 QUICK REFERENCE FOR AGENTS

### Most Critical Rules (READ FIRST)
1. **When implementing new features, ALWAYS write and run corresponding Rspec specs** to cover new functionality
2. **Follow [Ruby on Rails Conventions](#ruby-on-rails-conventions)** below for all code you write
3. **Explain why changes to existing methods in models and other core components are necessary**
4. **Rspec tests must be written to demonstrate new functionality works as intended** not just to make tests pass
5. **If requirements are not clear, ask for clarification before proceeding**
6. **Never commit directly to `up-develop` or `develop` branches** - always create feature branches and pull requests

### Critical Rules for Running Terminal Commands
1. **Never set environment variables** - use app-scripts instead
2. **Always run tests after making changes** to verify functionality
3. **Never redirect scripts stdout or stderr to /dev/null**
4. **Never run commands in the background** - all commands exit when complete with success or failure codes

### Git and GitHub Usage
- Use `git` and `gh` CLI tools for version control and repository management; DO NOT use GitKraken or other GUI tools.
- Create branches for features/bug fixes named with lowercase hyphen-separated words.
- Commit messages should be short (1 line) and clear, typically starting with one of the past tense verbs (Added, Fixed, Changed, Removed, Refactored, Updated) and ending with a suffix like ` - fixes #123` or ` - resolves #123` to reference related issues.
- Rebase your branch onto the latest `up-develop` before creating a pull request `git rebase --onto up-develop develop`.
- If requested, the AI Agent should create a pull request in repo `consected/restructure` based on the `develop` branch, with a descriptive title and summary of changes 
- Only a human user will merge branches after code review; AI agents should not merge branches.

### Testing Conventions
- When fixing implementation bugs, **always write new Rspec tests** to demonstrate the bug, before fixing it.
- Check for reusable support methods in `spec/support/` before writing new test code.
- After writing tests, always add comments to the top of the spec files explaining the purpose of the tests.

### Rspec System Spec Best Practices
1. **ALWAYS use helper methods for system specs** - read `spec/support/feature_support.rb` before starting to implement system spec tests
2. **Run `debug_process_status`** when fields/sections can't be found
3. **Wait for AJAX** using `finish_page_loading` and `finish_form_formatting` after interactions
4. **Expand sections before accessing fields** - forms load via AJAX
5. **Never write raw Capybara selectors in system specs**

### First Steps When Stuck
1. Run `debug_process_status` to see current UI state
2. Check if section needs expanding: `expand_model_reference('Section Name')`
3. Check if edit button needs clicking: `click_edit_button_within_target(form)`
4. Verify show_if conditions are met for hidden fields
5. As last resort: `debug_state('action_name', 'description')` to save HTML snapshot, screenshot and UI status

### Ruby on Rails Conventions

- Follow the RuboCop Style Guide and use `rubocop` for consistent formatting:
  - Run `bundle exec rubocop --autocorrect [file1, file2, ...]` to auto-fix issues.
- Use snake_case for variables/methods and CamelCase for classes/modules.
- Keep methods short and focused; use early returns, guard clauses, and private methods to reduce complexity.
- Favor meaningful names over short or generic ones.
- Comment only when necessary — avoid explaining the obvious.
- Apply the Single Responsibility Principle to classes, methods, and modules.
- Prefer composition over inheritance; extract reusable logic into modules or services.
- Keep controllers thin — move business logic into models, services, or command/query objects.
- Apply the “fat model, skinny controller” pattern thoughtfully and with clean abstractions.
- Extract business logic into service objects for reusability and testability.
- Use partials or view components to reduce duplication and simplify views.
- Use `unless` for negative conditions, but avoid it with `else` for clarity.
- Avoid deeply nested conditionals — favor guard clauses and method extractions.
- Use safe navigation (`&.`) instead of multiple `nil` checks.
- Prefer `.present?`, `.blank?`, and `.any?` over manual nil/empty checks.
- Scope queries in models or use query objects for clarity and reuse.
- Use `before_action` callbacks sparingly — avoid business logic in them.
- Use `Rails.cache` to store expensive computations or frequently accessed data.
- Construct file paths with `Rails.root.join(...)` instead of hardcoding.
- Use `class_name` and `foreign_key` in associations for explicit relationships.
- Keep secrets and config out of the codebase using ENV variables.
- Write isolated unit tests for models, services, and helpers.
- Cover end-to-end logic with request/system tests.
- Use background jobs (ActiveJob) for non-blocking operations like sending emails or calling APIs.
- Document complex code paths and methods with YARD

### Database Conventions
- Use migrations for all schema changes; avoid direct DB modifications for implementation.
- Name tables according to Rails conventions (plural snake_case) aligning with model names.
- Use history tables to allow auditing changes to important models.
- For user data tables, data will be automatically downcased for storage and titleized for display unless otherwise specified.

### Helper Methods Quick Reference

| Task | Helper Method | Example |
|------|--------------|------|
| Text input | `fill_in_field(name, value)` | `fill_in_field('description', 'My text')` |
| Dropdown | `select_from_dropdown_field(name, value)` | `select_from_dropdown_field('status', 'Active')` |
| Multi-select | `select_multiple_from_chosen(name, values)` | `select_multiple_from_chosen('tags', ['A', 'B'])` |
| Radio buttons | `set_yes_no_field(name, value)` | `set_yes_no_field('approved', 'yes')` |
| Checkbox | `set_checkbox_field(name, checked)` | `set_checkbox_field('active', true)` |
| Big select | `select_from_big_select_field(name, value)` | `select_from_big_select_field('grant', 'Title')` |
| Expand section | `expand_model_reference(name)` | `form = expand_model_reference('Grant Aims')` |
| Expand master | `expand_master_record(text: title)` | `expand_master_record(text: 'Proposal')` |
| Edit button | `click_edit_button_within_target(elem)` | `form = click_edit_button_within_target(form)` |
| Wait for AJAX | `finish_page_loading` | `finish_page_loading` |
| Debug current state | `debug_process_status` | `debug_process_status` |
| Available fields | `available_form_fields` | `available_form_fields` |

## Running Bash Scripts and Terminal Commands

### IMPORTANT Terminal Command Rules for AI Agents

#### ❌ NEVER Do These Things

```bash
# ❌ Setting environment variables (scripts handle this internally)
RAILS_ENV=test bundle exec rspec
FPHS_2FA_AUTH_DISABLED=true bundle exec rails runner "puts 'test'"

# ❌ Piping long-running commands (lose visibility into progress and errors)
bundle exec rspec spec/system/ 2>&1 | grep "Error" | tail -15

# ❌ Running in background (can't track completion or errors)
nohup bundle exec rspec spec/system/ &
bundle exec rspec spec/system/ > /tmp/output.log 2>&1 &

# ❌ Redirecting output to /dev/null (lose debugging information)
bundle exec rspec spec/system/ >/dev/null 2>&1
bundle exec rspec spec/system/ 2>/dev/null
```

#### ✅ ALWAYS Do This Instead

```bash
# ✅ Let test output stream, then analyze the saved log
bundle exec rspec spec/system/ 2>&1 | tee /tmp/rspec_output.log | tail -100
grep -E "pattern" /tmp/rspec_output.log | tail -15
grep -E --after-context=100 "other pattern" /tmp/rspec_output.log | tail -200

# ✅ Use app-scripts that set environment variables internally
# NOTE: the arguments after the script are the same as you would pass to the underlying command
app-scripts/rails_runner_test.sh "puts User.count"
app-scripts/headless_rspec.sh spec/system/my_spec.rb -e 'the example to test'
app-scripts/not_headless_rspec.sh spec/system/my_spec.rb -e 'the example to test'
```

#### Why These Rules Exist

- **Terminal tools can lose output** if commands pipe before completion
- **Background processes hide errors** and completion status from the agent
- **Environment variables must be consistent** - app-scripts ensure this
- **Tee allows both viewing and analyzing** output without losing information
- **Agents need full output** to diagnose failures accurately

## Project-Specific Conventions

### File Structure
- `app-scripts/`: Deployment and utility scripts (not standard Rails)
- `scripted_job_scripts/`: Filestore processing scripts
- `docs/`: Multi-audience documentation (admin, dev, user, guest)
- Dynamic controllers live in `app/controllers/dynamic_model/`

### Naming Patterns
- Tables use `ml_app` DB schema in production for core tables only
- Dynamic model tables use project or feature specific DB schema, e.g. `redcap`, `grant_aims`
- Dynamic models: `DynamicModel::ClassName` namespace
- Activity logs: `ActivityLog::LogTypeName` namespace
- Route helpers: auto-generated based on table names

### Security Model
- Separate admin (`/admin/sign_in`) and user authentication
- Two-factor authentication with TOTP
- File access controlled via Linux groups
- API token authentication available

### UI Architecture (Handlebars-Based Single-Page Application)

The front-end is a custom reactive single-page application using Handlebars templates:

**Template Generation Flow:**
1. ERB partials in `app/views/common_templates/_search_results_template.html.erb` generate Handlebars templates at page load
2. For each model type (player_info, activity logs, dynamic models), three templates are created:
   - `<model>-result-template`: Individual item rendering
   - `<models>-list-template`: Collection rendering  
   - `<models>-compact-list-template`: Condensed view
3. `app/assets/javascripts/app/_fpa.js` orchestrates the front-end logic and Handlebars rendering
4. AJAX requests return JSON data, which Handlebars templates render client-side

**Key Template Files:**
- `app/views/masters/_search_results_master_tabs.html.erb`: Master record structure and tabs
- `app/views/common_templates/_common_template_list.html.erb`: Generic list handler
- `app/views/common_templates/_common_template_result.html.erb`: Individual item renderer with fields
- See `docs/dev_reference/app-ui/ui-templates-for-master-record-search-results.md` for complete template hierarchy

**UI Split:**
- User-facing: `app/assets/javascripts/application.js` + `app/_fpa.js` 
- Admin panel: `app/assets/javascripts/admin.js` (reuses user components)
- Templates are configuration-driven - most UI changes happen through admin panel YAML configs, not code

### Environment Variables
Key variables (see `app-scripts/get-aws-env-vars.sh`):
- `FPHS_POSTGRESQL_*`: Database connection
- `FPHS_2FA_AUTH_DISABLED`: Disable 2FA in development
- `FPHS_LOAD_APP_TYPES`: Load dynamic configurations on startup

NOTE: AI agents must NOT set environment variables directly in terminal commands. Use the appropriate app-scripts that handle environment variables internally.

## Testing Approach

Background to the test framework and conventions:

- **RSpec**: Main test framework with parallel execution support
- **Capybara**: systems tests with Chrome by default, or Firefox/Geckodriver
- **Database Cleaner**: Test isolation
- **Model specs** must be produced to cover all new model logic
- **System specs** (not features specs) should be produced for all new UI functionality
- **Run `rspec` on new spec tests** after implementing new features to make sure they run
- **Do not use `skip` or `xit` in spec files**. Instead, fix the underlying issues causing test failures. 

### Running tests
Before running tests for the very first time after a reboot, set up the filestore simulation. Tests require Filestore mount setup once only after a system restart: 
```bash
app-scripts/setup-dev-filestore.sh
```
NOTE: this needs "sudo" to run, and although the Rspec suite attempts to run this automatically if required, it is best to run this manually once after a reboot to avoid test failures.

Standard Rspec tests, which exclude environment / app specific tests in 
`spec/system/apps/` and `spec/support/apps/`
```bash
bundle exec rspec  # Run in headless mode
```

For headless (invisible browser) system tests, which include the environment / app specific specs:
```bash
app-scripts/headless_rspec.sh spec/system/apps/grant_aims/grant_aims_process_spec.rb
```

For non-headless (visible browser) system tests, which include the environment / app specific specs:
```bash
app-scripts/not_headless_rspec.sh spec/system/apps/grant_aims/grant_aims_process_spec.rb
```

For javascript tests (in `spec/javascripts/`):
```bash
app-scripts/jasmine-serve.sh headless
```

AI Agents: to use the Rails runner, use one of the following:

```bash
app-scripts/rails_runner_test.sh "<command to run>"
# Or
bundle exec rails runner -e test "<command to run>"
```

AI Agents: DO NOT use environment variables
```bash
RAILS_ENV=test bundle exec rails runner "<command to run>"
```

If needed, clean the test database:
```bash
app-scripts/clean-test-db.sh

```
If needed, clean test assets and cache:
```bash
app-scripts/clean-test-assets-and-cache.sh
```
### Parallel test execution
```bash
app-scripts/parallel_test.sh
```
NOTE: the full test suite is slow, so only run when a full coverage test is required! Add arguments for spec paths if required.

The results are found in tmp/failing_specs.log or on the console. Any issues are reported by the final section after the "Retesting" of any failures has completed.

To rerun only the failed tests from the last parallel test run:
```bash
app-scripts/retest_failed_parallel_tests.sh
```

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

To capture console logs from the browser, store them to a global array variable during the test run
and retrieve them later for debugging:

```ruby
# At the start of the test run
page.execute_script('window.browserLogs = []; console.log = function(msg) { window.browserLogs.push(msg); };')
```

```ruby
# At the end of the test run
logs = page.evaluate_script('window.browserLogs')
puts "Browser console logs:\n#{logs.join("\n")}"
```


## System Specs

System specs are located in `spec/system/`. Follow Best Practices and Development Patterns below when implementing system specs. We write system specs to simulate real user/admin interactions through the UI as much as possible. Interacting with underlying Javascript is discouraged; use Jasmine tests for Javascript-specific behavior. 

### Things to Remember
- Standard string / varchar fields downcase data on storage and titleize on display. Keep this in mind when writing system specs that interact with user data fields.
- Some fields rely heavily on Javascript for rendering and interaction (e.g., chosen.js dropdowns, big select dialogs, custom rich text editors). Always use the provided helper methods to interact with these fields.
- Field visibility is controlled by `show_if` rules. Always set prerequisite fields first and allow time for the UI to update.
- Don't navigate directly to edit URLs; always use the UI flow to reach forms (e.g. </masters/123> then click edit button for the appropriate block).

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

## UI interaction with specific components

Some UI components are driven by Javascript and may appear to be disabled or not function as expected. They should be listed here. The @agent should also keep this section up to date with new learnings.

### Chosen single select boxes: `<select class="use-chosen">`

The <select> tags that have the class "use-chosen" that use the `chosen.js` component to allow for typed filtering of dropdown selection boxes.

The select element itself is hidden. The next element after it (selector `div.chosen-container`) has an `id` attribute that starts with the same `id` as the select tag and adds the suffix `_chosen`. 

Click this `div.chosen-container` to reveal the drop down list of results.

When clicked, the whole block moves in the DOM and is positioned absolutely (for display reasons, to prevent truncation of the box by parent containers). You can find the dropdown items by searching for the `div.chosen-container .chosen-results`. Also you can type into the field that became active when clicked to filter the results. The `player_data_entry_spec.rb` has an example with "chosen" than may help in implementation of feature specs.

### Chosen multiple select boxes: `<select multiple>`

The multi-select boxes are similar to the single select boxes, but allow multiple selections. They also use the `chosen.js` component. Any `select` tag with the attribute `multiple="multiple"` will be treated as a multi-select "chosen" selector.

The operation is similar to the single select boxes. Selected items appear as "tags" within the box. The link on each tag `.search-choice-close` can be clicked to remove that selection.

Since multiple items can be selected, the dropdown list does not close when an item is clicked. Instead, click outside the box to close the dropdown (for example, on the caption above it).

### Big Select boxes: `<input class="use-big-select">`

A big select field is like a select box, but when clicked it opens a full dialog with more descriptive options.

The big select field is an `input` element, with class `.use-big-select.big-select-use-overlay`. The field triggers the big select dialog to appear when the focus event is fired. Focus on this field and the dialog should appear. 

In the big select dialog, each selectable item will have class `.big-select-item`. Simply click the desired item to select it. If there are many items, a scrollbar will appear on the right side of the dialog.

Click the `close` button to close the dialog without making a selection.

Big select dialogs may include a blank "(none)" option at the end of the list to allow clearing the selection.

## Implementation classes, resource names and database table names

All of these may refer to the same resource, but in different contexts. This section clarifies the naming conventions used.

A "dynamic definition" is one of three dynamic configured resources: dynamic models, activity logs, or external identifiers. These are represented by the classees `DynamicModel`,
`ActivityLog`, and `ExternalIdentifier` respectively. The database tables for these resources (the configurations) are `dynamic_models`, `activity_logs`, and `external_identifiers` respectively.

When referring to a specific instance of one of these resources, the term "dynamic model", "activity log", or "external identifier" is used.

The dynamic definitions programmatically generate runtime model classes in the namespaces `DynamicModel::`, `ActivityLog::`, and `ExternalIdentifier::` respectively. For example, a dynamic model with the table name `contact_infos` would generate a runtime class `DynamicModel::ContactInfo`. The resource name for this model would be `dynamic_model__contact_infos` (yes, plural, to match the database table name!)

Activity logs generate runtime classes similarly. An activity log with table name `activity_log_case_reviews` would generate a runtime class `ActivityLog::CaseReview`. The resource name for this model would be `activity_log__case_reviews`. 

Since activity logs are case management workflows, each record in the `activity_log_case_reviews` table would represent a specific case review instance. The "activity" to be performed in that case review would be determined by the `extra_log_type` attribute on the record. Activity log records can be referred to using resource names that represent the extra log type they have. For example, if there is an extra log type `initial_review`, then records of that type could be referred to using the resource name `activity_log__case_review__initial_review` (NOTE that `case_review` is singular, and `initial_review` always matches exactly the extra log type definition name).

Resource names are used extensively in access control definitions and naming of associations within the code. They are a unique way of referring to specific models or subsets of records within models. The `Resources::Models` module maps resource names to their corresponding runtime classes and acts as a registry for all dynamic definitions. If in doubt, try to look up resources in `Resources::Models` to find the correct class, resource name or actual class itself.


## Development Setup
```bash
# Run once after reboot to setup filestore simulation
app-scripts/setup-dev-filestore.sh 

# Database setup
app-scripts/add_admin.sh <email>
FPHS_2FA_AUTH_DISABLED=true bundle exec rails s

# Set up test database
app-scripts/create-test-db.sh 1

# Run parallel test suite to validate configuration
app-scripts/parallel_test.sh
```

## Production Build Workflow
```bash
# Release and build (handles versioning, branching, Docker builds)
app-scripts/release_and_build.sh
# Release and build with a minor version bump (for the ReStructure upstream repo)
app-scripts/release_and_build.sh minor  
```

## Database Migrations
Dynamic models create migrations automatically. The test environment runs migrations automatically
when specs are run.

For manual migrations in the development environment:
```bash
bundle exec rails db:migrate
```

## Integration Points

### REDCap Integration
- `app/models/redcap/`: REDCap API integration
- Automated data pulls and dynamic model generation
- Metadata synchronization for data dictionary

### AWS Services
- SNS/Pinpoint for notifications
- S3 for file storage (alternative to NFS)
- CloudWatch for logging

### External APIs
- Token-based API authentication via `simple_token_authentication`
- RESTful endpoints following Rails conventions
- Configurable API access controls

### Code Style
- Always format files using the default VSCode formatter (Ruby-LSP is set to use Rubocop)
- Use modern Ruby syntax 
  - safe navigation
  - keyword arguments
  - omit values in Hash literals and method call keys with variables matching keys

## Common Gotchas

1. **Route Changes**: `DynamicModel.routes_reload` should be automatically run after model config changes, but may need manual invocation for some tests to work
2. **Filestore**: Requires proper NFS mounts or development mount simulation
3. **Master Association**: Most models require `master_id` - use external identifiers for exceptions
4. **Admin vs User**: Separate authentication systems with different access patterns
5. **Schema Awareness**: Production uses `ml_app` schema

Focus on configuration over code - most features should be achievable through admin panel settings rather than new Ruby code.

## Additional Resources
- [Architecture Overview](docs/dev_reference/main/architecture_overview.md): High-level system design
- [ReStructure Admin Guide](docs/admin_reference/main/README.md): Instructions for configuring the platform
- [Template Structures](app/models/admin/defs): Various files providing outlines for configurations and defintition of admin panel fields
- [Supplementary Developer Docs](docs/dev_reference/main/README.md): Details on common developer requirements
- [Various End-User App Guides](docs/app_reference): Highlight how end-user applications are used
- [API Examples](app-scripts/api/README.md): Sample API usage and BASH scripts