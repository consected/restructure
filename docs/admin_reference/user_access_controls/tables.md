# Tables

*User Access Controls* for *tables* grant users access to all the data in the specified table. Access may be to *create* new records, only *read* existing records, or *update* existing records.

If a user does not have access to a table, via a *User Role* or directly having a *User* entry, the user will not be able to see the existence of any this type of record when viewing a master record.

Tables that are protected by *User Access Controls* are:

- primary participant details tables
- dynamic models
- activity log processes
- external identifiers

## Trackers Table

Users with *create* or *update* access on any table, must also have *create* access to the **trackers** table, since any data changes also lead to tracker entries being made.

## Activity Log Tables

A user that is intended to have access to activity log processes, must have appropriate access to the table holding the activity log data, in addition to the required [activity log type](activity_log_types.md) access definitions.
