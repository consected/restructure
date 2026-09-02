# `notify`
## Send a Notification

Send a notification (email, SMS, etc.) using a configured message template when this trigger fires.

### When substitutions are made

The trigger runs in two stages, and it matters which values are resolved in each.

When the trigger fires, the recipients, `subject:`, the string values of
`extra_substitutions:` and `content_template_text:` are substituted against the record that
fired it, while that record is still in memory. A message notification record is then
created holding those resolved values, and a job is queued to send it.

The message body is not rendered until that job runs. It re-loads the record from the
database by ID and substitutes the layout together with the content in a single pass, so
those tags resolve against the saved record and its master record.

This gives the two ways of supplying content different behaviour:

| | `content_template_text:` | Named `content_template:` |
| --- | --- | --- |
| Substituted when the trigger fires | Yes, against the in-memory record | No — only the template name is stored |
| Substituted when the message is sent | Yes, with the layout | Yes, with the layout |
| A tag that can not be resolved | Silently replaced with a blank at the first stage, so it never reaches the second | Raises an error when the message is sent |

Values held on the record but not yet saved are therefore visible to
`content_template_text:` and not to a named `content_template:`. See
[record scoping](scoping.md) for what each stage can reach.

```yaml
!defs(save_triggers_notify_options_defs.yaml)
```

### Pattern 1: Email notification to a role

```yaml
!defs(save_triggers_notify_pattern_1_email_defs.yaml)
```

### Pattern 2: SMS notification to phone numbers

```yaml
!defs(save_triggers_notify_pattern_2_sms_defs.yaml)
```

### Pattern 3: Recipients via phone_records association

```yaml
!defs(save_triggers_notify_pattern_3_phone_records_defs.yaml)
```

### Pattern 4: Calendar invite (email only)

```yaml
!defs(save_triggers_notify_pattern_4_calendar_invite_defs.yaml)
```

### Pattern 5: File attachments (email only)

```yaml
!defs(save_triggers_notify_pattern_5_attachments_defs.yaml)
```


## Inline Image Handling

Email bodies can contain `<img src="data:image/...;base64,...">` tags. When such tags are
present, they are automatically converted to proper MIME inline attachments (CID references)
so that email clients such as Gmail and Outlook display them correctly.

This behaviour is controlled by the `ProcessInlineDataUriImages` setting (default: enabled).
Set the environment variable `FPHS_PROCESS_INLINE_DATA_URI_IMAGES=false` to disable it.
