# `_configurations`
## Runtime and Structural Configurations

Control how the definition behaves at runtime: versioning, secondary keys, view SQL, migration prevention, batch triggers, uniqueness, master record handling, and more.

`foreign_key_through_external_id` is what gives a definition without a `master_id` column a
master record scope. See [record scoping](scoping.md) for what that affects.

```yaml
!defs(extra_options_top_level_configurations_defs.yaml)
```
