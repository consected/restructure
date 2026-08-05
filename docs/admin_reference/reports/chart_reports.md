# Chart Reports

Reports can display results as interactive charts using [Chart.js](https://www.chartjs.org/). This allows SQL query results to be visualised as line, bar, pie, doughnut, radar and other chart types.

## Enabling Chart View

Set `view_as: chart` in the report's `view_options` to render results as a chart instead of the default table:

```yaml
view_options:
  view_as: chart
```

The report must also be configured with a `component:` section that defines the chart type and Chart.js options.

## SQL Structure

The SQL query must return columns that map to chart data:

- **One column** acts as the **label** for each data point (the x-axis or legend label). Specify which column to use with `label_with_column`.
- **Remaining columns** each become a **dataset** (a data series) in the chart.

**Example — two datasets named "screenings" and "enrollments" labelled by "week":**

```sql
SELECT
  week_start    AS "week",
  screenings    AS "screenings",
  enrollments   AS "enrollments"
FROM weekly_summary
ORDER BY week_start;
```

## Component Options

The `component:` section of a report's options holds the Chart.js configuration. All keys inside `component: options:` are mapped directly onto Chart.js constructor arguments.

```yaml
component:
  options:
    type: <chart_type>
    width: <number>
    height: <number>
    label_with_column: <column_name>
    dataset_options:
      - <per-dataset Chart.js options>
    data_labels: []
    options:
      <Chart.js options object>
```

### Top-Level Keys

| Key | Default | Description |
|-----|---------|-------------|
| `type` | `''` | Chart.js chart type (see [Chart Types](#chart-types)) |
| `width` | `100` | Canvas width (pixels or `'100%'` for responsive) |
| `height` | `100` | Canvas height (pixels or percentage string for responsive) |
| `label_with_column` | `'label'` | SQL column name whose values become the chart labels |
| `dataset_options` | `[]` | Array of Chart.js dataset option objects, one per dataset column |
| `data_labels` | `[]` | Seed labels; SQL-derived labels are appended to this array at render time |
| `options` | `{}` | Chart.js [configuration options](https://www.chartjs.org/docs/latest/configuration/) object |

### Chart Types

Any Chart.js chart type is supported:

| Type | Description |
|------|-------------|
| `line` | Line chart — good for time-series trends |
| `bar` | Vertical bar chart |
| `horizontalBar` | Horizontal bar chart |
| `pie` | Pie chart |
| `doughnut` | Doughnut chart |
| `radar` | Radar/spider chart |
| `polarArea` | Polar area chart |
| `scatter` | Scatter plot |
| `bubble` | Bubble chart |
| `sankey` | Sankey flow diagram — see [Sankey Charts](#sankey-charts) |

## Sankey Charts

Sankey diagrams visualise flow quantities between nodes. They require the [chartjs-chart-sankey](https://github.com/kurkle/chartjs-chart-sankey) plugin, which is bundled with the application.

### SQL Structure for Sankey

Unlike standard charts (which use a label column plus one or more value columns), Sankey charts require **three columns** per row:

| Column | Default name | Description |
|--------|-------------|-------------|
| Source node | `from` | The name of the origin node |
| Target node | `to` | The name of the destination node |
| Flow magnitude | `flow` | A positive number representing the quantity flowing |

**Example:**

```sql
SELECT
  stage_from  AS "from",
  stage_to    AS "to",
  participant_count AS "flow"
FROM cohort_transitions
ORDER BY participant_count DESC;
```

### Custom Column Names

If your SQL uses different column names, map them with `sankey_columns`:

```yaml
component:
  options:
    type: sankey
    sankey_columns:
      from_column: source
      to_column: destination
      flow_column: value
```

### Sankey Dataset Options

The first entry in `dataset_options` applies to the single Sankey dataset. Supported keys:

| Key | Description |
|-----|-------------|
| `label` | Dataset label (shown in the tooltip header) |
| `colorMode` | Colour blending mode: `'gradient'` (default), `'from'`, or `'to'` |
| `alpha` | Opacity of the flow ribbons (0–1, default `0.5`) |
| `colorFrom` | Colour of the source end of each ribbon (CSS string or callback) |
| `colorTo` | Colour of the target end of each ribbon (CSS string or callback) |
| `size` | `'max'` (default) or `'min'` — controls overlap strategy |

---

## Dataset Options

Each entry in `dataset_options` applies Chart.js [dataset configuration](https://www.chartjs.org/docs/latest/configuration/elements.html) to the corresponding data column. The array index matches the column order (excluding the label column).

Common dataset options:

| Key | Description |
|-----|-------------|
| `borderColor` | Line/bar border colour (CSS colour string) |
| `backgroundColor` | Fill colour (CSS colour string or `transparent`) |
| `borderWidth` | Border width in pixels |
| `lineTension` | Curve tension for line charts (`0` = straight lines) |
| `cubicInterpolationMode` | `'monotone'` for smooth non-overshoot curves |
| `fill` | Whether to fill the area under a line (`false` to disable) |
| `pointRadius` | Size of data point markers |

## Chart.js Options

The nested `options:` key passes through to the [Chart.js options object](https://www.chartjs.org/docs/latest/configuration/). Commonly used properties:

```yaml
options:
  responsive: true
  maintainAspectRatio: false
  scales:
    yAxes:
      - ticks:
          min: 0
        stacked: false
    xAxes:
      - type: time
        display: true
        time:
          unit: week
          displayFormats:
            day: MMM D, YY
  legend:
    display: true
    position: bottom
  title:
    display: true
    text: My Chart Title
```

### Responsive Sizing

- When `width` or `height` are provided as numbers, the chart renders at a fixed pixel size and `responsive` defaults to `false`.
- For fluid layouts, set `width: '100%'` and `responsive: true` (done automatically when a chart is embedded inside a page layout panel).
- `maintainAspectRatio: false` allows the chart to fill its container without preserving the aspect ratio.

---

## Examples

### Example 1: Simple Bar Chart

A report showing counts by category.

**SQL:**

```sql
SELECT
  category  AS "category",
  count(*)  AS "count"
FROM my_table
GROUP BY category
ORDER BY category;
```

**Options:**

```yaml
view_options:
  view_as: chart

component:
  options:
    type: bar
    width: 600
    height: 300
    label_with_column: category
    dataset_options:
      - backgroundColor: 'rgba(54, 162, 235, 0.8)'
        borderColor: 'rgba(54, 162, 235, 1)'
        borderWidth: 1
    options:
      responsive: false
      scales:
        yAxes:
          - ticks:
              min: 0
              beginAtZero: true
```

---

### Example 2: Multi-Dataset Line Chart (Time Series)

A report tracking two running totals over time.

**SQL:**

```sql
SELECT
  created_at    AS "date",
  sum(screenings) OVER (ORDER BY created_at)  AS "screenings",
  sum(enrollments) OVER (ORDER BY created_at) AS "enrollments"
FROM weekly_stats
ORDER BY created_at;
```

**Options:**

```yaml
view_options:
  view_as: chart

component:
  options:
    type: line
    height: 250
    width: 800
    label_with_column: date
    dataset_options:
      - borderColor: '#c00'
        borderWidth: 3
        backgroundColor: transparent
        lineTension: 0.1
        cubicInterpolationMode: monotone
      - borderColor: '#0c0'
        borderWidth: 3
        backgroundColor: transparent
        lineTension: 0.1
        cubicInterpolationMode: monotone
    options:
      responsive: true
      scales:
        yAxes:
          - ticks:
              min: 0
            stacked: false
        xAxes:
          - type: time
            display: true
            time:
              unit: week
              displayFormats:
                day: MMM D, YY
```

---

### Example 3: Pie Chart

A report showing proportions across categories.

**SQL:**

```sql
SELECT
  status        AS "status",
  count(*)      AS "participants"
FROM participants
GROUP BY status;
```

**Options:**

```yaml
view_options:
  view_as: chart

component:
  options:
    type: pie
    width: 400
    height: 400
    label_with_column: status
    dataset_options:
      - backgroundColor:
          - '#FF6384'
          - '#36A2EB'
          - '#FFCE56'
          - '#4BC0C0'
          - '#9966FF'
    options:
      responsive: false
      legend:
        display: true
        position: right
```

---

### Example 4: Doughnut Chart

Similar to a pie chart, with a hollow centre. Replace `type: pie` with `type: doughnut`.

```yaml
component:
  options:
    type: doughnut
    width: 400
    height: 400
    label_with_column: status
    dataset_options:
      - backgroundColor:
          - '#FF6384'
          - '#36A2EB'
          - '#FFCE56'
    options:
      responsive: false
```

---

### Example 5: Embedded Chart in a Page Layout

When a chart report is embedded in a page layout panel, the dimensions are automatically set to fill the panel:

- `height` is set to `'30%'`
- `width` is set to `'100%'`
- `maintainAspectRatio: false` is applied
- `responsive: true` is applied

You can override these defaults in the `component: options:` configuration. A full-page report uses its explicit `width` and `height` values.

In the example below, we also enable a value number to appear on each bar (the `component.options.options.plugins.datalabels` entry)
and remove the legend (the `component.options.options.plugins.legend` entry).

For an embedded chart, specify a meaningful height via the `options` block:

```yaml
view_options:
  view_as: chart

component:
  options:
    type: bar
    label_with_column: label
    options:
      maintainAspectRatio: false
      responsive: true
      plugins:
        legend:
          display: false
        datalabels:
          color: white
          font:
            weight: bold
          textStrokeWidth: 3
          textStrokeColor: '#4472c4'
      
```

---

### Example 6: Sankey Flow Diagram

A report showing participant transitions between study stages.

**SQL:**

```sql
SELECT
  stage_from        AS "from",
  stage_to          AS "to",
  count(*)          AS "flow"
FROM participant_transitions
GROUP BY stage_from, stage_to
ORDER BY stage_from, stage_to;
```

**Options:**

```yaml
view_options:
  view_as: chart

component:
  options:
    type: sankey
    width: 800
    height: 400
    dataset_options:
      - label: Participant flow
        colorMode: gradient
        alpha: 0.6
    options:
      responsive: false
```

**With custom column names** (when SQL columns differ from the defaults):

```yaml
component:
  options:
    type: sankey
    width: 800
    height: 400
    sankey_columns:
      from_column: source_stage
      to_column: destination_stage
      flow_column: participant_count
    dataset_options:
      - label: Participant flow
        colorMode: gradient
```

---

## Auto-Run Charts

Charts are often configured to run automatically without requiring user input. Set `auto: true` on the report and optionally `hide_criteria_panel: true` to suppress the search form:

```yaml
view_options:
  view_as: chart
  hide_criteria_panel: true
```

This is useful for dashboard-style charts embedded in page layouts.

## Hiding the Search Criteria Panel

For charts that auto-run on page load, the criteria panel can be hidden to present a clean visualisation:

```yaml
view_options:
  view_as: chart
  hide_criteria_panel: true
  hide_export_buttons: true
```

## Access Control

Chart reports are subject to the same access control as other reports. Grant users access via:

- **Role-based**: Assign a role with `resource_type: report` and `resource_name: <report_name>`.
- **All reports**: Grant `resource_name: _all_reports_` for broad access.

See [User Access Controls](../user_access_controls/) for details.
