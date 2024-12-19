# Protocols

## Introduction

**Protocols** and their related **sub processes** and **events** provide a way to classify activities related to a participant in the **tracker**. These are a
related through a simple hierarchy, to allow a user to refine the specification of the activity performed. For example:

- *protocol*: **Targeted Study**
  - *sub process*: **Opt In**
  - *sub process*: **Sent**
    - *event*: Email
    - *event*: Text
  - *sub process*: **Exit**
    - *event*: Withdrew
    - *event*: Lost to Follow Up
    - *event*: Removed by Study Team
  - *sub process*: **Complete**
- *protocol*: **General Awareness**
  - *sub process*: **Opt In**
  - *sub process*: **Sent**
    - *event*: Email
    - *event*: Text
    - *event*: Postal Mail
  - *sub process*: **Opt Out**
    - *event*: Email
    - *event*: Text
    - *event*: Postal Mail
    - *event*: All Communications
...

Every *tracker* entry must be classified with at least a *protocol* and *sub process*. A related *event* must also be specified, if at least one has been defined for the parent *sub process*.

**NOTE:** The *tracker* user interface shows uses the terms **Protocol**, **Status** and **Method** to refer to **Protocol**, **Sub Process** and **Event**.

## Add a new Protocol

Add a new *Protocol* by clicking the **+ Protocol** button. The following field may be set:

- **Name** - a mixed case, human-readable name. When used within the database, this name will be case sensitive
- **Position** - (optional) set the relative position in the list protocols displayed in the tracker

## Position

The [App Configurations](../app_configurations/0_introduction.md) **tracker order** setting allows the default ordering of tracker protocols to be
changed. This allows the protocols to appear as:

- protocol position value
- protocol name
- latest entry

## Adding Sub Processes to a Protocol

After a *protocol* has been added, new *sub processes* may be added to it, to build up the hierarchy. Click the link **edit sub processes** to
add or disable *sub processes* for the *protocol*.

Each *sub process* may only belong to a single *protocol*. It has just a single field defining it:

- **Name** - a mixed case, human-readable name. When used within the database, this name will be case sensitive

## Adding Events to a Sub Process

After a *sub process* has been created for a *protocol*, new *events* may be added to it, to complete the hierarchy.
Click the link **edit events** to add or disable *events* for the *sub process*.

Each *event* may only belong to a single *sub process* and subsequently *protocol* grandparent.
It has the following fields:

- **Name** - a mixed case, human-readable name. When used within the database, this name will be case sensitive
- **Milestone** - (optional) a value to assist with definition of events - or may control if the UI should notify the
  current user when a participant with has a milestone set
- **Description** - (optional) the text displayed for a "milestone"

### Milestone

The **milestone** may simply be used to provide addition definition of the *event*. There are also special cases, which control notifications presented
to the user on the UI when a participant record is opened. By setting the value to one of:

- **notify-user**
- **always-notify-user**

a notification prompt will pop up for the user when a participant has a tracker entry with this event set. The *Description* field sets the message that is presented.

Additionally, a tracker entry with **notify-user** milestone may be overridden by a tracker entry with **override-alert** milestone set in a later event. Tracker events with milestone **always-notify-user** can't be overridden, and will always appear.

## Database Tables

For information about access trackers within the database, see [Tracker Protocol / Sub Process / Event in the Database](db_tables.md)
