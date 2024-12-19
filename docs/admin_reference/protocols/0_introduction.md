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

## Add a new Protocol

Add a new *Protocol* by clicking the **+ Protocol** button. The following field may be set:

- **Name** - a mixed case, human-readable name. When used within the database, this name will be case sensitive
- **Position** - (optional) set the relative position in the list protocols displayed in the tracker

## Position

The [App Configurations](app_configurations/0_introduction) **tracker order** setting allows the default ordering of tracker protocols to be
changed. This allows the protocols to appear as:

- protocol position value
- protocol name
- latest entry

## Adding Sub Processes to a Protocol

After a *protocol* has been added, new *sub processes* may be added to it, to build up the hierarchy. Click the link **edit sub processes** to
add or disable *sub processes* from the *protocol*.
