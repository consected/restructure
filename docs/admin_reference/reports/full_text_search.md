# Full Text Search

## Summary

Reports can perform full text search against indexed `tsvector` columns produced by save triggers or filestore pipeline jobs.

Use PostgreSQL search operators and functions:

- `@@` to test if a vector matches a query
- `to_tsquery(config, text)` for explicit query syntax
- `plainto_tsquery(config, text)` for plain user-entered terms

## Typical Pattern

1. Join report source data to the table that stores the `tsvector` index.
2. Add a report search attribute (for example `search_text`).
3. Apply a conditional where clause using `@@` when the search input is present.

```sql
select dm.id,
       dm.title,
       dm.updated_at
from dynamic_test.my_items dm
join dynamic_test.item_search_indexes idx
  on idx.source_record_id = dm.id
where :search_text is null
   or idx.search_vector @@ plainto_tsquery('english', :search_text)
order by dm.updated_at desc;
```

## When to Use `to_tsquery` vs `plainto_tsquery`

- Use `plainto_tsquery` for free-text user input.
- Use `to_tsquery` when you need operators such as `&`, `|`, or `!`.

Example using `to_tsquery`:

```sql
where idx.search_vector @@ to_tsquery('english', 'heart & disease')
```

## Performance Guidance

- Ensure indexed columns use a `gin` index.
- Keep indexed text focused to avoid bloated vectors.
- Prefer filtering by app context and date ranges before full-text predicates where possible.

See also: [General Concepts: Full Text Search](../general/full_text_search.md)
