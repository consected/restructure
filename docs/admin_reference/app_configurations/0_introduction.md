# App Configurations

## Introduction

**App Configurations** provide configurations for many aspects of app-specific functionality. Each *App Configuration* entry is a simple key / value pair, and each key has specific requirements.

Administration is provided in [Admin: App Configurations](/admin/app_configurations)

## Definitions

!defs(app_configuration_defs.yaml)

## Master Record Banner Titles

The **master header prefix** and **master header title** configurations are substitution templates for the master record banner. Their tags accept [tag formatters](../general/substitutions.md). Date-only fields such as `birth_date` should use the `date` formatter, not the `date_time` formatters, so the day is not shifted. See the date and time formatting section of the substitutions page.

## Search Selector

The **search selector** app configurations control how searchable reports are selected on the master search page. This is an app configuration rather than a page layout setting because it applies to the search form and all reports marked *Searchable*; page layouts configure the result panels shown after a master record is found.

- **search selector**: `tabs` (default) keeps the current report buttons, `dropdown` shows a searchable Chosen select, and `none` hides the searchable report choices. Simple and Advanced Search remain available. Blank values use `tabs`.
- **search selector header** and **search selector footer**: optional Markdown captions above and below the report controls.
- **search selector label**: plain text shown before the dropdown.
- **search selector categorized**: `true` groups dropdown options by report category; each group preserves the reports' configured order. Defaults to `false`.

Each value supports runtime substitutions. The header and footer are interpreted as Markdown after substitution; the label is displayed as plain text. When tabs or the dropdown are available, users can switch between those views with the selector icon. Their choice is retained in a browser cookie per app type. Selecting a different report continues to collapse the previously open search panel.

See [Substitutions](../general/substitutions.md) for available runtime tags and conditional substitutions.

## Message Notification Contact Matching

- **message notification contact resources**: a YAML hash mapping `email` and `phone` to `Master` contact association names. Each defaults to `player_contact_emails` and `player_contact_phones`. Each association must be a `has_many` whose table has `master_id` and `data` columns (`data` holds the email address or phone number). Any filtering the association defines, such as a `rec_type`, is applied, so a plain table containing only emails or only phone numbers works without a `rec_type` column. Invalid YAML or an unknown/invalid association is logged during live notifications and counted as a failure by the strict backfill task.
- **default phone country code**: the country calling code used when matching notification numbers. Defaults to the server setting `DefaultPhoneCountryCode` (`FPHS_DEFAULT_PHONE_COUNTRY_CODE`), or `1`. Explicit `+` numbers from another country are matched only by their full digits; those digits may still collide with a local number, which is an accepted limitation.
- **default phone trunk number**: the national trunk prefix used when matching notification numbers. Defaults to the server setting `DefaultPhoneTrunkNumber` (`FPHS_DEFAULT_PHONE_TRUNK_NUMBER`), or `1`.

Phone matching compares all digits in the recipient and stored contact. A contact number
with extension digits therefore does not match a recipient containing only the base number.
