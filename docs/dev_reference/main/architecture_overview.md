# Architecture Overview

**ReStructure** is a research data management platform built on Rails 7 with a flexible, configuration-driven architecture. The system is designed around five core concepts:

1. **App Types**: Encapsulate all configurations for an end-user application (like Zeus or Athena)
2. **Master Records**: Central participant/subject records that everything relates to
3. **External Identifiers**: Real-world numbering systems for people or entities represented by master records
4. **Activity Logs**: Process management and case management workflows with embedded steps
5. **Dynamic Models**: Runtime-generated Rails models from database configurations

## The Master Record Pattern

Everything in ReStructure relates to a Master record (participant/subject). This is enforced through:

- `master_id` foreign key on nearly all tables (exception: external identifiers before assignment)
- `current_user` passed through master: `master.current_user` not `self.current_user`
- Access controls verified at master level: `master.allows_user_access`
- Controllers set user once: `@master.current_user = current_user`

## Key Components

- **Admin Panel**: Configuration management at `/admin/*` routes using database-stored YAML configs
- **User Interface**: Single-page application with custom JavaScript front-end
- **Filestore**: NFS-based file management with Linux group security
- **Background Jobs**: `delayed_job` for file processing and notifications
- **User Access Controls**: Granular role-based permissions system controlling table/field access

## Top-Down Development Approach

ReStructure follows a hierarchical configuration pattern:

1. **App Type Configuration**: Define the overall application scope and user roles
2. **External Identifier Setup**: Configure real-world ID systems (SSN, study IDs, etc.)
3. **Activity Log Creation**: Define main workflow processes and case management
4. **Activity Log Types**: Configure individual workflow steps/activities within processes
5. **Embedded Dynamic Models**: Create forms and data structures for each workflow step

This approach ensures consistent user experience and proper data relationships throughout the application.

## Activity Log Workflow System

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

# Essential Development Patterns

## Dynamic Model System

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

## User Base Pattern

All user-facing models inherit from `UserBase` through `HandlesUserBase` concern:

- Always requires authenticated user context via `current_user`
- Enforces master record associations (participant linking)
- Implements granular access controls through `user_access_controls`
- Uses crosswalk validation for external identifiers

## User Roles and Access Controls

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

## Configuration-Driven Development

Most functionality is configured, not coded:

- **Access Controls**: `user_access_controls` table defines granular permissions
- **Form Rules**: YAML configurations define field visibility and validation
- **Process Workflows**: Activity log configurations manage case processes
- **Data Structures**: Dynamic model configurations define database schema
- **External ID Systems**: Configure how real-world identifiers map to master records
