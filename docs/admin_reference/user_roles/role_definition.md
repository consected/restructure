# Role Definition

Every *User Role* is associated with an *App Type*, so the assignments and authorizations that are made through it only apply to the user when that app is selected for use.

The *role name* field is a text field that provides selections of existing names when you start typing. Simply tab out or click on the selected item in the list, or just exit the field with a new value if an existing suggestion does not match what you need.

Most *role names* are simply identifiers meaningful to the administrator, rather than carrying any inherent meaning. The *role name* will appear in the other admin functions that associate entries with a role.

Names that are used to enable *Activity Log* process functionality must match the names used in the configuration, and will be provided to administrators by the process administrator.

[Filestore Role Names](#filestore-role-names) are specially formatted and will be provided by the application server administrator.

Every **User Role** entry has a user selected, to receive that role. The list of **User Roles** is ordered by user then role name, so you can easily see all the roles assigned to a specific user. If instead you want to see all the users assigned to a role, either click the *role name* table heading, or use the filters.

## Role Naming for User Access Controls

*User Role* naming is important when applied to *User Access Controls*, since the naming sets the priority with which they are applied. Roles that appear higher up the *User Access Controls* list override access to the same resource from roles that appear lower.

As a rule of thumb, for a general, default role, name the role like `user - some function`, where *some function* represents the process a user with that role has access to. Then for higher priority roles, those that will override the default, name something like `org role - some function`, where the *org role* could be something like 'manager'.

For example, a process could have roles defined: `user - scheduling`, `planner - scheduling`, `approver - scheduling`,`reviewer - scheduling`

Any role name that is earlier alphabetically will override those farther down the alphabet, meaning that `user - ...` is a convenient convention for default users since it will be overridden in most cases.

## Filestore Role Names

*Filestore Role Names* carry a special meaning. They are specially formatted text that has a meaning to Filestore when deciding if a user can access a specific container.

A *Filestore Role Name* links a user to an application server operating system group. Specific groups are used to authorize access to the underlying filesystem directories that files are stored to.

The names are formatted as `nfs_store group <group id>` - for example `nfs_store group 600` allows the user access to underlying storage directories assigned group with ID 600. The application server administrator will assign the operating system groups, and let you know which group IDs are in use for a specific app and type of container.

## @template users

To make it easier for app administrators to provision new users, template users with usernames like `<meaningful-name>@template` can be added through the [Usernames and Passwords](../users/user_profile_configuration.md), and subsequently assigned specific roles. A template user can then be copied to a new user, assigning all the template user's roles (within the selected app) to the new user. More details are provided in [Copying User Role Templates](copying_user_role_templates.md).

Every new *role name* that is created within an app that didn't previously exist, will have an additional entry made with the assigned user `template@template`

This is a template user that allows export of all roles to other servers when using the *App Type* export functionality. In most cases there should be no reason to edit the template definition. An app administrator defining an app may occasionally disable a template entry to ensure that a *role name* that is no longer used will be exported.
