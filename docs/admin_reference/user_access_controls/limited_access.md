# Limited Access

*User Access Controls* for *limited access* restricts users, so that they can only view a *master record* if specific associated data records are present for that *master record*.

**NOTE:** unlike other *User Access Controls*, the presence of a *Limited Access* entry for a user acts as a restriction on their access to master records. Based on this blanket restriction, meeting the requirements of the *Limited Access* then grants access to the master record.

A *Limited Access* control will only allow a user access to a *master record* if the specified *External Identifier* or *Dynamic Model* has a record existing associated with the *master record*. If not, the *master record* will not be visible in search results.

## Example

*Master records* should be visible to all users with the role `user - internal`, but should only be visible to users with the role `user - external` if an `External ID` *External Identifier* record has been added to the *master record*.

For the `user - internal` role, no *Limited Access* entry should be made in the *User Access Controls*.

For the `user - external` role, a *Limited Access* entry must be made. It should have the *resource name* `External ID`, indicating that the external users will only be able to view master records having and `External ID` record in them.
