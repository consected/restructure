# `notify`
## Send a Notification

Send a notification (email, SMS, etc.) using a configured message template when this trigger fires.

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
