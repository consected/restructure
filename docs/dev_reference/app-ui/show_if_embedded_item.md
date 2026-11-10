# show_if with embedded_item

## Overview

The `show_if` configuration option in dynamic models and activity logs supports conditional field visibility based on data from embedded items. This feature allows parent forms to show/hide fields based on attributes in a separate embedded model.

## Implementation

### JavaScript Logic

The client-side evaluation is handled in `app/assets/javascripts/app/_fpa_show_if.js` within the `calc_conditions` method. When a condition includes `embedded_item`, the logic:

1. Checks if the condition field is `'embedded_item'`
2. Retrieves embedded data from `data.embedded_item` (populated when embed: configuration exists)
3. Recursively evaluates conditions against the embedded item's attributes
4. Supports all standard condition operators: `all`, `any`, `not_all`, `not_any`
5. Handles explicit comparison operators like `>=`, `<`, `in?`, etc.

### Critical Implementation Detail

The `embedded_item` check must occur **before** the generic nested condition handling to prevent infinite recursion. The code structure is:

```javascript
// Check for embedded_item specifically first
if (cond_field == 'embedded_item') {
  // Handle embedded_item conditions
  return calc_conditions(cond_val, data.embedded_item);
}

// Then handle generic nested conditions
if (typeof cond_val === 'object' && !Array.isArray(cond_val)) {
  // Generic nesting logic
}
```

### Configuration Requirements

The parent model must define an `embed:` configuration that references the embedded model:

```yaml
embed:
  resource_name: dynamic_model__embedded_records
  # Optional: resource_id can be specified if not using foreign key lookup
```

The embedded item data is automatically loaded and attached to the parent form data as `data.embedded_item`.

## Usage Example

### Parent Model Configuration

```yaml
fields:
  - main_field
  - conditional_field_1
  - conditional_field_2

embed:
  resource_name: dynamic_model__embedded_status_records

show_if:
  conditional_field_1:
    embedded_item:
      status: complete
  
  conditional_field_2:
    all:
      embedded_item:
        score:
          - ">="
          - 80
        approved: true
      this:
        ready: true
```

### Embedded Model Configuration

```yaml
fields:
  - status
  - score  
  - approved
  - parent_record_id  # Foreign key back to parent
```

## Testing

### JavaScript Tests

Location: `spec/javascripts/`

Tests validate:

- Field show_if
- Tag formatting

Run with: `app-scripts/jasmine-serve.sh`

### Model Configuration Tests

Location: `spec/models/option_configs/dynamic_model_options_spec.rb`

Tests validate:

- Configuration parsing
- Nested show_if conditions with embedded_item

Run with: `bundle exec rspec spec/models/option_configs/dynamic_model_options_spec.rb`

### Feature Tests

Location: `spec/system/dynamic_model_show_if_spec.rb`

Tests validate:

- UI behavior with embedded_item conditions
- Field visibility toggling based on embedded data changes
- Integration with form rendering

Support module: `spec/support/test_show_if_dm_support.rb`

Run with: `bundle exec rspec spec/system/dynamic_model_show_if_spec.rb`

## Related Documentation

- [Admin Reference: Substitutions](../../admin_reference/general/substitutions.md) - Using embedded_item in show_if
- [Admin Reference: Conditions](../../admin_reference/general/conditions.md) - Complete condition syntax
- [Admin Reference: show_if Option](../../admin_reference/general/options/show_if.md) - show_if configuration options
