# Manage Administrators

## Introduction

{{#if allow_admins_to_manage_admins}}
Administrators are able to perform a full set of functions to manage other administrator profiles, including adding new administrator profiles.

Available functions include:
{{else}}
Administrators are able to perform a limited set of functions to manage other administrator profiles. This includes:
{{/if}}

- Changing first and last names
- Resetting passwords
- Resetting two-factor authentication
- Disabling currently active administrators
- Changing email address (username) - for other admins only

{{#if allow_admins_to_manage_admins}}
Administrator profiles can also re-enabled after having been previously disabled. Be sure that the **Disabled** filter shows the admins that have been disabled.
{{else}}
Administrator profiles can not be re-enabled after having been previously disabled through the user interface. This requires an authorized operating system admin.
{{/if}}

## Capabilities

Administrators can be assigned a set of **capabilities** when created or edited. The capabilities list the types of functions that are available to the administrator through the admin panel. In this way, administrators can be assigned with different levels of authority to make changes to the system.

## Operating System Administrators

{{#if allow_admins_to_manage_admins}}
Some administration tasks, such as creation of new administrators, re-enabling previously disabled admins and resetting passwords, can also be performed by users with access to the app server operating system.
{{else}}
Adding new administrators and re-enabling disabled administrators can only be performed by users with access to the app server operating system.
{{/if}}

See [Create an admin user or reset an admin account](create_admin.md) for details
