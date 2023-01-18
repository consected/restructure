(function (root, factory) {
  if (typeof exports === 'object') {
    module.exports = factory(require('handlebars'));
  } else if (typeof define === 'function' && define.amd) {
    define(['handlebars'], factory);
  } else {
    root.HandlebarsHelpersRegistry = factory(root.Handlebars);
  }
}(this, function (Handlebars) {

  var isArray = function (value) {
    return Object.prototype.toString.call(value) === '[object Array]';
  };

  var ExpressionRegistry = function () {
    this.expressions = [];
  };

  ExpressionRegistry.prototype.add = function (operator, method) {
    this.expressions[operator] = method;
  };

  ExpressionRegistry.prototype.call = function (operator, left, right) {
    if (!this.expressions.hasOwnProperty(operator)) {
      throw new Error('Unknown operator "' + operator + '"');
    }

    return this.expressions[operator](left, right);
  };

  var eR = new ExpressionRegistry;
  eR.add('not', function (left, right) {
    return left != right;
  });
  eR.add('>', function (left, right) {
    return left > right;
  });
  eR.add('<', function (left, right) {
    return left < right;
  });
  eR.add('>=', function (left, right) {
    return left >= right;
  });
  eR.add('<=', function (left, right) {
    return left <= right;
  });
  eR.add('===', function (left, right) {
    return left === right;
  });
  eR.add('==', function (left, right) {
    // Allow string to number comparisons
    return left == right;
  });
  eR.add('!==', function (left, right) {
    return left !== right;
  });
  eR.add('in', function (left, right) {
    if (!isArray(right)) {
      if (!right) right = '';
      right = right.split(',');
    }
    return right.indexOf(left) !== -1;
  });
  eR.add('!in', function (left, right) {
    if (!isArray(right)) {
      right = right.split(',');
    }
    return right.indexOf(left) === -1;
  });
  eR.add('includes', function (left, right) {
    if (!left) return;
    var re = new RegExp(right);
    return left.search(right) !== -1;
  });
  eR.add('typeof', function (left, right) {
    if (!right) return;
    if (right == 'object') {
      return (left !== null && !(left instanceof String) && !(left instanceof Number) && !(left instanceof Date) && (typeof left == 'object') && Object.keys(left).length);
    }
    return typeof left == right;
  });

  var isHelper = function () {
    var args = arguments
      , left = args[0]
      , operator = args[1]
      , right = args[2]
      , options = args[3]
      ;

    if (args.length == 2) {
      options = args[1];
      if (left) return options.fn(this);
      return options.inverse(this);
    }

    if (args.length == 3) {
      right = args[1];
      options = args[2];
      if (left == right) return options.fn(this);
      return options.inverse(this);
    }

    if (eR.call(operator, left, right)) {
      return options.fn(this);
    }
    return options.inverse(this);
  };


  var containsHelper = function (str, pattern, options) {
    if (str && str.indexOf(pattern) !== -1) {
      return options.fn(this);
    }
    return options.inverse(this);
  };



  Handlebars.registerHelper('is', isHelper);

  Handlebars.registerHelper('contains', containsHelper);

  Handlebars.registerHelper('split', function (obj, el) {
    var res = '';
    if (!obj) return res;
    for (var i in obj) {
      res += '<' + el + '>' + obj[i] + '</' + el + '>';
    }
    return res;
  });

  Handlebars.registerHelper('sort', function (obj, dir, on_attr) {
    if (dir == 'desc') {
      if (on_attr) {
        return obj.sort(function (a, b) { return b[on_attr] - a[on_attr] });
      }
      return obj.reverse();
    }
    else {
      if (on_attr) {
        return obj.sort(function (a, b) { return a[on_attr] - b[on_attr] });
      }
      return obj.sort();
    }
  });

  Handlebars.registerHelper('unique', function (obj) {
    var res = [];
    var done = [];
    for (var i in obj) {
      var item = obj[i];
      var strItem = item.toString();
      if (done.indexOf(strItem) < 0) {
        res.push(item);
        done.push(strItem);
      }
    }

    return res;
  });

  Handlebars.registerHelper('pluck', function (obj, attr, attr2) {
    var res = [];
    for (var i in obj) {
      if (obj.hasOwnProperty(i)) {
        var item = obj[i];
        var val = [item[attr]];
        if (attr2) val.push(item[attr2]);
        res.push(val);
      }
    }

    return res;
  });

  // if all are true
  // From: https://stackoverflow.com/a/14840042/483133
  Handlebars.registerHelper('if_all', function () {
    var args = [].slice.apply(arguments);
    var opts = args.pop();

    var fn = opts.fn;
    for (var i = 0; i < args.length; ++i) {
      if (args[i])
        continue;
      fn = opts.inverse;
      break;
    }
    return fn(this);
  });


  // Handle the substitution of caption-before labels in the block with
  //  {{#caption_before_substitutions this}}...{{/caption_before_substitutions}}
  Handlebars.registerHelper('caption_before_substitutions', function (data, options) {
    var text = options.fn(this);
    var block = $(text);
    _fpa.form_utils.caption_before_substitutions(block, data);

    return block[0].outerHTML;
  });

  Handlebars.registerHelper('join', function (list, with_str, context) {
    if (!list) return list;
    if (!list.join) return list;
    return list.join(with_str);
  });


  // Replace instance(s) of replace_str in orig_str, with with_str.
  // re_options represents zero or more standard regex options
  //   g: replace all
  //   i: case insensitive
  //   etc
  Handlebars.registerHelper('replace', function (orig_str, replace_str, with_str, re_options, context) {
    var reo;

    if (!replace_str || replace_str == '') return orig_str;

    if (orig_str == null) return;

    // Avoid using the context object if the last option was excluded from the call
    if (!re_options.hasOwnProperty('name'))
      reo = re_options;
    var re = new RegExp(replace_str, reo);
    return orig_str.replace(re, with_str);
  });

  Handlebars.registerHelper('was', function (obj, options) {
    if (obj || obj === 0)
      return options.fn(this);
    else
      return options.inverse(this);
  });

  Handlebars.registerHelper('has', function (obj, options) {
    if (this.hasOwnProperty(obj))
      return options.fn(this);
    else
      return options.inverse(this);
  });


  Handlebars.registerHelper('includes', function (obj, inc) {
    if (!obj) return;
    var re = new RegExp(inc);
    return obj.search(inc) !== -1;
  });

  Handlebars.registerHelper('with_content', function (name, type, context, options) {
    return with_content(name, type, context, options);
  });

  Handlebars.registerHelper('stringify', function (obj) {
    return JSON.stringify(obj, undefined, 4);
  });

  Handlebars.registerHelper('plain_object', function (obj) {
    return obj;
  });

  Handlebars.registerHelper('typeof', function (obj) {
    return typeof obj;
  });

  Handlebars.registerHelper('nl2br', function (text) {
    return _fpa.utils.nl2br(text);
  });

  Handlebars.registerHelper('quoteattr', function (text) {
    var s = text;
    var preserveCR = false;
    preserveCR = preserveCR ? '&#13;' : '\n';
    return ('' + s) /* Forces the conversion to string. */
      .replace(/&/g, '&amp;') /* This MUST be the 1st replacement. */
      .replace(/'/g, '&apos;') /* The 4 other predefined entities, required. */
      .replace(/"/g, '&quot;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      /*
      You may add other replacements here for HTML only
      (but it's not necessary).
      Or for XML, only if the named entities are defined in its DTD.
      */
      .replace(/\r\n/g, preserveCR) /* Must be before the next replacement. */
      .replace(/[\r\n]/g, preserveCR);
    ;
  });


  Handlebars.registerHelper('timestamp', function (text) {
    if (text) {
      return _fpa.utils.ISOdatetoTimestamp(text);
    }
  });

  Handlebars.registerHelper('get', function (obj, key, key2, key3) {
    if (!obj || !key) return;

    var item = obj[key.toString()];
    if (!item) {
      return item;
    }
    else {
      item = item[key2];
    }
    if (!item) {
      return item;
    }
    else {
      return item[key3];
    }
  });

  Handlebars.registerHelper('date_time', function (text) {
    const dtf = UserPreferences.date_time_format();
    if(!dtf) return text; 

    const d = (text) ? _fpa.utils.DateTime.fromISO(text) : _fpa.utils.DateTime.now();
    const formatted = (d.isValid) ?
        d.toFormat(dtf) :
        text;
    return new Handlebars.SafeString(formatted);
  });



  Handlebars.registerHelper('fpa_state_item', function (name, key, sub_key, sub_key2, sub_key3, sub_key4, sub_key5) {
    var res = _fpa.state[name];
    if (res && key && !key.hash)
      res = res[key];
    if (res && sub_key && !sub_key.hash)
      res = res[sub_key];
    if (res && sub_key2 && !sub_key2.hash)
      res = res[sub_key2];
    if (res && sub_key3 && !sub_key3.hash)
      res = res[sub_key3];
    if (res && sub_key4 && !sub_key4.hash)
      res = res[sub_key4];
    if (res && sub_key5 && !sub_key5.hash)
      res = res[sub_key5];
    return res;
  });

  Handlebars.registerHelper('pad_start', function (value, num, padstr) {
    return String(value).padStart(num, padstr);
  });

  Handlebars.registerHelper('concat', function (str1, str2, str3) {
    str1 = str1 || '';
    str2 = str2 || '';
    str3 = str3 || '';

    if (typeof str1 == 'object') str1 = '';
    if (typeof str2 == 'object') str2 = '';
    if (typeof str3 == 'object') str3 = '';

    return str1 + str2 + str3;
  });


  Handlebars.registerHelper('simple_log', function (t) {
    console.log(t);
  });

  Handlebars.registerHelper('log', function () {
    console.log(['Values:'].concat(
      Array.prototype.slice.call(arguments, 0, -1)
    ));
  });

  Handlebars.registerHelper('debug', function () {
    console.log('Context:', this);
    console.log(['Values:'].concat(
      Array.prototype.slice.call(arguments, 0, -1)
    ));
  });

  Handlebars.registerHelper('new_random', function (array, items, options) {
    _fpa.state.hh = _fpa.state.hh || {};
    _fpa.state.hh.random = Math.floor(10000000000000 * Math.random());

    return _fpa.state.hh.random;
  });

  Handlebars.registerHelper('get_random', function (array, items, options) {
    _fpa.state.hh = _fpa.state.hh || {};
    return _fpa.state.hh.random;
  });


  Handlebars.registerHelper('filter', function (array, items, options) {
    var item, result, _i, _len;
    result = '';
    var ins = items.split(',');


    for (_i = 0, _len = ins.length; _i < _len; _i++) {
      item = array[ins[_i]];
      result += options.fn(item, { data: { key: ins[_i] } });
    }

    return result;
  });

  // Display date in local format, without adjusting the timezone and giving the appearance of changing the day
  Handlebars.registerHelper('local_date', function (date_string, unknown, options) {
    if (date_string === null || date_string === '') return unknown;
    const startTime = _fpa.utils.DateTime.fromISO(date_string)

    if (!startTime.isValid) {
      if (options.hash.return_string)
        return date_string;
      else
        return unknown;
    }

    const format = UserPreferences.date_format();
    return startTime.toUTC().toFormat(format);
  });

  Handlebars.registerHelper('and', function (a, b, options) {
    return a && b;
  });

  Handlebars.registerHelper('or', function (a, b, options) {
    return a || b;
  });

  Handlebars.registerHelper('not', function (a, options) {
    return !a;
  });

  Handlebars.registerHelper('to_string', function (stre) {
    if (typeof stre === 'undefined' || stre == null) return

    return String(stre)
  });


  Handlebars.registerHelper('underscore', function (stre, options) {
    if (!stre) return null;
    return stre.underscore()
  });

  Handlebars.registerHelper('ns_underscore', function (stre, options) {
    if (!stre) return null;
    return stre.ns_underscore();
  });

  Handlebars.registerHelper('ns_hyphenate', function (stre, options) {
    if (!stre) return null;
    return stre.ns_hyphenate();
  });


  Handlebars.registerHelper('pretty_string', function (stre, options) {
    if (options && !options.hash) options.hash = {};
    return _fpa.utils.pretty_print(stre, options.hash);
  });


  Handlebars.registerHelper('local_time', function (stre) {
    if (!stre || stre === '' || !stre.length) return;
    let s = stre.toString();

    s = new Date(s);
    if (s.toString() === 'Invalid Date') return stre;

    const d = _fpa.utils.DateTime.fromJSDate(s);
    if (!d.isValid) return stre;

    const format = UserPreferences.time_format();
    return d.toUTC().toFormat(format);
  });


  Handlebars.registerHelper('capitalize', function (str) {
    return _fpa.utils.capitalize(str);
  });

  Handlebars.registerHelper('hyphenate', function (str) {
    if (!str) return;
    return str.hyphenate();
  });

  Handlebars.registerHelper('id_hyphenate', function (str) {
    if (!str) return;
    return str.id_hyphenate();
  });


  Handlebars.registerHelper('pathify', function (str) {
    if (!str) return;
    return str.pathify();
  });

  Handlebars.registerHelper('pluralize', function (str) {
    if (!str) return;
    return str.pluralize();
  });

  Handlebars.registerHelper('singularize', function (str) {
    if (!str) return;
    return str.singularize();
  });

  Handlebars.registerHelper('titleize', function (str) {
    if (!str) return;
    return str.titleize();
  });

  Handlebars.registerHelper('substring', function (str, from, to) {
    if (str == null) return;
    if (str.toString) str = str.toString();
    if (!str.substring) return str;

    var txt = document.createElement("textarea");
    txt.innerHTML = str;
    str = txt.value;
    if (str.length > to + 10) {
      str = str.substring(from, to);
      str = str + '(...)';
    }
    return str;
  });


  Handlebars.registerHelper('template', function (source) {
    return Handlebars.compile(source, _fpa.HandlebarsCompileOptions)(this);
  });


  Handlebars.registerHelper('compile_template', function (source) {
    return Handlebars.compile(source, _fpa.HandlebarsCompileOptions);
  });

  Handlebars.registerHelper('run_template', function (template, context) {
    if (!template) {
      console.log("Template to be run is null.");
      console.log(this);
      console.log(context);
      return;
    }

    return template(this);
  });

  Handlebars.registerHelper('one_decimal', function (num) {
    return num.toFixed(1);
  });

  Handlebars.registerHelper('markdown_html', function (obj) {
    return megamark(obj);
  });

  Handlebars.registerHelper('json_stringify', function (obj) {
    return JSON.stringify(obj);
  });

  Handlebars.registerHelper('pretty_print', function (obj) {
    return JSON.stringify(obj, null, 2);
  });

  Handlebars.registerHelper('pretty_print_html', function (obj) {
    return JSON.stringify(obj, null, '<div>  ');
  });

  Handlebars.registerHelper('humanize', function (obj) {
    if (!obj) return;
    if (typeof obj !== 'string') return obj;

    obj = _fpa.utils.translate(obj, 'field_labels');

    return obj.replace(/_/g, ' ');
  });

  Handlebars.registerHelper('in', function (context, key, items, options) {

    var ins = items.split(',');


    if (ins.indexOf(key) >= 0)
      return options.fn(context);
    else
      return options.inverse(context);


  });

  return eR;

}));
