# `fields`
## Displayed Field List

Specify the ordered list of fields to display for this definition or extra log type. Only listed fields will be shown.

Field names in dynamic models, activity logs and external identifiers must not start
with `all`, `any`, `not_all` or `not_any` (including names without an underscore, such as
`allergies` or `anyone`); these reserved condition-selection prefixes are reported as
configuration notices but do not prevent saving. A name that contains one of these
strings elsewhere, such as `many_things` or `company_records`, is unaffected. See
[Conditions](conditions.md) for details.

```yaml
!defs(extra_options_fields_defs.yaml)
```
