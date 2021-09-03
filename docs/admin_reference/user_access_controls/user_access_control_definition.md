# User Access Control Definition

**User Access Controls** are defined to grant user access to specific resources based on the membership of a [User Role](../user_roles/0_introduction.md) or the assignment to the user directly. It is recommended that *User Roles* are used to assign *User Access Controls*, unless a very individual requirement for a single user is required.

## Role Naming for User Access Controls

*User Role* naming is important when applied to *User Access Controls*, since the naming sets the priority with which they are applied. Roles that appear higher up the *User Access Controls* list override access to the same resource from roles that appear lower.

As a rule of thumb, for a general, default role, name the role like `user - some function`, where *some function* represents the process a user with that role has access to. Then for higher priority roles, those that will override the default, name something like `org role - some function`, where the *org role* could be something like 'manager'.

For example, a process could have roles defined: `user - scheduling`, `planner - scheduling`, `approver - scheduling`,`reviewer - scheduling`

Any role name that is earlier alphabetically will override those farther down the alphabet, meaning that `user - ...` is a convenient convention for default users since it will be overridden in most cases.

## User Assignments

Specifying a *User* directly in a *User Access Control* entry always overrides access to the same resource for any roles specified.

## Resources and Access Levels

The resources that are controlled by *User Access Controls* are:

- [general](general_resources.md) (the ability to access an app, for example)
- [tables](tables.md) (database tables)
- [reports](reports.md) (search tabs, charts and dashboard components)
- [activity log types](activity_log_types.md) (process steps)
- [limited access](limited_access.md) (to master records having assigned external identifiers or other data items)

Each resource type has different access levels that can be assigned:

- **tables** and **activity log types**
  - **create** - *create* new records, and *update* existing records (implies being able to read them too)
  - **update** - *update* existing records (implies being able to read them too)
  - **read** - *read* existing records
  - **see presence** - only see the presence of a record by its title, rather than all the record data

- **reports** and **general**
  - **read** - grants access to the specific resource

- **limited access**
  - **limited** - limits users to master records only if they have the defined resource
