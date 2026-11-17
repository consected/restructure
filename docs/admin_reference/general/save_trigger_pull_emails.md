# `pull_emails`
## Read MIME Emails and Run Nested Triggers

Read MIME email content from S3, filesystem, or IMAP sources, then execute `on_email` trigger tasks for each email. Optional `on_email_complete` and `on_email_failure` hooks run per-email after processing.

```yaml
!defs(save_triggers_pull_emails_options_defs.yaml)
```

### Pattern 1: S3 source

`bucket` is required. `prefix` optionally restricts which keys are listed. `since_modified` is
optional and only returns objects whose `last_modified` is strictly newer than the supplied
timestamp (ISO8601 string or anything `Time.parse` understands).

```yaml
!defs(save_triggers_pull_emails_pattern_1_s3_defs.yaml)
```

### Pattern 2: Filesystem source

`path` (a directory of `*.eml` files) is required. `since_modified` is optional and only returns
files whose mtime is strictly newer than the supplied time.

```yaml
!defs(save_triggers_pull_emails_pattern_2_filesystem_defs.yaml)
```

### Pattern 3: IMAP source

`host`, `username` and `password` are required (use a `{{variables.*}}` secret reference for
`password`). `port` defaults to 993 (ssl) or 143; `ssl` defaults to false; `mailbox` defaults to
`INBOX`; `search` defaults to `['ALL']`. `since_uid` is optional and only returns messages whose
UID is strictly greater than the supplied value - combined with `search` (AND) when both are set.

```yaml
!defs(save_triggers_pull_emails_pattern_3_imap_defs.yaml)
```
