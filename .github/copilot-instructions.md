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

- **RSpec**: Main test framework with parallel execution support
- **Capybara**: Feature tests with Firefox/Geckodriver
- **Database Cleaner**: Test isolation
- Tests require Filestore mount setup - this needs "sudo" to run: `app-scripts/setup-dev-filestore.sh`

Test commands:
```bash
bundle exec rspec  # Run in headless mode
NOT_HEADLESS=true bundle exec rspec  # Suggest a human developer reviews the actual browser output
app-scripts/parallel_test.sh       # Parallel execution
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
- Always format `.rb` files using the default VSCode formatter
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