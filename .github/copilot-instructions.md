# ReStructure AI Coding Guidelines

## Architecture Overview

**ReStructure** is a research data management platform built on Rails 7 with a flexible, configuration-driven architecture. The system is designed around five core concepts:

1. **App Types**: Encapsulate all configurations for an end-user application (like Zeus or Athena)
2. **Master Records**: Central participant/subject records that everything relates to
3. **External Identifiers**: Real-world numbering systems for people or entities represented by master records
4. **Activity Logs**: Process management and case management workflows with embedded steps
5. **Dynamic Models**: Runtime-generated Rails models from database configurations

### The Master Record Pattern

Everything in ReStructure relates to a Master record (participant/subject). This is enforced through:
- `master_id` foreign key on nearly all tables (exception: external identifiers before assignment)
- `current_user` passed through master: `master.current_user` not `self.current_user`
- Access controls verified at master level: `master.allows_user_access`
- Controllers set user once: `@master.current_user = current_user`

### Key Components

- **Admin Panel**: Configuration management at `/admin/*` routes using database-stored YAML configs
- **User Interface**: Single-page application with custom JavaScript front-end
- **Filestore**: NFS-based file management with Linux group security
- **Background Jobs**: `delayed_job` for file processing and notifications
- **User Access Controls**: Granular role-based permissions system controlling table/field access

### Top-Down Development Approach

ReStructure follows a hierarchical configuration pattern:

1. **App Type Configuration**: Define the overall application scope and user roles
2. **External Identifier Setup**: Configure real-world ID systems (SSN, study IDs, etc.)
3. **Activity Log Creation**: Define main workflow processes and case management
4. **Activity Log Types**: Configure individual workflow steps/activities within processes
5. **Embedded Dynamic Models**: Create forms and data structures for each workflow step

This approach ensures consistent user experience and proper data relationships throughout the application.

### Activity Log Workflow System

Activity Logs provide case management through `extra_log_types` (individual workflow steps) configured in YAML:

```yaml
step_name:
  label: Step Label
  fields: [field1, field2]
  creatable_if:  # Controls when this step can be created
    all:
      this:
        status: 'previous_step_complete'
  references:  # Links to other records/models
    - dynamic_model__some_model:
        label: Related Item
        from: this
        add: many
```

**Key Workflow Concepts:**
- `extra_log_type` attribute stores which step a record represents (e.g., 'proposal_submission', 'review')
- `creatable_if` conditions control sequential workflow - steps only appear when prerequisites are met
- `references` create relationships to other models (dynamic models, other activity logs)
- `status` field typically drives workflow state transitions
- Each activity log process (defined in admin) generates a runtime model class in `ActivityLog::` namespace

## Essential Development Patterns

### Dynamic Model System

The platform's core feature is runtime model generation from database configurations:

**How It Works:**
1. Admin creates/updates a `DynamicModel` record with YAML `options` configuration
2. `after_save :generate_model` callback triggers class generation
3. Runtime class created in `DynamicModel::` namespace (e.g., `DynamicModel::TestData`)
4. Database migration auto-generated and run to create/update table
   (NOTE: auto migrations are denied for the "ml_app" schema - spec tests should use the "dynamic_test" schema)
5. Routes auto-generated via `DynamicModel.routes_reload`
6. Master association added automatically: `has_many :dynamic_model__test_datas`

**Key Files:**
- `app/models/dynamic/def_generator.rb`: Core generation logic, memoization, regeneration triggers
- `app/models/dynamic/model_generator.rb`: Parses configs, creates migrations
- `lib/active_record/migration/app_generator.rb`: Migration execution
- Controllers inherit from `DynamicModelControllerHandler` for generated models

**Critical Pattern:**
Models are NOT code files - they're runtime-generated Ruby classes stored in memory. Changes to configs trigger regeneration:
```ruby
# After creating/updating dynamic model admin config
# This happens automatically, but may need manual trigger in tests
DynamicModel.routes_reload
Rails.application.routes_reloader.reload!
```

**Memoization:** Generated models cached in `DynamicModel.models` hash and `Resources::Models` - cleared on regeneration

### User Base Pattern

All user-facing models inherit from `UserBase` through `HandlesUserBase` concern:

- Always requires authenticated user context via `current_user`
- Enforces master record associations (participant linking)
- Implements granular access controls through `user_access_controls`
- Uses crosswalk validation for external identifiers

