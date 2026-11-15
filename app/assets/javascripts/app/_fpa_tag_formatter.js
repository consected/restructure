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
      "time_ignore_zone",
      "time_with_zone",
      "time_show_zone",
      "time_sec",
      "dicom_datetime",
      "dicom_date",
      "redcap_date",
      "iso8601_datetime",
      "join_with_space",
      "join_with_comma",
      "join_with_csv",
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
      "split_space",
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
      "no_html_tag",
      "general_selection_label",
      "parse_json",
      "parse_yaml"
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
    return _fpa.utils.capitalize(res, true);
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
      if (d.isValid) {
        orig_val = d.toFormat(dtf).toLowerCase();
      }
      else {
        console.log(`Date is invalid: ${orig_val}`)
      }
    }
    else {
      console.log('User preferences don\'t include date format');
    }
    return orig_val;
  }


  // Show the date and time as it was set(as if no timezone was specified)
  // without adjusting to the user's timezone.  
  date_time(_res, orig_val) {
    let dtf = UserPreferences.date_time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.setZone('UTC').toFormat(dtf).toLowerCase() : orig_val;
    }
    return orig_val;
  }

  // Forces the stored timezone to the user's timezone preference, without changing the date.
  // A stored date time intended to not have a timezone
  // will be returned as a new date time based on the user's timezone.
  date_time_with_zone(_res, orig_val) {
    let dtf = UserPreferences.date_time_format();
    let dtz = UserPreferences.timezone();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: dtz }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.setZone(dtz).toFormat(dtf).toLowerCase() : orig_val;
    }

    return orig_val;
  }

  // Date and time only including hours:minutes and timezone of displayed time
  date_time_show_zone(_res, orig_val) {
    let dtf = UserPreferences.date_time_format();
    let dtz = UserPreferences.timezone();
    let dtzh = UserPreferences.timezone_human();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: dtz }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf).toLowerCase() : orig_val;
      orig_val = `${orig_val} ${dtzh}`;
    }

    return orig_val;
  }

  // Time only including hours: minutes
  time(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    let dtz = UserPreferences.timezone();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: dtz }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf).toLowerCase() : orig_val;
    }
    return orig_val;
  }

  // Time only including hours: minutes
  time_ignore_zone(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: 'UTC' }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf).toLowerCase() : orig_val;
    }
    return orig_val;
  }

  // Time only including hours:minutes and timezone of displayed time
  // TODO: this does not return the timezone
  time_with_zone(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    let dtz = UserPreferences.timezone();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: dtz }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf).toLowerCase() : orig_val;
    }
    return orig_val;
  }

  // Time only including hours:minutes and timezone of displayed time
  // TODO: this does not return the timezone
  time_show_zone(_res, orig_val) {
    let dtf = UserPreferences.time_format();
    let dtz = UserPreferences.timezone();
    let dtzh = UserPreferences.timezone_human();
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: dtz }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf).toLowerCase() : orig_val;
      orig_val = `${orig_val} ${dtzh}`;
    }
    return orig_val;
  }

  // Time for hours: minutes: seconds
  time_sec(_res, orig_val) {
    let dtf = UserPreferences.time_format(true);
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: UserPreferences.timezone() }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf).toLowerCase() : orig_val;
    }
    return orig_val;

  }

  dicom_datetime(_res, orig_val) {
    let dtf = 'yyyyMMddHHmmss+0000';
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: 'UTC' }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return orig_val;
  }

  dicom_date(_res, orig_val) {

    let dtf = 'yyyyMMdd';
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val, { zone: 'UTC' }) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return orig_val;
  }

  redcap_date(_res, orig_val) {

    let dtf = 'yyyy-MM-dd';
    if (dtf) {
      let d = (orig_val) ? _fpa.utils.DateTime.fromISO(orig_val) : _fpa.utils.DateTime.now();
      orig_val = (d.isValid) ? d.toFormat(dtf) : orig_val;
    }
    return orig_val;
  }

  iso8601_datetime(_res, orig_val) {
    if (typeof orig_val == 'date') {
      orig_val = orig_val.toISOString();
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

  join_with_csv(res, _orig_val) {
    if (!Array.isArray(res)) return;

    // Convert array to CSV format with proper escaping
    return res.map(item => {
      const str = String(item == null ? '' : item);
      // Quote fields that contain comma, quote, or newline
      if (str.includes(',') || str.includes('"') || str.includes('\n')) {
        return '"' + str.replace(/"/g, '""') + '"';
      }
      return str;
    }).join(',');
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
      return res.join('\n\n');
  }

  compact(res, _orig_val) {
    if (Array.isArray(res))
      return res.filter(item => (item));
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
    return newres;
  }

  markdown_list(res, _orig_val) {

    if (Array.isArray(res))
      return `- ${res.join("\n- ")}`
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

  split_space(res, _orig_val) {
    return res.split(" ")
  }

  split_lines(res, _orig_val) {
    return res.split("\n")
  }

  split_comma(res, _orig_val) {
    return res.split(',')
  }

  split_csv(res, _orig_val) {
    // Parse CSV with proper handling of quoted values
    const result = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < res.length; i++) {
      const char = res[i];
      const nextChar = res[i + 1];

      if (char === '"') {
        if (inQuotes && nextChar === '"') {
          current += '"';
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        result.push(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.push(current);
    return result;
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

  parse_json(res, _orig_val) {
    try {
      return JSON.parse(res);
    } catch (e) {
      return null;
    }
  }

  parse_yaml(res, _orig_val) {
    try {
      return jsyaml.load(res);
    } catch (e) {
      return null;
    }
  }

}
