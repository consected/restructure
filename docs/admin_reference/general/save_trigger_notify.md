# `notify`
## Send a Notification

Send a notification (email, SMS, etc.) using a configured message template when this trigger fires.

```yaml
!defs(save_triggers_notify_options_defs.yaml)
```

## Inline Image Handling

Email bodies can contain `<img src="data:image/...;base64,...">` tags. When such tags are
present, they are automatically converted to proper MIME inline attachments (CID references)
so that email clients such as Gmail and Outlook display them correctly.

This behaviour is controlled by the `ProcessInlineDataUriImages` setting (default: enabled).
Set the environment variable `FPHS_PROCESS_INLINE_DATA_URI_IMAGES=false` to disable it.
