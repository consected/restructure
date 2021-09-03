# Activity Log Process Steps (Process Activities)

*User Access Controls* for the resource type *activity_log_types* grant users access to individual *Process Activities* within an *Activity Log Process*. Access may be to *create* new records, only *read* existing records, or *update* existing records.

If a user does not have access to a *Process Activity*, via a *User Role* or directly having a *User* entry, the user will not be able to see the existence of any this type of *Process Activity* when viewing an *Activity Log* panel. If the user has *create* access, they will be able to create new records of that type to record their activities. If they only have *update* or *read*, they will see the existing *Process Activities*, but will not be able to add new ones.

When selecting a *Process Activity* in the *Resource Name* field, all steps are listed, grouped by *Activity Log Process*.

## Activity Log Tables

A user that is intended to have access to an *Activity Log Process* must have appropriate [table user access controls](tables.md) to the database table holding the *Activity Log* data, in addition to the individual *Process Steps*.
