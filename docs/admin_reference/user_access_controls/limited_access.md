# Limited Access

*User Access Controls* for *limited access* restricts users, so that they can only view a *master record* if specific associated data records are present for that *master record*.

A *Limited Access* control will only allow a user access to a *master record* if the specified *External Identifier* or *Dynamic Model* has a record existing associated with the *master record*. If not, the *master record* will not be visible in search results.

An additional option is less restrictive: *limited_if_none* limits users to *master records* that have at least one of the records or associations with this setting. If none of these records appear, the user will not have access.

**NOTE:** unlike other *User Access Controls*, the presence of a *Limited Access* entry for a user acts as a restriction on their access to master records. Based on this blanket restriction, meeting the requirements of the *Limited Access* then grants access to the master record (and associated data).

## Important table restrictions

If a *Limited Access* setting is used referencing a resource such as a dynamic model, it is important that access to this model is controlled appropriately (preventing editing for example) to avoid users granted access from changing the settings that granted them access.

## Limiting to the user the master record was created by

An extension allows the use of a resource *master_created_by_user*, so that we can limit to master records that were created by the current user.

## Limiting to a specific user

An additional extension checks the resource that is being limited on (such as a dynamic model), to see if it has the field *assign_access_to_user_id*. If it does, the limited access filter also checks for the current user ID matching the value in *assign_access_to_user_id*. This allows for instances of this dynamic model to be added with different *assign_access_to_user_id* user IDs, effectively granting these users access to a specific *master* record and its associated references.

## Example 1

*Master records* should be visible to all users with the role `user - internal`, but should only be visible to users with the role `user - external` if an `External ID` *External Identifier* record has been added to the *master record*. Users with `user - limited` will be assigned to all users, but won't grant them access.

For the `user - internal` role, no *Limited Access* entry should be made in the *User Access Controls*.

For the `user - external` role, a *Limited Access* entry must be made. It should have the *resource name* `External ID`, indicating that the external users will only be able to view master records having an `External ID` record in them.

Extending this, specifically entitled users should also be allowed access, by adding a dynamic model named `dynamic_model__access_users`. This dynamic model must have a field in it named `assign_access_to_user_id`, which can be set by a form drop down, or as extra options *save_trigger: update_reference: ...*

After generating the dynamic model definition, add the user access control for the role `user - limited` with *limited_if_none* access on resource `dynamic_model__access_users`. This means that users will be granted access to the master if the dynamic model is added with `assign_access_to_user_id` set appropriately.

## Example 2

The following user access controls are set for different roles and resources. All users have the `user` role. Most users have `user` and `viewer` roles. Only privileged reviewers have the `reviewer - project coordinator` role.

| role                           | access          | resource type  | resource name                            |
| ------------------------------ | --------------- | -------------- | ---------------------------------------- |
| reviewer - project coordinator | limited_if_none | limited_access | dynamic_model__analysis_plans            |
| reviewer - project coordinator |                 | limited_access | dynamic_model__project_add_investigators |
| user                           | limited_if_none | limited_access | dynamic_model__project_add_investigators |
| viewer                         | limited_if_none | limited_access | dynamic_model__study_page_sections       |
| reviewer - project coordinator |                 | limited_access | master_created_by_user                   |
| user                           | limited_if_none | limited_access | master_created_by_user                   |
| viewer                         | limited_if_none | limited_access | master_created_by_user                   |
| user                           | limited_if_none | limited_access | temporary_master                         |

A `reviewer - project coordinator` gains access to all master records that have a referenced `dynamic_model__analysis_plans`, not just master records they created themselves.

A `viewer` will have access to master records that have a `dynamic_model__study_page_sections` - this may be a portal page for example, or to any master records they created themselves.

A `user` - everybody in this app - will only have access to master records they created, unless they have been named in the `assign_access_to_user_id` field in the `dynamic_model__project_add_investigators`. They will also be able to view records in the temporary master records (IDs -1, -2) for the limited time they are working on them. Additional extra options *showable_if*, *editable_if* and *creatable_if* settings limit this more.
