# Storing Encrypted Secrets

Encrypted secrets may be stored in the database and used through substitutions. This is the preferred way to store API secrets used within `pull_external_data` triggers, and may be useful for other encrypted storage requirements.

## Step-by-step example

Create a new dynamic model with:

- table name: `api_secrets`
- primary key name: `id`
- field list: `name category secret disabled`

Add options:

```yaml
_db_columns:
  secret:
    type: string
    encrypted: true

default:
  field_options:
    secret:
      no_downcase: true
      view_original_case: true
```

Enter a secret by searching the table and adding an entry. For this example, use name `marketo_client_secret` and category `marketo`.

In a dynamic model or config library, use the new secret by setting a variable, for example:

```yaml
    set_variables:
      - name: marketo_client_secret
        value:
          no_masters: {}
          dynamic_model__api_secrets:
            disabled:
              - null
              - false
            category: marketo
            name: marketo_client_secret
            secret: return_value
```

Then use the variable wherever needed with `{{variables.marketo_client_secret}}`
