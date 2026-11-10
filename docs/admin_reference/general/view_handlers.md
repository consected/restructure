# `view_options` - `view_handlers`

View handlers add model-level behavior (validations, associations, helper methods) and UI behavior to a dynamic model. They are listed in the `view_options` of the model's options:

```yaml
default:
  view_options:
    view_handlers:
      - rec_type
      - rank
```

`view_handlers` must be a YAML list, even when it contains only one name:

```yaml
view_handlers:
  - rec_type
```

Each name is matched to a `ViewHandlers::<Name>` module in the server code. A name with no matching module is ignored on the server, so it can be used just to trigger UI behavior (the browser looks for a matching handler in `_fpa.view_handlers`, and `<name>_edit` for edit forms).

See [view_options](view_options.md) for the other display and layout options.

## General selection requirements

Several handlers validate or label values using General Selections (configured in the admin panel). The *item type* of a General Selection is the model's association name followed by a suffix for the field. The association name is the pluralized, underscored full class name, for example `dynamic_model__contact_infos` for the dynamic model table `contact_infos`.

- The admin panel only offers an item type once the dynamic model exists and has the field, so create the dynamic model first, then add its General Selections.
- `rec_type` is optional and is not checked against a list until at least one rec-type selection exists. Once selections exist, `rec_type` is required and must match a selection. The validation reads the current selections; rec-type Master associations for `rec_type` and `contact` are created when the model class is generated, so later-added associations appear after regeneration.
- For `rank`, the shared user validation checks every non-nil value against its resolved rank name. `rank` and `contact` need an `_rank` selection; `subject` may use built-in accuracy-score names when no rank selection matches. Without an available match, an assigned rank is invalid. The `rank` handler additionally requires a rank value when the field exists.
- For `source`, nil values pass the shared check, but every non-nil value must resolve to a `_source` selection; an empty string does not bypass this lookup. `contact` permits a nil source; `subject` requires a present source when a rank is set.

## Master association requirement

The `rec_type`, `contact` and `subject` handlers require `foreign_key_name: master_id`. The rec-type associations added by `rec_type` and `contact` do not specify a custom Master key. `subject` also creates a direct Master association, and its configured primary key is the dynamic model's key rather than the Master's crosswalk key. A crosswalk or external-ID foreign key can therefore associate records with the wrong Master. DynamicModel validation rejects these handlers when `foreign_key_name` is blank or is not `master_id`, and reports the offending handler names on `foreign_key_name`.

`rank` uses the model's configured `master` association when changing primary status; it does not define a separate Master association that requires `master_id`. `address` and `secondary_info` do not add Master associations, so this requirement does not apply to them.

## Available handlers

| Handler | Purpose | Required fields | General Selections (item type suffix) |
| --- | --- | --- | --- |
| `rec_type` | Rec-type scoped Master associations and rec_type validation | `rec_type`, `data`; `foreign_key_name: master_id` | `_rec_type` |
| `rank` | Requires `rank` when the field exists; validates assigned values against their selection name | `rank` (when present) | `_rank` for assigned values |
| `contact` | Contact record behavior: rank, rec_type and source | `rank`, `rec_type`, `data`, `source`; `foreign_key_name: master_id` | `_rec_type`, `_rank`, `_source` |
| `address` | Address behavior: zip validation, state and country names | `zip`, `state`, `country`, `region`, `postal_code` (each optional, used when present) | None |
| `subject` | Subject behavior: date checks, accuracy rank names, single Master association | `source` and `rank` (together), `birth_date` and `death_date` (optional); `foreign_key_name: master_id` | `_source`; `_rank` (optional, with accuracy-score fallback) |
| `secondary_info` | Marks the model as a subjects category model; no other behavior | None | None |

### `rec_type`

Includes `RecTypeHandler`. For each valid rec type (from the General Selections) it adds a Master association named `<association name singular>_<rec_type>` pluralized, scoped to that `rec_type` and ordered by rank when the model has a `rank` field. For example, rec types `email` and `phone` on `dynamic_model__contact_infos` add `master.dynamic_model__contact_info_emails` and `master.dynamic_model__contact_info_phones`. A scope for each rec type is also added to the model class.

- Fields: requires both `rec_type` and `data`. A model with the handler but no `rec_type` field is left unchanged. The definition must use `foreign_key_name: master_id`.
- General Selections: `<association name>_rec_type`, with a value for each rec type (`<association name>_type` is also read, but the admin panel only offers `_rec_type`). Add them after creating the dynamic model. The associations are built when the model class is generated, so they appear for selections added later once the class is next generated (for example after a server restart).
- With no rec-type selections, this handler does not require `rec_type` or check it against a list. Once selections exist, `rec_type` is required and must match one of their values.
- Rec type values such as `phone` and `email` also activate the built-in formatters in `Formatter::Formatters` and matching validators in `app/models/validates/<rec_type>_validator.rb`, which format and validate `data`.

### `rank`

Requires `rank` to be set.

- Fields: `rank`. A model with the handler but no `rank` field is left unchanged.
- General Selections: `<association name>_rank` provides the rank choices and names. The conventional values are Primary `10`, Secondary `5` and Inactive `0`.
- Every dynamic model already includes `RankHandler` through `Dynamic::DynamicModelBase`, so primary demotion happens on any dynamic model with a `rank` field, with or without this handler: when a record is saved with the Primary rank, other Primary records for the same master (and the same `rec_type`, if the model has one) become Secondary. The `rank` handler only adds the rank-required validation.

### `contact`

The handler used by player contacts: validates `source` (when present) and requires `rank`, and includes `RankHandler` and `RecTypeHandler`. `data` is used as the secondary key for lookups. The definition must use `foreign_key_name: master_id` because the generated rec-type associations do not specify a custom Master key.

- Fields: `rank`, `rec_type`, `data` and `source`.
- General Selections: `_rec_type`, `_rank` and `_source`. Once rec-type selections exist, `rec_type` is required and must match one. `rank` is required and its assigned value must match `_rank`; without rank selections, no assigned rank is valid. `source` may be nil, but any non-nil value must match `_source`.
- Rec-type associations are generated as for `rec_type`.

### `address`

Validates `zip` as a US zip code when the model has a `zip` field, and adds `state_name` and `country_name` helper methods (from the `state` and `country` fields, when present). The UI handler lays out the state, country and source names, and the edit form handler `address_edit` masks the zip field and switches between US fields (`state`, `zip`) and non-US fields (`region`, `postal_code`) according to `country`.

- Fields: all optional; each feature applies only when its field exists.
- General Selections: none required. State names come from the address states list and country names from ISO 3166 country data.

### `subject`

The handler used by player information records: checks that `birth_date` is not after today or after `death_date`, provides accuracy rank names (`rank_name`, `accuracy_score_name`), and adds a singular Master association (for example `master.dynamic_model__subject_info`) so a single record can be used in substitutions, such as `{{dynamic_model__subject_info.last_name}}`. The definition must use `foreign_key_name: master_id` because this association does not use the Master's crosswalk key.

- Fields: when the model has `rank` and a rank value is set, `source` is required and must be valid. A rank value must match `_rank` or a built-in accuracy score. `birth_date` and `death_date` are optional.
- General Selections: `<association name>_source` for source values; any non-nil source must match one. `<association name>_rank` supplies rank names when defined, with built-in accuracy scores as fallback. Without either a matching rank selection or accuracy score, any assigned rank is invalid.

### `secondary_info`

Only sets the model category to subjects. No fields or General Selections are needed.
