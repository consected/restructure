# Scoping of Conditions and Substitutions

Every conditional calculation and curly brace substitution is evaluated against a
**current record** — the record being created, edited, shown, validated, or the record
that fired a save trigger. Almost everything else that a configuration can reach is
found *through that record's master record*.

This page explains how the master record scope is established, what happens when a
definition has no master record, and how the *Foreign key name* definition field and the
`_configurations.foreign_key_through_external_id` setting change the result.

Related references:

- [Conditions](conditions.md) — the condition syntax itself
- [Search scope](conditions_scope.md) — the `masters:`, `no_masters:`, `users` and
  `definition_resources` directives
- [Substitutions](substitutions.md) — the curly brace substitution syntax
- [`_configurations`](configurations.md) — where `foreign_key_through_external_id` is set

## What is in scope

For a definition that is attached to a master record, three things are in scope:

| Scope | Reached by |
| --- | --- |
| The current record | `this:` in conditions, and bare `{{field_name}}` substitutions |
| The current record's own references and embedded items | `referring_record:`, `parent_references:`, `embedded_item:`, `{{embedded_item.field_name}}` |
| Every other record belonging to the same master | naming a table in a condition, and `{{association_name.field_name}}` substitutions |

The third row is the one that depends on the master record. A condition such as:

```yaml
showable_if:
  all:
    dynamic_model__other_records:
      status: complete
```

is turned into a query that starts at the current record's master and joins to the named
resource through it. Similarly, `{{dynamic_model__other_records.status}}` looks up the
association of that name on the master record and takes the first result.

If the current record has no master, neither of these can work.

## How a definition reaches its master record

The *Foreign key name* field on a dynamic model definition decides this. It names the
column on the definition's own table that identifies the master record.

### `master_id` — the normal case

The table has a `master_id` column and everything above applies with no extra
configuration.

> When a definition is first created for a table that already exists, the foreign key
> name is set to `master_id` automatically if the table has a `master_id` column,
> whatever value was entered. An external ID column can therefore only be used as the
> foreign key on a table that has no `master_id` column.

### Blank — a standalone definition

Leaving *Foreign key name* blank produces a standalone definition. It has no `master_id`,
no `master` association, and no master scope. Records are looked up directly rather than
through a master record, and they are not auto-loaded into a master record's panels.

Standalone definitions are useful for lookup and reference tables, but they change how
configurations must be written:

- A condition that names a table **fails with an error** rather than returning false,
  because there is no master to join through. Add
  [`masters:` or `no_masters:`](conditions_scope.md) to give the query a base — which of
  the two depends on the table being searched, as described below.
- `{{association_name.field_name}}` substitutions return blank. In contexts that do not
  ignore missing tags, the substitution raises an error instead.
- Bare `{{field_name}}` substitutions and `this:` conditions are unaffected — they only
  need the current record.

Most conditions written on a standalone definition search another standalone table, such
as a lookup or reference table. Use `no_masters: {}`, which makes the first table named in
the block the base of the query and leaves the masters table out of it entirely:

```yaml
# A standalone definition checking a standalone lookup table of valid site codes
valid_if:
  on_save:
    all:
      no_masters: {}
      dynamic_model__site_codes:
        code:
          this: site_code
        active: true
```

`masters: {}` is the alternative where the table being searched *is* attached to master
records. For a single table it makes no difference to the result — `no_masters: {}` finds
the same records with a simpler query. It earns its place once **more than one**
master-associated table is named, because it keeps the masters table as the base of the
query and so requires them all to match the same master record:

```yaml
# True only where one participant holds both this contact value and a Portland address
valid_if:
  on_save:
    all:
      masters: {}
      player_contacts:
        data:
          this: contact_value
      addresses:
        city: portland
```

Read `masters: {}` here as *the masters table, unrestricted* — not as "the current
record's master", which a standalone definition does not have. Written with
`no_masters: {}` instead, only `player_contacts` would be queried, and `addresses` would
produce a `missing FROM-clause entry for table "addresses"` database error.

### An external ID column, through an external identifier

Where the table has no `master_id` column but does hold an external ID that identifies the
participant — a study ID, a survey identifier, an assignment number — set *Foreign key
name* to that column and name the external identifier definition that holds the same value
in [`_configurations.foreign_key_through_external_id`](configurations.md):

```yaml
_configurations:
  foreign_key_through_external_id: ipa_assignments
```

