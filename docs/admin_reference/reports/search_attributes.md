# SQL Search Attributes

A report's SQL incorporates search attributes from the search criteria form simply by adding
`:<attribute_name>` to the SQL. Field types are handled directly, so there is no need to surround
with quotes for example.

A common approach is to check if the search criteria has been entered, and to use it in the where
clause of the SQL:

```
select * 
from a_table 
where 
  :name is null
  or name = :name;
```

## Current User Substitutions

Current user information may also be added to the SQL. Add one or more of the following:

- `:current_user` - current user id
- `:current_user_preference` - current user user_preference.id
- `:current_user_roles` - array of active role names in this app, added as `array['role1',...]`

## Double Curly Substitutions

The SQL is also parsed to add `{\{tag_name}\}` substitutions.

## Config Libraries

Add the text from a library to the SQL, by adding:

`-- @library <category> <name>`


