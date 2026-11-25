# External Identifiers

## Introduction

**External Identifiers** allow *master records* to be identified by numeric or alphanumeric identifiers that are specific to an app. They allow deidentified references to participants to be passed outside of the app, and subsequently searched to find the participants they belong to.

*External Identifiers* may be generated for a specific study, to provide a participant identifier within that study, or to record externally generated identifiers such as *Medical Record Numbers (MRNs)*.

Administration is provided in [External Identifiers](/admin/external_identifiers)

## Field Definitions

!defs(external_identifier_field_defs.yaml)

Because an external identifier's `name` is also its database table and resource name, neither `name` nor its fields (`external_id_attribute` and `extra_fields`) may start with `all`, `any`, `not_all` or `not_any` (including names without an underscore, such as `allergies` or `anyone`). These reserved condition-selection prefixes are reported as configuration notices without preventing saving. Names containing these strings elsewhere, such as `company_records`, are unaffected. See [Conditions](../general/conditions.md) for details.

## Contents

- [Detailed Options](detailed_options.md)
- [Form Field Types](../general/field_types.md)
