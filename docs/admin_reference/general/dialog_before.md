# `dialog_before`

## Confirmation Dialogs Before Actions

Display a confirmation dialog (driven by a message template) in an edit form, positioned before the specified form field, all fields, or the submit button.

The generated message is shown directly in the form when its length is 100 characters or fewer after HTML tags are stripped, or when the label is blank. In these cases, no dialog button is shown. Only when the message is longer than 100 characters after stripping HTML tags and the label is nonblank is a preview shown with a button bearing the configured label; clicking the button reveals the full message. Therefore, a message of exactly 100 characters does not show a dialog button.

```yaml
!defs(extra_options_dialog_before_defs.yaml)
```

### Pattern 1: Simple string (template name only)

```yaml
!defs(extra_options_dialog_before_pattern_1_simple_defs.yaml)
```

### Pattern 2: Hash with label

```yaml
!defs(extra_options_dialog_before_pattern_2_hash_defs.yaml)
```
