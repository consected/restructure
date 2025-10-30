# ReStructure AI Coding Guidelines

## Architecture Overview

**ReStructure** is a research data management platform built on Rails 7 with a flexible, configuration-driven architecture. The system is designed around five core concepts:

1. **App Types**: Encapsulate all configurations for an end-user application (like Zeus or Athena)
2. **Master Records**: Central participant/subject records that everything relates to
3. **External Identifiers**: Real-world numbering systems for people or entities represented by master records
4. **Activity Logs**: Process management and case management workflows with embedded steps
5. **Dynamic Models**: Runtime-generated Rails models from database configurations

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

## Essential Development Patterns

### Dynamic Model System

The platform's core feature is runtime model generation. When developing:

- Models are created through admin configurations, not code files
- Use `DynamicModel.define_models` to regenerate after config changes  
- Controllers inherit from `DynamicModelControllerHandler` for generated models
- Routes are auto-generated via `DynamicModel.routes_reload`

Example workflow:
```ruby
# After creating a dynamic model config
DynamicModel.routes_reload
Rails.application.routes_reloader.reload!
```

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

### UI
- The UI is split between user-facing single-page application and admin panel
  - `app/assets/javascripts/application.js` handles end-user logic
  - `app/assets/javascripts/admin.js` handles admin panel logic, which relies on single-page application components from the end-user front-end
- The `app/assets/javascripts/app/_fpa.js` file contains the main single-page application front-end application logic.

### Environment Variables
Key variables (see `app-scripts/get-aws-env-vars.sh`):
- `FPHS_POSTGRESQL_*`: Database connection
- `FPHS_2FA_AUTH_DISABLED`: Disable 2FA in development
- `FPHS_LOAD_APP_TYPES`: Load dynamic configurations on startup

## Testing Approach

- **RSpec**: Main test framework with parallel execution support
- **Capybara**: Feature tests with Firefox/Geckodriver
- **Database Cleaner**: Test isolation
- Tests require Filestore mount setup: `app-scripts/setup-dev-filestore.sh`

Test commands:
```bash
IGNORE_MFA=true bundle exec rspec  # Skip AWS MFA
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