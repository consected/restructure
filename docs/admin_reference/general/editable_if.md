# `editable_if`
## Conditional Edit Access

Control whether an existing record can be edited, based on a [conditions](conditions.md) reference evaluated at runtime.

If not defined, the default is to allow editing only for the most recently created item in the list. Use `always: true` to make items always editable.

```yaml
!defs(extra_options_editable_if_defs.yaml)
```
