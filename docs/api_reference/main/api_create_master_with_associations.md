# API: Create Master Record with Associated Records

## Overview

The `POST /masters/create.json` endpoint creates a master record and optionally
creates multiple associated records (player contacts, addresses, scantrons,
dynamic models, etc.) in a **single atomic transaction**.

If any associated record fails validation, the entire transaction rolls back —
no master record or associated records are persisted.

## Authentication

All API requests require token authentication via query parameters:

| Parameter    | Description                        |
|--------------|------------------------------------|
| `user_email` | Email address of the API user      |
| `user_token` | Authentication token for the user  |
| `use_app_type` | App type ID for the user context |

## Request

**Method:** `POST`
**URL:** `/masters/create.json`
**Content-Type:** `application/json`

### JSON Body Structure

```json
{
  "master": {
    "embedded_item": {
      "<attribute>": "<value>"
    },
    "associations": {
      "<association_name>": {
        "0": { "<attribute>": "<value>" },
        "1": { "<attribute>": "<value>" }
      }
    }
  }
}
```

### Parameters

#### `master[embedded_item]`

Attributes for the first `create_master_with` item (typically `player_info`).
This is the primary record created alongside the master, as configured in the
app configuration `create_master_with`.

#### `master[associations]`

A hash of association names to indexed record attribute hashes. Each key must
be a valid `has_many` association on the `Master` model.

Common association names:

| Association Name                   | Description                          |
|------------------------------------|--------------------------------------|
| `player_contacts`                  | Contact information records          |
| `addresses`                        | Address records                      |
| `scantrons`                        | Scantron external identifier records |
| `dynamic_model__<table_name>`      | Dynamic model records                |

Multiple records can be created for any association by using indexed keys
(`"0"`, `"1"`, `"2"`, etc.).

Only attributes listed in the model's `permitted_params` are accepted.
Unpermitted attributes are silently ignored.

## Example

### Request

```bash
curl -XPOST -s \
  -H "Content-Type: application/json" \
  "https://server.example.com/masters/create.json?\
use_app_type=1&\
user_email=api-user@example.com&\
user_token=SECRET_TOKEN" \
  -d '{
    "master": {
      "embedded_item": {
        "first_name": "jane",
        "last_name": "doe",
        "source": "cis"
      },
      "associations": {
        "player_contacts": {
          "0": { "data": "(617)555-0100", "rec_type": "phone", "rank": 10, "source": "cis" },
          "1": { "data": "(617)555-0200", "rec_type": "phone", "rank": 5, "source": "cis" }
        },
        "addresses": {
          "0": { "street": "123 main st", "city": "boston", "state": "ma", "zip": "02101", "rank": 10, "source": "nfl" }
        },
        "scantrons": {
          "0": { "scantron_id": 12345678 }
        }
      }
    }
  }'
```

### Success Response (HTTP 200)

```json
{
  "master": {
    "id": 12345,
    "msid": "...",
    "player_infos": [ { "first_name": "jane", "last_name": "doe", "..." : "..." } ],
    "..."
  }
}
```

### Error Response (HTTP 400)

Returned when any record fails validation. The entire transaction is rolled back.

```json
{
  "message": "Error creating Master Record: Validation failed: Rank can't be blank"
}
```

## Access Control

The API user must have:

- **`create_master`** permission
- **Create access** to each association type being created (e.g. `player_contacts`, `addresses`)
- **App configuration** `create_master_with` must include the embedded item type

## Transaction Behavior

All records are created within a single database transaction:

1. Master record is created
2. The `create_master_with` embedded item is created (e.g. `player_info`)
3. Each association in `associations` is iterated; records are created with `create!`
4. If any `create!` raises `ActiveRecord::RecordInvalid`, the transaction rolls back
5. On rollback, the API returns the validation error message with HTTP 400

## Related

- [API Scripts README](../../../app-scripts/api/README.md) — sample API usage scripts
- `MastersController#create` — controller action implementation
- `Master.create_master_record` — model method handling transactional creation
- `Master.create_associated_records` — model method creating association records