With both set, the platform joins the record to the external identifier record with a
matching ID, and from there to its master. The record then behaves like any
`master_id`-based definition: `master` and `master_id` both resolve, table conditions use
the default master join, and `{{association_name.field_name}}` substitutions work. If
several external identifier records match, the most recent one is used.

> Setting *Foreign key name* to a column other than `master_id` **without** also setting
> `foreign_key_through_external_id` is not supported. There is nothing to resolve the
> column to a master record, and saving a record fails with an error about `master_id`.

### Crosswalk attributes on the masters table

Crosswalk attributes are the alternative identifier columns held directly on the masters
table: `msid`, `pro_id`, `pro_info_id`, and `contact_id`. They can identify a master in
conditions, and a dynamic model can also use one of these columns as its Foreign key name
to attach directly to that master. In that case the dynamic model's `primary_key_name`
still identifies records in its own table; the crosswalk column is only the master join key.

Other fields on a dynamic model are not master join keys. They require `master_id`, or the
external identifier route above, to gain a master scope.

Once the current record has a master, a crosswalk attribute can be used to reach a
*different* master record from within a condition:

```yaml
all:
  masters:
    msid:
      this: participant_msid
    id: return_value
```

This also works from a standalone definition, and is the way to reach a participant's
records from one. Match the crosswalk attribute against a field on the current record, then
name the master-associated tables to be searched — they are correlated to whichever master
the crosswalk value matched:

```yaml
# From a standalone survey table, check the matched participant's contact records
valid_if:
  on_save:
    all:
      masters:
        msid:
          this: survey_id
      player_contacts:
        rec_type: email
```

This is a condition-time join only when the definition itself is standalone. It gives the
definition no master association, so `{{association_name.field_name}}` substitutions still
return blank, and the records are still not shown in master record panels. A dynamic model
whose Foreign key name is one of the four supported crosswalk columns has a direct master
association instead, so its normal master scope, substitutions, and master-panel loading
are available.

To make a table keyed by a crosswalk value behave as a full master-associated definition,
back the definition with a view that resolves the master, using
[`_configurations.view_sql`](configurations.md):

```yaml
_configurations:
  view_sql: |
    select s.*, m.id master_id
    from survey_data s
    inner join masters m on m.msid = s.survey_id
```

The view has a `master_id` column, so *Foreign key name* is set to `master_id` and the
definition behaves like any other `master_id`-based one — the default master join, working
substitutions, and a place in the master record panels. A joined view like this is not
updatable, so records can only be read through it. Setting
`_configurations.view_skip_updates` makes an update appear to succeed so that save triggers
still fire, but the values are discarded rather than written.

If a definition's own table carries a column named after a crosswalk attribute, the value
is checked for consistency against the record's master when the record is saved.

## Widening the scope in conditions

Two directives change the base of the query that a condition generates. Both are
described in full in the [search scope reference](conditions_scope.md).

| Directive | Base of the query |
| --- | --- |
| *(neither)* | The current record's master record only |
| `masters: {}` | All master records. Add conditions such as `masters: { id: [1, 2] }` to restrict the set |
| `no_masters: {}` | The first table named in the block, queried directly with no masters join |

Neither depends on the *current* record having a master, so both are available to a
standalone definition. They are not interchangeable, though, because they differ in what
they require of the tables being **searched**:

- `masters:` keeps the masters table as the base of the query, so every table named in the
  block must be associated with a master record. Naming a standalone table alongside it
  fails with `Can't join 'Master' to association named '<resource_name>'`. Because the
  masters table correlates them, several master-associated tables named together must all
  match the **same** master record — which is the main reason to choose it. Conditions may
  also be placed on master attributes, including crosswalk IDs.
- `no_masters:` removes the masters table entirely, so the **first** table listed becomes
  the base and no master association is needed by any of them. Any further table named must
  be an association of that first table, or the query fails with a `missing FROM-clause
  entry` database error. Use it for standalone lookup tables, and whenever the records
  being matched are not related to a participant.

Where only one master-associated table is being searched, the two are equivalent.

Naming both in the same block is allowed. `no_masters:` takes effect, so `masters:` is
treated as an ordinary table condition on the masters table rather than as a scope
directive — which is a concise way of querying master records directly:

```yaml
# Look up a master record by its crosswalk ID, ignoring the current record's master
all:
  masters:
    msid: 123456
    id: return_value
  no_masters: {}
```

