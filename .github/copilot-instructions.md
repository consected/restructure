# ReStructure AI Coding Guidelines

## 🚨 QUICK REFERENCE FOR AGENTS

### Most Critical Rules (READ FIRST)
1. **When implementing new features, ALWAYS write and run corresponding Rspec specs** to cover new functionality
2. **Follow [Ruby on Rails Coding Standards](instructions/ruby-on-rails.instructions.md)** for all code you write
3. **Explain why changes to existing methods in models and other core components are necessary**
4. **Rspec tests must be written to demonstrate new functionality works as intended** not just to make tests pass
5. **If requirements are not clear, ask for clarification before proceeding**
6. **Never commit directly to `up-develop` or `develop` branches** - always create feature branches and pull requests
7. **Focus on configuration over code** - most features should be achievable through admin panel settings rather than new Ruby code
8. **Create new files and edit directly in the editor**; avoid using command line file operations to generate source code


### Critical Rules for Running Terminal Commands
1. **Never set environment variables inline** - use app-scripts instead or `export` them in the terminal before running commands
2. **Always wait for commands to complete before proceeding** - load the `execute/awaitTerminal` tool first
3. **Never redirect scripts stdout or stderr to /dev/null or /tmp**
4. **Never run commands in the background** - all commands exit when complete with success or failure codes

### Git and GitHub Usage

- Use `git` and `gh` CLI tools for version control and repository management.
- Before starting work, add a tag `start-<feature-name>-<issue-number>` then create a features/bug branch `<feature-name>-<issue-number>`.
- Commit messages should be short (1 line) and clear, typically starting with one of the past tense verbs (Added, Fixed, Changed, Removed, Refactored, Updated) and ending with a suffix like ` - fixes #123` or ` - resolves #123` to reference related issues.

### Creating a Pull Request

If requested to create a PR, follow these steps:

- Rebase your branch onto the latest local `up-develop` branch before creating a pull request:
  `git checkout up-develop && git pull && git rebase --onto up-develop start-<feature-name>-<issue-number>`
- Create a (cross fork) pull request on repo `consected/restructure` based on the `develop` branch, with a descriptive title and summary of changes. "head" should refer to the local branch created for the feature.

NOTE: Only a human user will merge branches after code review; AI agents should not merge branches.

### Testing Conventions
- When fixing implementation bugs, **always write new Rspec or Jasmine tests** to demonstrate the bug, before fixing it.
- Check for reusable support methods in `spec/support/` before writing new test code.
- After writing tests, always add comments to the top of the spec files explaining the purpose of the tests.

### Ruby on Rails Conventions

For all Ruby on Rails code you write, follow these conventions: [Ruby on Rails Coding Standards](instructions/ruby-on-rails.instructions.md)

### HTML and CSS Conventions

- Avoid adding HTML styles inline; use CSS classes instead.
- Use BEM (Block, Element, Modifier) naming conventions for CSS classes.
- If JavaScript is needed for UI behavior, preferably use appropriate postprocessors rather than inline scripts.
- If inline `<script>` or `<style>` tags are necessary, use Rails `javascript_tag` or `style_tag` helpers with a nonce for CSP compliance.

### Database Conventions
- Use migrations for all schema changes; avoid direct DB modifications for implementation.
- Name tables according to Rails conventions (plural snake_case) aligning with model names.
- Use history tables to allow auditing changes to important models.
- For user data tables, data will be automatically downcased for storage and titleized for display unless otherwise specified.

### Rspec Specs

For general Rspec standards refer to: [Rspec project coding standards](instructions/rspec.instructions.md)

### Rspec System Specs

For Rspec System Specs Refer to: [Rspec System Specs project coding standards](instructions/rspec-system-spec.instructions.md)

### Command Line Usage
- Create a directory `./tmp/agent-tmp` in the workspace root
- Use `./tmp/agent-tmp` for all temporary files and logs
- DO NOT set environment variables or prefix commands with `VAR=VALUE`; use the appropriate app-scripts instead or `export VAR=value` in the terminal before running commands
- DO NOT run commands that redirect output to `/dev/null` or `/tmp/`
- DO NOT run commands in the background using `&` or `nohup` unless absolutely necessary, and if so, ensure output is redirected to a file in `./tmp/agent-tmp` for later analysis
- DO NOT run commands with `timeout` unless absolutely necessary

