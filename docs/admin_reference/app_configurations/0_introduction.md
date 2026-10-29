# App Configurations

## Introduction

**App Configurations** provide configurations for many aspects of app-specific functionality. Each *App Configuration* entry is a simple key / value pair, and each key has specific requirements.

Administration is provided in [Admin: App Configurations](/admin/app_configurations)

## Definitions

!defs(app_configuration_defs.yaml)

## Message Notification Contact Matching

- **message notification contact resources**: a YAML hash mapping `email` and `phone` to `Master` contact association names. Each defaults to `player_contact_emails` and `player_contact_phones`.
- **default phone country code**: the country calling code used when matching notification numbers. Defaults to the server setting `DefaultPhoneCountryCode` (`FPHS_DEFAULT_PHONE_COUNTRY_CODE`), or `1`.
- **default phone trunk number**: the national trunk prefix used when matching notification numbers. Defaults to the server setting `DefaultPhoneTrunkNumber` (`FPHS_DEFAULT_PHONE_TRUNK_NUMBER`), or `1`.
