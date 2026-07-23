# `pull_emails`
## Read MIME Emails and Run Nested Triggers

Read MIME email content from S3, filesystem, or IMAP sources, then execute `on_email` trigger tasks for each email. Optional `on_email_complete` and `on_email_failure` hooks run per-email after processing.

```yaml
!defs(save_triggers_pull_emails_options_defs.yaml)
```