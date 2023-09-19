# App Types

## Introduction

**App Types** represent different user-centric apps (or modules that comprise these apps). Each *App Type* provides the core configurations and setup information for an app. An *App Type* associates all types of components (dynamic models, activity logs, user roles, etc) into a single self-contained bundle. Each *App Type* can:

- be created as a simple configuration, to allow component configurations to be bundled together
- export a YAML file representing all its associated component configurations
- import a YAML (or JSON) file representing all associated component configurations
- export migrations for a Ruby on Rails developer to use to force database updates on another system

Administration is provided in [Admin: App Types](/admin/app_types)

## Add a new App Type

Add a new *App Type* by clicking the **+ App Type** button. The following fields must be set:

- **Name** - a lower case identifier (alphanumeric, including spaces, hyphens and underscores)
- **Label** - a user friendly label
- **Default Schema** - default database schema that underlying database storage will be assigned to if not specified in associated components

## List of App Types

In addition to the primary fields set when an *App Type* is created, the list of configured *App Types* provides the following information:

### ID

The internal ID number for the app type, which is consistent across all servers that share this database.

### Active on Server?

This shows whether the *App Type* active on this server. If an *App Type* is active on a server, it can be accessed by authorized users.

Being active is based on:

- an environment variable configurations `FPHS_LOAD_APP_TYPES` being either unset or listing the *ID* in a comma separated list
- the *default schema* being included in the environment variable `FPHS_POSTGRESQL_SCHEMA` database search path

### Admin has Access?

Indicates whether the current logged in user (typically matching the admin username) has access to the app type. If not, the user can be authorized access through the addition of a [User Access Control](/admin/user_access_controls) either directly associated with the user or by a [User Role](/admin/user_roles).

The *User Access Control* required to grant access to an *App Type* is:

- **App Type** to assign user(s) access to
- **Access** set to *read*
- **Resource Type** set to *general*
- **Resource Name** set to *app_type*

In addition, one of either **User** or **Role** must be set to assign access either directly to an individual user, or to user roles that users may be assigned.

### Admin Links

Simply export the configuration as a YAML file, or export the Ruby on Rails migrations as a Zip file. This is only available for *App Types* that are active on this server.

### Additional Setup

Information is provided showing additional setup required to make an *App Type* active on this server, and able to store files to the Filestore. These actions require a system administrator to update environment variables on the server, used during server startup, or to add configurations to the Filestore filesystem using command line scripts.
