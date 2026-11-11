# App Configurations

## Introduction

**App Configurations** provide configurations for many aspects of app-specific functionality. Each *App Configuration* entry is a simple key / value pair, and each key has specific requirements.

Administration is provided in [Admin: App Configurations](/admin/app_configurations)

## Definitions

!defs(app_configuration_defs.yaml)

## Message Notification Contact Matching

- **message notification contact resources**: a YAML hash mapping `email` and `phone` to `Master` contact association names. Each defaults to `player_contact_emails` and `player_contact_phones`. Each association must be a `has_many` whose table has `master_id` and `data` columns (`data` holds the email address or phone number). Any filtering the association defines, such as a `rec_type`, is applied, so a plain table containing only emails or only phone numbers works without a `rec_type` column. Invalid YAML or an unknown/invalid association is logged during live notifications and counted as a failure by the strict backfill task.
- **default phone country code**: the country calling code used when matching notification numbers. Defaults to the server setting `DefaultPhoneCountryCode` (`FPHS_DEFAULT_PHONE_COUNTRY_CODE`), or `1`. Explicit `+` numbers from another country are matched only by their full digits; those digits may still collide with a local number, which is an accepted limitation.
- **default phone trunk number**: the national trunk prefix used when matching notification numbers. Defaults to the server setting `DefaultPhoneTrunkNumber` (`FPHS_DEFAULT_PHONE_TRUNK_NUMBER`), or `1`.

Phone matching compares all digits in the recipient and stored contact. A contact number
with extension digits therefore does not match a recipient containing only the base number.