### User Roles and Access Controls

ReStructure implements a sophisticated role-based permission system:

- **App Types**: Users belong to specific app types that determine their application scope
- **User Access Controls**: Database-driven permissions defining who can access what resources
- **Resource-Level Security**: Controls access to tables, fields, and specific records
- **Role Hierarchy**: Permissions cascade from app type → user role → specific resources
- **Master-Based Security**: All access is contextual to the master records users can see

Access control checks happen at multiple levels:
```ruby
# Table-level access
user.has_access_to?(:create, :table, 'player_infos')
# Record-level access through master association
record.allows_current_user_access_to?(:edit)
```

### Configuration-Driven Development

Most functionality is configured, not coded:

- **Access Controls**: `user_access_controls` table defines granular permissions
- **Form Rules**: YAML configurations define field visibility and validation
- **Process Workflows**: Activity log configurations manage case processes
- **Data Structures**: Dynamic model configurations define database schema
- **External ID Systems**: Configure how real-world identifiers map to master records

## Critical Commands

### General Terminal Command Limitations

When running as an agent, adhere to the following rules when using terminal commands:

- DO NOT set any environment variables - use the appropriate development scripts that handle environment variables internally
- DO NOT redirect any output to `>/dev/null` or `2>/dev/null`

Don't pipe output to other commands like `grep`, `tail`, `awk`, `sed`, etc since after running that time the output is lost. It is preferable to redirect output and errors to `/tmp/` then analyzing the files with grep, awk, sed, or other text processing tools. In this way the output of a long running test can be examined in multiple ways after completion. For example:

**Don't do this:**
```bash
bundle exec rspec spec/features/ 2>&1 | grep -E "PHASE|✓ Grant|Failures|Finished|examples" | tail -15
```

**Do this instead:**
```bash
bundle exec rspec spec/features/ 2>&1 | tee /tmp/rspec_output.log | tail -100
grep -E "PHASE|✓ Grant|Failures|Finished|examples" /tmp/rspec_output.log | tail -15
```

**Because then you can also do follow up commands, such as:**
```bash
grep -E --after-context=100 "Available fields" /tmp/rspec_output.log | tail -200
```


### Extracting results from HTML files using CSS selectors

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


### Development Setup
```bash
# Database setup
app-scripts/setup-dev-filestore.sh
app-scripts/add_admin.sh <email>
FPHS_2FA_AUTH_DISABLED=true bundle exec rails s

# Test database
app-scripts/create-test-db.sh 1
app-scripts/parallel_test.sh
```

### Production Workflow
```bash
# Release and build (handles versioning, branching, Docker builds)
app-scripts/release_and_build.sh
app-scripts/release_and_build.sh minor  # for minor version bumps
```

### Database Migrations
Dynamic models create migrations automatically. For manual migrations:
```bash
# Always specify schema
FPHS_POSTGRESQL_SCHEMA=ml_app,ref_data bundle exec rails db:migrate
```

## Project-Specific Conventions

### File Structure
- `app-scripts/`: Deployment and utility scripts (not standard Rails)
- `scripted_job_scripts/`: Filestore processing scripts
- `docs/`: Multi-audience documentation (admin, dev, user, guest)
- Dynamic controllers live in `app/controllers/dynamic_model/`

### Naming Patterns
- Tables use `ml_app` schema prefix in production
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

## Testing Approach

Background to the test framework and conventions:

- **RSpec**: Main test framework with parallel execution support
- **Capybara**: Feature tests with Chrome by default, or Firefox/Geckodriver
- **Database Cleaner**: Test isolation
- **Model specs** must be produced to cover all new model logic
- **Feature specs** should be produced for all new UI functionality
- **Run `rspec` on new spec tests** after implementing new features to make sure they run

### Running tests
Before running tests for the very first time after a reboot, set up the filestore simulation. Tests require Filestore mount setup once only after a system restart: 
```bash
app-scripts/setup-dev-filestore.sh
```
NOTE: this needs "sudo" to run, and although the Rspec suite attempts to run this automatically if required, it is best to run this manually once after a reboot to avoid test failures.

Standard Rspec tests, which exclude environment / app specific tests in 
`spec/features/apps/` and `spec/support/apps/`
```bash
bundle exec rspec  # Run in headless mode
```

For headless (visible browser) feature tests, which include the environment / app specific specs:
```bash
app-scripts/headless_rspec.sh spec/features/apps/grant_aims/grant_aims_process_spec.rb
```

