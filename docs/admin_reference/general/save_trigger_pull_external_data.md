# `pull_external_data`
## Pull Data from an External Source

Request data from an external API or data source and store the results, optionally making them available to subsequent triggers via `save_trigger_results`.

```yaml
!defs(save_triggers_pull_external_data_options_defs.yaml)
```

### Pattern 1: GET request

Use `from:` for get requests.

```yaml
!defs(save_triggers_pull_external_data_pattern_1_get_defs.yaml)
```

### Pattern 2: POST request with headers and a body

Use `to:` for post requests - `headers:` only applies to `to:`.

```yaml
!defs(save_triggers_pull_external_data_pattern_2_post_defs.yaml)
```