```bash
# Let test output stream, then analyze the saved log
bundle exec rspec spec/system/ 2>&1 | tee /tmp/rspec_output.log | tail -100
grep -E "pattern" /tmp/rspec_output.log | tail -15
grep -E --after-context=100 "other pattern" /tmp/rspec_output.log | tail -200

# NOTE: the arguments after the script are the same as you would pass to the underlying command
# Replace `RAILS_ENV=test bundle exec rails runner ...` with: 
app-scripts/rails_runner_test.sh "puts User.count"
# or use the rails environment argument
bundle exec rails runner -e test "puts Rails.env"

# Replace `RUN_APP_SPECS=true FEATURE_DEBUG=true bundle exec rspec ...` with:
app-scripts/headless_rspec.sh spec/system/my_spec.rb -e 'the example to test'

# Replace `NOT_HEADLESS=true RUN_APP_SPECS=true FEATURE_DEBUG=true bundle exec rspec ...` with:
app-scripts/not_headless_rspec.sh spec/system/my_spec.rb -e 'the example to test'

# Clean the test database (creates a fresh one)
app-scripts/clean-test-db.sh 

# Clean test assets and cache
app-scripts/clean-test-assets-and-cache.sh
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
Server configurations (including secrets) use environment variables:
- Most are used to set the configuration in `config/initializers/app_settings.rb` and `config/initializers/app_default_settings.rb`
- `FPHS_POSTGRESQL_*`: Database connection
- `FPHS_2FA_AUTH_DISABLED`: Disable 2FA in development
- `FPHS_LOAD_APP_TYPES`: Load dynamic configurations on startup

NOTE: AI agents must NOT set environment variables directly in terminal commands. Use the appropriate app-scripts that handle environment variables internally.


## UI interaction with specific components

Some UI components are driven by Javascript and may appear to be disabled or not function as expected. They should be listed here.

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

## Dynamic Definition Setup - Automatic Migrations

When an admin or rspec test creates a new dynamic definition (dynamic model, activity log or external identifier), the system may automatically generate a new database table for that definition, with the appropriate columns and types. This is enabled by the `Settings::AllowDynamicMigrations` setting to `true`. This setting is **enabled** by default in *development environments* and for *system spec tests*, but **disabled** in *production environments* by default. 

Other spec tests (models, controllers, requests, helpers, etc) may explicitly enable this setting if they need to create dynamic definitions as part of their tests. Add the following to the top of the spec file to enable automatic migrations for that spec:

```ruby
before :all do
   change_setting('AllowDynamicMigrations', true)
end

after :all do
   change_setting('AllowDynamicMigrations', false)
end
```

*Production environments* can enable dynamic migrations by setting the environment variable `FPHS_ALLOW_DYNAMIC_MIGRATIONS=true` on the app server.

If automatic migrations are disabled, dynamic definitions will need underlying database tables to be created manually before they can be used. These may be created through manual migrations, or using SQL directly on the database. Some *spec tests* have previously generated tables manually using SQL, but the recommended approach is to enable automatic migrations for tests that require dynamic definitions, and allow the system to handle table creation.

## Development Setup
```bash
# Run once after reboot to setup filestore simulation
# The user will be prompted for sudo access, so avoid running unless necessary
app-scripts/setup-dev-filestore.sh 

# Create an admin user
app-scripts/add_admin.sh <email>

# Run the development server
bundle exec rails s

# Set up test database
app-scripts/clean-test-db.sh

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

## Common Gotchas

- **Filestore**: Requires proper NFS mounts or development mount simulation
- **Master Association**: Most models require `master_id` - use external identifiers for exceptions
- **Admin vs User**: Separate authentication systems with different access patterns
- **Schema Awareness**: Production uses `ml_app` schema

## Additional Resources
- [Architecture Overview](docs/dev_reference/main/architecture_overview.md): High-level system design
- [ReStructure Admin Guide](docs/admin_reference/main/README.md): Instructions for configuring the platform
- [Template Structures](app/models/admin/defs): Various files providing outlines for configurations and defintition of admin panel fields
- [Supplementary Developer Docs](docs/dev_reference/main/README.md): Details on common developer requirements
- [Various End-User App Guides](docs/app_reference): Highlight how end-user applications are used
- [API Examples](app-scripts/api/README.md): Sample API usage and BASH scripts