For non-headless (visible browser) feature tests, which include the environment / app specific specs:
```bash
app-scripts/not_headless_rspec.sh spec/features/apps/grant_aims/grant_aims_process_spec.rb
```

To use the Rails runner without prompting a human for approval, use:

```bash
app-scripts/rails_runner_test.sh "<command to run>"
```
This is the equivalent of:
```bash
RAILS_ENV=test bundle exec rails runner "<command to run>"
```

If needed, clean the test database:
```bash
app-scripts/clean-test-db.sh
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

### Rspec feature test tips

To avoid 2FA logins blocking tests, the following settings are recommended in test setup (in `before(:all)` block):
```ruby
change_setting('TwoFactorAuthDisabledForUser', true)
change_setting('TwoFactorAuthDisabledForAdmin', true)
```

Never click on elements programmatically using Javascript if they may not be interactable. Instead, use JavaScript to scroll them into view first:
```ruby
edit_link = find('a', text: 'edit tracker record')
page.execute_script('arguments[0].scrollIntoView(true);', edit_link)
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


Attempt to follow the real user / admin flow through the UI as much as possible, avoiding direct model manipulation except for setup/teardown. Avoid using `visit` to go directly to pages that would not normally be accessible through the UI flow. 

Any "edit" button represented by a glyphicon should be clicked in the UI rather than visiting the edit URL directly. These buttons typically have the HTML class something like: "edit-entity glyphicon glyphicon-pencil".

Any link or button that has the HTML attribute `data-remote="true"` (which may appear in a Rails helper like `<%= link_to ..., remote: true %>`) should be clicked in the UI rather than visiting the URL directly. This is because these links typically perform AJAX requests that update parts of the page dynamically.

Don't use Javascript to manipulate or show fields not visible due to `show_if` rules. These are hidden due to the business logic, and if the tests dictate they should be shown then this indicates a bug.

## Feature Spec Development Patterns

This section captures critical patterns and learnings from end-to-end feature spec development, particularly for Activity Log workflows. These patterns are essential for successful test implementation.

**CRITICAL:** ReStructure provides comprehensive helper methods in `spec/support/feature_support.rb`. **Always use these helpers** rather than writing raw Capybara selectors or inspecting HTML directly. The helpers handle AJAX waits, scrolling, visibility issues, and provide debug output when things fail.

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
FEATURE_DEBUG=true bundle exec rspec spec/features/your_spec.rb
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

**Debug Technique (when development):**
```ruby
# See what sections are available
debug_process_status  # Shows all model reference expanders

# Or specifically:
available_model_reference_expanders  # Lists all expandable sections
```

### Show_if Conditional Field Visibility

Fields may appear or disappear based on other field values via `show_if` configuration rules. This is pure business logic - don't circumvent it.

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

### Debug Techniques

**Save HTML Snapshots:**
```ruby
# At any point in the test
File.write('/tmp/debug_page.html', page.html)

# Then examine with command line:
grep -A 5 'field-name' /tmp/debug_page.html
```

**Extract with Nokogiri:**
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

**List Available Elements:**

```ruby
debug_process_status  # Shows all sections, fields, buttons, etc
```

If you need to dig in to the HTML, use Capybara selectors:
```ruby
# Find what sections are available
all('.mr-expander').each do |elem|
  puts "ID: #{elem[:id]}, Text: #{elem.text}"
end

# Find all forms
all('form').each do |form|
  puts "Action: #{form[:action]}, Method: #{form[:method]}"
end

# Find all inputs in a section
within result_target do
  all('input, select, textarea', visible: :all).each do |field|
    puts "Name: #{field[:name]}, Type: #{field[:type]}"
  end
end
```

**Scroll Elements into View:**
```ruby
def scroll_into_view(element)
  page.execute_script('arguments[0].scrollIntoView(true);', element)
  sleep 0.5  # Allow scrolling to complete
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
- [ReStructure Admin Guide](docs/admin_reference/main/README.md): Instructions for configuring the platform
- [Template Structures](app/models/admin/defs): Various files providing outlines for configurations and defintition of admin panel fields
- [Supplementary Developer Docs](docs/dev_reference/main/README.md): Details on common developer requirements
- [Various End-User App Guides](docs/app_reference): Highlight how end-user applications are used
- [API Examples](app-scripts/api/README.md): Sample API usage and BASH scripts