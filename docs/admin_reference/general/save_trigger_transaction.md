# `transaction`
## Wrap Triggers in a Transaction

Wrap a set of inner trigger tasks inside a single database transaction. If any inner trigger fails the entire transaction is rolled back, including the record's own save - useful when multiple related records must be created atomically.

```yaml
!defs(save_triggers_transaction_options_defs.yaml)
```

### Pattern 1: Create related records atomically

```yaml
!defs(save_triggers_transaction_pattern_1_basic_defs.yaml)
```

