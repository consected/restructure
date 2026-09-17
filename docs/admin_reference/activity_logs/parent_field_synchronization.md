# Activity Log: Parent Field Synchronization

An activity log field that also exists as an attribute on its parent item type (`item_type`) is automatically synchronized from the parent.

This applies to fields listed in `fields:` or a traditional `field_list`. Such fields are excluded from the activity form and rejected from submitted form data, even though they are listed. Their values are copied from the parent record whenever the activity log is saved.

This applies regardless of the parent's type: dynamic model, external identifier, or core model such as `player_contact`. This behavior is unique to activity logs; dynamic models and external identifiers have no equivalent parent-field synchronization.

The admin panel's "synced fields" panel, on an activity log definition's Details tab, lists fields currently affected by synchronization.

## Opting Fields Out

Use `_configurations.no_sync_fields` to keep an overlapping field independently editable on the activity log. The value may be one field name or an array of field names:

```yaml
_configurations:
  no_sync_fields:
    - status
    - disabled
```

Each configured name must be present in the inferred activity-log/parent attribute overlap before opt-outs are applied. Unknown, misspelled, or non-overlapping names produce a configuration error.

Semantic validation is reported through the standard configuration errors shown in the admin panel. If parent metadata is unavailable, the configuration error explains that validation could not be performed, while the activity-log Details panel shows the existing parent-resolution diagnostic. Runtime sync access raises a clear error rather than treating unverified fields as synchronized or independent.

The option only applies to activity logs; it has no effect on dynamic models or external identifiers. Opted-out fields remain available in activity forms and submitted parameters, are not copied from the parent on save, and are shown separately from effective synced fields in the admin details panel.
