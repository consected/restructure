# `transaction`
## Wrap Triggers in a Transaction

Wrap a set of inner trigger tasks inside a single database transaction. If any inner trigger fails the entire transaction is rolled back.

```yaml
!defs(save_triggers_transaction_options_defs.yaml)
```
