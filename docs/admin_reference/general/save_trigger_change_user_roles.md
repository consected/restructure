# `change_user_roles`
## Add or Remove User Roles

Add or remove roles for the current user (or a specified user) when this trigger fires.

```yaml
!defs(save_triggers_change_user_roles_options_defs.yaml)
```

### Pattern 1: Add/remove literal role names for the current user

```yaml
!defs(save_triggers_change_user_roles_pattern_1_basic_defs.yaml)
```

### Pattern 2: Role scoped to a specific app_type

```yaml
!defs(save_triggers_change_user_roles_pattern_2_app_type_defs.yaml)
```

### Pattern 3: Change the roles of a different user

`for_user` resolves which user the role change applies to - here, the user who originally
created the referenced record.

```yaml
!defs(save_triggers_change_user_roles_pattern_3_for_user_defs.yaml)
```