There is no equivalent directive for substitutions. A `{{association_name.field_name}}`
substitution can only follow associations from the current record's own master. To pull a
value from elsewhere, use a condition with
[`return_value`](conditions_returns.md) and place the result in a
[save trigger variable](set_variables.md) or a save trigger result, then substitute that.

## Scope in extra options

Conditional options are evaluated against the record they are configured on, at the point
the platform needs the answer:

| Option | Current record |
| --- | --- |
| `creatable_if` | The current activity log record, or the record holding the `references:` entry |
| `editable_if`, `showable_if`, `valid_if` | The existing record |
| `add_reference_if` | The record the reference would be added from |
| `show_if` | The record being displayed or edited |
| `preset_fields`, `set_variables`, field defaults | The record being initialised or saved |

## Scope in save triggers

### Foreground triggers

A save trigger runs with the record that fired it as the current record, and the same
master scope as any other condition. This applies to the trigger's own `if:` condition, to
`with:` attribute values, and to every substitution in the trigger's configuration.

Values accumulated during the save are also in scope:

- `{{save_trigger_results.<name>}}` in substitutions, read in conditions as the
  `save_trigger_results` attribute of `this:`
- `{{variables.<name>}}` in substitutions, written by [`set_variables`](set_variables.md)
  and read in conditions as the `trigger_variables` attribute of `this:`

Both are held in memory on the record for the duration of the save. They are not stored
in the database.

Triggers that create records elsewhere — [`create_master`](save_trigger_create_master.md),
[`create_reference`](save_trigger_create_reference.md) with `in: master` — do not change
the scope of later triggers in the same list. The current record remains the record that
fired the trigger, unless `create_master` was configured with `move_this`, which moves the
current record to the new master and so changes the scope from that point on.

### `background:` triggers

[`background`](save_trigger_background.md) queues its list of triggers as a job. The job
loads the record again from the database by ID and sets the current user from the user ID
that was recorded when the job was queued.

The consequences for scope are:

- The record is the **saved** version. Any in-memory changes not written to the database
  are not visible.
- `save_trigger_results` and `variables` accumulated by foreground triggers are **not**
  available. Anything a background trigger needs must be stored on a record first.
- The master scope is resolved exactly as it is in the foreground, by whichever of the
  routes above the definition uses. A standalone definition has no more master scope in a
  background trigger than it does in the foreground.

### `notify` triggers

[`notify`](save_trigger_notify.md) resolves its own configuration immediately, against the
current record in memory. `if:`, the recipients, `subject:` and the string values of
`extra_substitutions:` are all substituted at that point, as is `content_template_text:`
where it is used. It then creates a message notification recording the record's type, ID
and master ID, and queues a job to send it.

The message body itself is not rendered until that job runs. It re-loads the record by ID
and renders the layout and content template against it, so substitutions there resolve
against the saved record and its master, not against the in-memory state at the time the
trigger ran.

This is the practical difference between the two ways of supplying content. A named
`content_template:` is fetched and substituted only at send time. `content_template_text:`
is substituted at trigger time as well, so it sees the in-memory record — but a tag it can
not resolve then is replaced with a blank rather than being left for the send-time pass.

For a standalone definition the recorded master ID is blank, so the message template
cannot use `{{master.*}}` or association substitutions.

### `batch_trigger` and `run_batch_trigger`

A [batch trigger](batch_trigger.md) runs once per record selected, and each record in turn
is the current record with its own master scope. A batch over a standalone definition has
no master scope for any of its records.

## Choosing an approach

| Requirement | Configuration |
| --- | --- |
| Records belong to a participant | *Foreign key name* `master_id` |
| Records are keyed by a study or survey ID, with no `master_id` column | *Foreign key name* set to that column, plus `_configurations.foreign_key_through_external_id` |
| Records are keyed by a masters crosswalk value (`msid`, `pro_id`, `pro_info_id`, or `contact_id`) | Set *Foreign key name* to that crosswalk column; keep *Primary key name* set to the dynamic table's own key, normally `id` |
| Records are a shared lookup table, unrelated to participants | *Foreign key name* blank, and `no_masters: {}` in conditions |
| A condition must reach records belonging to another participant | `masters: {}`, restricted by ID or a crosswalk attribute |
| A substitution must use a value from outside the current master | Return it with a condition into a save trigger variable, then substitute the variable |
