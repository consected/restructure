# `create_reference`
## Create a Reference to Another Model

Create a model reference (and optionally a related record) when this trigger fires.

The `in` option controls which record acts as the "from" record in the model reference. By default,
`in: this` creates the reference from the current item. You can alternatively specify
`in: { specific_record: {...} }` to create the reference from any other record (looked up by criteria),
rather than the current item.

```yaml
!defs(save_triggers_create_reference_options_defs.yaml)
```
