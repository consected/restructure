# `set_variables`
## Runtime Variables with Conditional Logic

Define an ordered list of variables within each extra log type or `default:` option type. Unlike `_constants` (which are global and static), `set_variables` are evaluated per option type at runtime and can use substitutions and conditional logic.

Variables are accessible via `{{variables.varname}}` or `{{variables.hashvar.key1}}` substitutions, and through `element: variables.varname` in conditional calculations.

### How it works

- Each entry specifies a `name` and a `value`
- Values may include `{{substitution}}` tags resolved against the current item's data
- An optional `if` condition (using [standard conditional syntax](conditions.md)) controls whether the variable is set
- Entries are processed **in order** — later entries with the same name override earlier ones
- This allows a default value to be set first, then conditionally overridden

### Value types

- **String**: a plain string or a string with `{{substitution}}` tags
- **Hash/Object**: use the `object:` key to define structured data, accessible with dot notation (e.g. `{{variables.config.key1}}`)

### Comparison with `_constants`

| Feature | `_constants` | `set_variables` |
|---|---|---|
| Scope | Global (all option types) | Per option type |
| Values | Static key-value pairs | Dynamic (supports substitutions) |
| Conditions | No | Yes (`if:` conditions) |
| Access | `{{constants.name}}` | `{{variables.name}}` |

```yaml
!defs(extra_options_set_variables_defs.yaml)
```
