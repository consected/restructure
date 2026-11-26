# `fields`
## Displayed Field List

Specify the ordered list of fields to display for this definition or extra log type. Only listed fields will be shown.

Field names in dynamic models, activity logs and external identifiers must not start
with `all`, `any`, `not_all` or `not_any` followed by the end of the name or a non-letter
(such as in `all_2`, `all2` or `not_any_cancelled`). A following letter, as in
`allow_this_request`, `anyone`, `allergies` or `not_allowed`, keeps the name ordinary.
Reserved condition-selection prefixes are reported as configuration notices but do not
prevent saving. See [Conditions](conditions.md) for details.

```yaml
!defs(extra_options_fields_defs.yaml)
```
