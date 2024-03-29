_fpa.tag_formatter = class {

  constructor(tag_name, data) {
    this.tag_name = tag_name;
    this.data = data;
  }

  static format_all(got, formatters, tag_name, data) {
    var res = got;

    if (res == null && formatters[0] != 'ignore_missing') {
      return;
    }

    // Automatically titleize names
    if (formatters.length == 0 && (tag_name == 'name' || tag_name.match(/_name$/))) {
      formatters = ['titleize'];
    }

    for (const [key, op] of Object.entries(formatters)) {
      res = this.format_with(op, res, got, tag_name, data)
    }

    return res;

  }

  static format_with(operation, res, orig_val, tag_name, data) {
    this.tag_formatter = new _fpa.tag_formatter(tag_name, data);
    return this.tag_formatter.process(operation, res, orig_val);
  }

  get ValidOps() {
    return [
      "capitalize",
      "titleize",
      "uppercase",
      "lowercase",
      "underscore",
      "hyphenate",
      "id_hyphenate",
      "id_underscore",
      "initial",
      "first",
      "age",
      "date",
      "date_time",
      "date_time_with_zone",
      "date_time_show_zone",
      "time",
      "time_with_zone",
      "time_show_zone",
      "time_sec",
      "dicom_datetime",
      "dicom_date",
      "join_with_space",
      "join_with_comma",
      "join_with_semicolon",
      "join_with_pipe",
      "join_with_dot",
      "join_with_at",
      "join_with_slash",
      "join_with_newline",
      "join_with_2newlines",
      "compact",
      "sort",
      "sort_reverse",
      "uniq",
      "markdown_list",
      "html_list",
      "plaintext",
      "strip",
      "split_lines",
      "split_comma",
      "split_csv",
      "split_semicolon",
      "split_pipe",
      "split_dot",
      "split_at",
      "split_slash",
      "markup",
      "yaml",
      "json",
      "ignore_missing",
      "last",
      "general_selection_label"
    ]
  }

  process(operation, res, orig_val) {
    const numop = parseInt(operation);

    if (this.ValidOps.indexOf(operation) >= 0) {
      return this[operation](res, orig_val);
    }
    else if (Array.isArray(res) && numop == operation) {
      return res[numop];
    }
    else if (numop != 0) {
      return res.slice(0, numop + 1);
    }
    else {
      return res;
    }
  }


  capitalize(res, _orig_val) {
    return res.capitalize();
  }

  titleize(res, _orig_val) {
    return res.titleize();
  }

  uppercase(res, _orig_val) {
    return res.toUpperCase()
  }

  lowercase(res, _orig_val) {
    return res.toLowerCase()
  }

  underscore(res, _orig_val) {
    return res.underscore();
  }

  hyphenate(res, _orig_val) {
    return res.hyphenate();
  }

  id_hyphenate(res, _orig_val) {
    return res.id_hyphenate();
  }

  id_underscore(res, _orig_val) {
    return res.id_underscore();
  }

  initial(res, _orig_val) {
    return (res[0] || '').toUpperCase();
  }

  first(res, _orig_val) {
    return res[0];
  }

  age(res, orig_val) {
    res = new Date(orig_val);

    if (res.getFullYear) {
      var today = new Date();
      var age = today.getFullYear() - res.getFullYear();
      var m = today.getMonth() - res.getMonth();
      if (m < 0 || (m === 0 && today.getDate() < res.getDate())) {
        age--;
      }
      res = age;
    }
    return res;
  }

  date(_res, orig_val) {
    let dtf = UserPreferences.date_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return orig_val;
  }

  date_time(_res, orig_val) {
    let dtf = UserPreferences.date_time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return orig_val;
  }

  // Date and time only including hours:minutes and timezone of displayed time
  // TODO: this does not return the timezone
  date_time_with_zone(_res, orig_val) {
    let dtf = UserPreferences.date_time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }

    return orig_val;
  }

  // Date and time only including hours:minutes and timezone of displayed time
  // TODO: this does not return the timezone
  date_time_show_zone(_res, orig_val) {
    let dtf = UserPreferences.date_time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }

    return orig_val;
  }

  // Time only including hours: minutes
  time(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: UserPreferences.timezone() }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return time;
  }

  // Time only including hours: minutes
  time_ignore_zone(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: 'UTC' }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return time;
  }

  // Time only including hours:minutes and timezone of displayed time
  // TODO: this does not return the timezone
  time_with_zone(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: UserPreferences.timezone() }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return time;
  }

  // Time only including hours:minutes and timezone of displayed time
  // TODO: this does not return the timezone
  time_show_zone(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: UserPreferences.timezone() }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return time;
  }

  // Time for hours: minutes: seconds
  time_sec(_res, orig_val) {
    let dtf = UserPreferences.time_format(true);
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: UserPreferences.timezone() }) : _fpa.utils.DateTime.now();
      res = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return orig_val;

  }

  dicom_datetime(_res, orig_val) {
    if (typeof orig_val == 'date') {
      orig_val = orig_val.toISOString();
    }
    orig_val = orig_val.split('.')[0].replace(/[\:\-T]/g, '');
    return orig_val;
  }

  dicom_date(_res, orig_val) {

    let dtf = '%Y%m%d';
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: UserPreferences.timezone() }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return orig_val;
  }

  join_with_space(res, _orig_val) {
    if (Array.isArray(res))
      return res.join(' ');
  }

  join_with_comma(res, _orig_val) {
    if (Array.isArray(res))
      return res.join(', ');
  }

  join_with_semicolon(res, _orig_val) {
    if (Array.isArray(res))
      return res.join('; ');
  }

  join_with_pipe(res, _orig_val) {
    if (Array.isArray(res))
      return res.join('|');
  }

  join_with_dot(res, _orig_val) {
    if (Array.isArray(res))
      return res.join('.');
  }

  join_with_at(res, _orig_val) {
    if (Array.isArray(res))
      return res.join('@');
  }

  join_with_slash(res, _orig_val) {
    if (Array.isArray(res))
      return res.join('/');
  }

  join_with_newline(res, _orig_val) {
    if (Array.isArray(res))
      return res.join('\n');
  }

  join_with_2newlines(res, _orig_val) {
    if (Array.isArray(res))
      return res.join('\n');
  }

  compact(res, _orig_val) {
    if (Array.isArray(res))
      res.filter(item => (item));
  }

  sort(res, _orig_val) {
    if (Array.isArray(res))

      return res.sort();

  }

  sort_reverse(res, _orig_val) {

    if (Array.isArray(res))
      return res.sort().reverse();
  }

  uniq(res, _orig_val) {


    if (!Array.isArray(res)) return res;

    var newres = [];
    var done = [];
    for (var i in res) {
      var item = res[i];
      var strItem = item.toString();
      if (done.indexOf(strItem) < 0) {
        newres.push(item);
        done.push(strItem);
      }
    }
  }

  markdown_list(res, _orig_val) {

    if (Array.isArray(res))
      return `  - ${res.join("\n  - ")}`
  }

  html_list(res, _orig_val) {
    if (Array.isArray(res))
      return `<ul><li>${res.join("</li>\n  <li>")}</li></ul>`

  }

  plaintext(res, _orig_val) {
    res = $(`<div>${res}</div>`).text()
    return res.replaceAll("\n", '<br>')
  }

  strip(res, _orig_val) {
    return res.trim()
  }

  split_lines(res, _orig_val) {
    return res.split("\n")
  }

  split_comma(res, _orig_val) {
    return res.split(',')
  }

  split_csv(res, _orig_val) {
    // Imperfect implementation. Really should properly parse CSV files
    return res.split(',')
  }

  split_semicolon(res, _orig_val) {
    return res.split(';')
  }

  split_pipe(res, _orig_val) {
    return res.split('|')
  }

  split_dot(res, _orig_val) {
    return res.split('.')
  }

  split_at(res, _orig_val) {
    return res.split('@')
  }

  split_slash(res, _orig_val) {
    return res.split('/')
  }

  markup(res, _orig_val) {
    return megamark(res);
  }

  yaml(res, _orig_val) {
    return jsyaml.dump(res);
  }

  json(res, _orig_val) {
    return JSON.stringify(res, null, 2)
  }

  ignore_missing(res, _orig_val) {
    return res || ''
  }

  last(res, _orig_val) {
    return res[res.length - 1];
  }

  no_html_tag(res, _orig_val) {
    return res;
  }

  general_selection_label(res, _orig_val) {
    console.log('data._general_selections')
    let data = this.data, tag_name = this.tag_name;

    if (!data || !data._general_selections) return res;

    return data._general_selections[tag_name] && data._general_selections[tag_name][res] && data._general_selections[tag_name][res].name || res
  }

}