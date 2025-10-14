# URL Search Attributes

In order to generate a URL to call a report from a link (for example in a form caption), the URL search attributes need to be be added to the URL. Each attribute that would appear on a regular report criteria form and be passed to the SQL as [SQL search attributes](search_attributes.md) can be passed.

Typically, this is handled by adding:

`/reports/category__show_name?search_attrs[attribute_name_1]=value_1&search_attrs[attribute_name_2]=value_2&...`

## Plain search attributes

Plain search attributes can be used instead if the [Options](detailed_options.md) includes:

```yaml
view_options:
  use_plain_attribute_names: true
```

This would allow either the default format to be used, or if no `search_attrs[]` attributes are specified then the URL can simply be:

`/reports/category__show_name?attribute_name_1=value_1&attribute_name_2=value_2&...`

## Additional attributes

Add the following attributes and values for specific operations:

- `force_run=true` - automatically run the report
- `commit=count` - return only a count (as if the *Count* button had been clicked)
- `commit=search` - return a master result list (as if the *Search* button had been clicked)
- `format=<format>` - returns results as specified format (`json`, `csv`, `text`)
- `embed=true` - used to get just the results section of the report as HTML
- `search_attrs[no_run]=true` - typically used with embedded reports
- `search_attrs=_use_defaults_`- ensures a report can be run if there are no search attributes specified and just the default values are to be used
