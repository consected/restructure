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

## Response headers

When `local_data` is configured, the response headers are stored in
`save_trigger_results` under `<local_data>_http_response_headers`. The hash
contains lowercase, hyphenated header-name strings and corresponding
underscored keys. For example, a response header named
`X-ReStructure-Error` is available as `x-restructure-error` or
`x_restructure_error`:

```text
{{save_trigger_results.remote_response_http_response_headers.x_restructure_error}}
```

The complete header hash can also be rendered with `::yaml`. Headers that appear multiple times are exposed as one comma-separated string, so individual values
must be accessed after splitting the string. If two different header names normalize to the
same underscored key, the later value overwrites the earlier value for that
symbol key; use the lowercase hyphenated string keys when those names must be
distinguished.

## Failure response data

When a request is rejected, its response metadata is stored before the failure is
raised. An `on_failure` hook can access the response body under `<local_data>`,
the status under `<local_data>_http_response_code`, the headers under
`<local_data>_http_response_headers`, and the resolved request under
`<local_data>_submitted_request`.

This applies to rejected non-2xx responses that are not listed in
`allow_response_codes`, malformed JSON or XML returned with a successful 2xx
status, and empty successful 2xx responses when `allow_empty_result` is false.
For malformed or empty responses, the raw response body is retained under
`<local_data>` while the original parsing or empty-content failure is preserved.
For an explicitly allowed non-2xx response, an unparsable body is instead
treated as successful raw response content, as documented by `allow_response_codes`.
