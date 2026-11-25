_fpa.substitution = class {

  constructor(text, data, options) {
    this.text = text;
    this.data = data;
    this.options = options || {};
    this.block = null;
  }

  // Substitutes the text against the data, returning a new string. Options: missing, escape_values, auto_titleize.
  static substitute(text, data, options) {
    this.substitution = new _fpa.substitution(text, data, options);
    return this.substitution.substitute();
  }

  // Returns a function (context) => string for an admin config string such as a caption or edit_button_href.
  static compile_config_string(source, options) {
    const config_options = Object.assign({ missing: 'blank', escape_values: true, auto_titleize: false }, options || {});
    const source_text = source == null ? '' : String(source);
    if (source_text.trim().length === 0) return function () { return ''; };
    // Text without curly tags needs no substitution.
    if (!source_text.includes('{{')) return function () { return source_text; };

    // ERB escapes quotes in captions, so decode them inside #is / else is conditions for the comparisons to match.
    const config_source = source_text.replace(_fpa.substitution.ConfigConditionalTagRegEx, function (tag, expression) {
      const decoded_expression = expression
        .replace(/&#39;|&#x27;/g, "'")
        .replace(/&quot;/g, '"');
      return '{{' + decoded_expression + '}}';
    });

    return function (context) {
      const output = _fpa.substitution.substitute(config_source, context, config_options);
      // Re-encode quotes in any conditional tags left unprocessed, so they cannot break out of an HTML attribute.
      return output.replace(_fpa.substitution.ConfigConditionalTagRegEx, function (tag) {
        return tag.replace(/'/g, '&#39;').replace(/"/g, '&quot;');
      });
    };
  }

  // Map of role id to role. Rebuilt only when the current_user_roles array is replaced.
  static current_user_roles_map() {
    const current_user_roles = _fpa.state.current_user_roles;
    if (!Object.prototype.hasOwnProperty.call(this, '_current_user_roles_source') ||
      this._current_user_roles_source !== current_user_roles) {
      const roles_map = {};
      if (current_user_roles && current_user_roles.forEach) {
        current_user_roles.forEach(function (role) {
          roles_map[role.id_underscore()] = role;
        });
      }
      this._current_user_roles_source = current_user_roles;
      this._current_user_roles_map = roles_map;
    }

    return this._current_user_roles_map;
  }

  // Own-property check that tolerates null and undefined.
  static has_own(obj, key) {
    return obj != null && Object.prototype.hasOwnProperty.call(obj, key);
  }

  // The record layered beneath a get_data() result, or null when there is none.
  static layered_base(obj) {
    const base = Object.getPrototypeOf(obj);
    return base === Object.prototype ? null : base;
  }

  // Builds the data used for substitution: the record layered with user, time, role, constant and master values.
  get_data() {
    const data = this.data;
    // Layer the enrichment values over the record instead of copying it: copying and
    // extending a record with many fields dominates rendering time. The record is never modified.
    const base = data !== null && typeof data === 'object' ? data : Object.assign({}, data || {});
    var new_data = Object.create(base);
    // True if the key is already set on the record or the layer, so a record value is never overwritten.
    const has_value = function (key) {
      return _fpa.substitution.has_own(new_data, key) || _fpa.substitution.has_own(base, key);
    };
    var master_id;
    if (data && (data.master_id || data.vdef_version)) {
      master_id = data.master_id;
    } else if (this.block) {
      master_id = this.block.parents('.master-panel').first().attr('data-master-id');
    }

    // Keep the historical front-end user_preference alias and expose the
    // backend-aligned name separately for portable substitutions.
    _fpa.state.current_user = _fpa.state.current_user || {};
    // Falsy record values are replaced by the current user's values, unlike the has_value checks below.
    if (!new_data.user_preference) new_data.user_preference = _fpa.state.current_user_preference;
    if (!has_value('current_user_preference')) {
      new_data.current_user_preference = _fpa.state.current_user_preference;
    }
    if (!new_data.current_user) new_data.current_user = _fpa.state.current_user;
    if (!new_data.current_user_id) new_data.current_user_id = _fpa.state.current_user.id;
    if (!new_data.current_user_email) new_data.current_user_email = _fpa.state.current_user.email;
    // Reuse the page's AJAX-refreshed timestamp; initialize lazily if setup has not run yet.
    if (!new_data.now) {
      _fpa.state.now = _fpa.state.now || _fpa.utils.DateTime.now().toUTC().toISO();
      new_data.now = _fpa.state.now;
    }
    if (!new_data.current_user_roles) {
      new_data.current_user_roles = _fpa.substitution.current_user_roles_map();
    }

    // Add only the explicitly allowlisted constants supplied by the server, without
    // replacing any value already present on the record.
    const common_constants = _fpa.state.common_constants || {};
    Object.keys(common_constants).forEach(function (key) {
      if (!has_value(key)) {
        new_data[key] = common_constants[key];
      }
    });

    // Get the master data saved in state for this instance.
    var master = _fpa.state.masters && _fpa.state.masters[master_id];
    if (master) {
      // Add a clone of the master data into the master: attribute
      new_data.master = Object.assign({}, master);
    }

    return new_data;
  };

  // Resolves a dotted tag against the data. Returns [value, tag_name].
  value_for_tag(tag, new_data) {
    tag = tag.replace(/^this\./, '');
    var elsplit = tag.split('.');
    var iter_data = new_data;
    const root_base = _fpa.substitution.layered_base(new_data);
    for (const next_tag of Object.values(elsplit)) {
      var got = null;
      var tag_name = next_tag;
      var is_array = Array.isArray(iter_data);

      if (is_array) {
        if (next_tag === 'first') {
          got = iter_data[0];
        }
        else if (next_tag === 'last') {
          got = iter_data[iter_data.length - 1];
        }
        else if (Number(next_tag) == next_tag) {
          got = iter_data[Number(next_tag)]
        }
        else {
          // If nothing specified, just use the first item
          got = iter_data[0];
        }
      }
      else if (typeof iter_data == 'string' && next_tag === 'json_parse') {
        got = JSON.parse(iter_data)
      }
      else if (typeof iter_data == 'string' && next_tag === 'yaml_parse') {
        got = jsyaml.load(iter_data)
      }
      // At the root, record fields are found through the layer's prototype.
      else if (_fpa.substitution.has_own(iter_data, next_tag) ||
        (iter_data === new_data && _fpa.substitution.has_own(root_base, next_tag))) {
        got = iter_data[next_tag];
      }
      else if (iter_data.embedded_item && iter_data.embedded_item.hasOwnProperty(next_tag)) {
        got = iter_data.embedded_item[next_tag];
      }
      else if (next_tag.indexOf('glyphicon_') === 0) {
        const icon = next_tag.replace('glyphicon_', '').replace('_', '-');
        got = `<span class="glyphicon glyphicon-${icon}"></span>`;
      }
      else if (next_tag.indexOf('embedded_report') === 0) {
        var repname = next_tag.replace('embedded_report_', '');
        got = _fpa.utils.embedded_report(repname, this.data);
      }
      else if (iter_data.model_references) {
        // Get array of matching references with this resource name
        got = iter_data.model_references.filter((el) => el.to_record_resource_name == next_tag);
      }

      iter_data = got;
      if (!got) {
        break;
      }
    }

    return [got, tag_name];
  };

  // Processes conditional blocks, then tags, and returns the resulting text.
  substitute() {
    var text = this.text;
    var data = this.data;
    const _this = this;
    if (!text || text.length < 1) return;

    // Special escaping of double curly braces allows Handlebars substitutions
    // to be skipped if these can't provide what is needed, reverting to handling
    // by this function.
    text = text.replaceAll('{^{', '{{').replaceAll('}^}', '}}')

    const regexes = _fpa.substitution.RegularExpressions;
    const IfBlocksRegEx = regexes.IfBlocks;
    const IfBlockRegEx = regexes.IfBlock;
    const IsBlocksRegEx = regexes.IsBlocks;
    const IsBlockRegEx = regexes.IsBlock;
    const ElseIfBoundaryRegEx = regexes.ElseIfBoundary;
    const ElseRegEx = regexes.Else;
    const ElseIsBoundaryRegEx = regexes.ElseIsBoundary;
    const TagRegEx = regexes.Tag;

    var ifres = text.match(IfBlocksRegEx);
    var isres = text.match(IsBlocksRegEx);

    if (ifres && ifres.length) {
      var new_data = _this.get_data();

      ifres.forEach(function (if_blocks) {
        const if_block = if_blocks.match(IfBlockRegEx);
        if (!if_block) return;

        let block_container = if_block[0];
        let initial_tag = if_block[2];
        let inner_content = if_block[3] || '';
        let parsed = _this.parse_if_clauses(initial_tag, inner_content, ElseIfBoundaryRegEx, ElseRegEx);
        let clauses = parsed[0];
        let else_content = parsed[1];
        let sub_text = null;

        clauses.forEach(function (clause) {
          if (sub_text != null) return;
          let tag = clause[0];
          let clause_content = clause[1];
          let vpair = _this.value_for_tag(tag, new_data)
          let tag_value = vpair[0];
          if (tag_value && tag_value.toString().length) {
            sub_text = clause_content || '';
          }
        });

        if (sub_text == null) sub_text = else_content || '';
        // A function replacement keeps $ sequences in the block content literal.
        text = text.replace(block_container, () => sub_text || '');
      });
    }

    if (isres && isres.length) {
      if (!new_data) {
        var new_data = _this.get_data();
      }

      isres.forEach(function (is_blocks) {
        const is_block = is_blocks.match(IsBlockRegEx);
        if (!is_block) return;

        let block_container = is_block[0];
        let initial_tag = is_block[2]
        let initial_op = is_block[3]
        let initial_exp = is_block[4]
        let inner_content = is_block[5] || '';
        let parsed = _this.parse_is_clauses(initial_tag, initial_op, initial_exp, inner_content, ElseIsBoundaryRegEx, ElseRegEx);
        let clauses = parsed[0];
        let else_content = parsed[1];
        let sub_text = null;

        clauses.forEach(function (clause) {
          if (sub_text != null) return;
          let tag = clause[0];
          let op = clause[1];
          let exp = clause[2];
          let clause_content = clause[3];
          let vpair = _this.value_for_tag(tag, new_data)
          let tag_value = vpair[0];
          let comp = _this.eval_is_comp(op, tag_value, exp, new_data)
          if (comp) {
            sub_text = clause_content || '';
          }
        });

        if (sub_text == null) sub_text = else_content || '';
        text = text.replace(block_container, () => sub_text || '');
      });
    }

    var res = text.match(TagRegEx);
    if (!res || res.length < 1) return text;

    if (!new_data) {
      var new_data = _this.get_data();
    }

    res.forEach(function (el) {
      let formatters = el.replace('{{', '').replace('}}', '').split('::');
      let tag = formatters.shift();
      let ignore_missing = null;
      let no_html_tag = false;

      if (formatters[0] == 'ignore_missing') {
        ignore_missing = 'show_blank';
      }

      if (formatters.indexOf('no_html_tag') >= 0) {
        no_html_tag = true;
      }

      let vpair = _this.value_for_tag(tag, new_data)
      let got = vpair[0];
      let tag_name = vpair[1];

      if (got == null) {
        // Config strings render missing tags blank, as Handlebars did. Other callers show (?).
        if (ignore_missing == 'show_blank' || _this.options.missing === 'blank') {
          got = '';
        } else {
          got = '(?)';
        }
      } else if (formatters.length || _this.options.auto_titleize !== false) {
        got = _fpa.tag_formatter.format_all(got, formatters, tag_name, data);
      }

      const generated_html = tag.indexOf('glyphicon_') === 0 || tag.indexOf('embedded_report_') === 0;
      // Values are HTML-escaped, except deliberate glyphicon and embedded report markup.
      if (_this.options.escape_values && !generated_html) {
        got = Handlebars.Utils.escapeExpression(got);
      }

      // A function replacement keeps $ sequences in the value literal.
      text = text.replace(el, () => got);
    });

    return text;
  };

  // Splits an #if block's content into [tag, content] clauses and the else content.
  parse_if_clauses(initial_tag, inner_content, elseIfBoundaryRegEx, elseRegEx) {
    let clauses = [];
    let else_content = null;
    let remaining = inner_content;
    let current_tag = initial_tag;

    while (remaining != null) {
      let else_if_match = remaining.match(elseIfBoundaryRegEx);
      let else_match = remaining.match(elseRegEx);
      let next_boundary = null;

      if (else_if_match && else_match) {
        next_boundary = else_if_match.index < else_match.index ? 'else_if' : 'else';
      } else if (else_if_match) {
        next_boundary = 'else_if';
      } else if (else_match) {
        next_boundary = 'else';
      }

      if (next_boundary === 'else_if') {
        clauses.push([current_tag, remaining.slice(0, else_if_match.index)]);
        current_tag = else_if_match[1];
        remaining = remaining.slice(else_if_match.index + else_if_match[0].length);
      } else if (next_boundary === 'else') {
        clauses.push([current_tag, remaining.slice(0, else_match.index)]);
        else_content = remaining.slice(else_match.index + else_match[0].length);
        break;
      } else {
        clauses.push([current_tag, remaining]);
        break;
      }
    }

    return [clauses, else_content];
  }

  // Splits an #is block's content into [tag, op, exp, content] clauses and the else content.
  parse_is_clauses(initial_tag, initial_op, initial_exp, inner_content, elseIsBoundaryRegEx, elseRegEx) {
    let clauses = [];
    let else_content = null;
    let remaining = inner_content;
    let current_tag = initial_tag;
    let current_op = initial_op;
    let current_exp = initial_exp;

    while (remaining != null) {
      let else_is_match = remaining.match(elseIsBoundaryRegEx);
      let else_match = remaining.match(elseRegEx);
      let next_boundary = null;

      if (else_is_match && else_match) {
        next_boundary = else_is_match.index < else_match.index ? 'else_is' : 'else';
      } else if (else_is_match) {
        next_boundary = 'else_is';
      } else if (else_match) {
        next_boundary = 'else';
      }

      if (next_boundary === 'else_is') {
        clauses.push([current_tag, current_op, current_exp, remaining.slice(0, else_is_match.index)]);
        current_tag = else_is_match[1];
        current_op = else_is_match[2];
        current_exp = else_is_match[3];
        remaining = remaining.slice(else_is_match.index + else_is_match[0].length);
      } else if (next_boundary === 'else') {
        clauses.push([current_tag, current_op, current_exp, remaining.slice(0, else_match.index)]);
        else_content = remaining.slice(else_match.index + else_match[0].length);
        break;
      } else {
        clauses.push([current_tag, current_op, current_exp, remaining]);
        break;
      }
    }

    return [clauses, else_content];
  }

  // Compares a tag value with an #is expression using the operator. The expression may be a quoted literal, null, or another tag.
  eval_is_comp(op, tag_value, exp, new_data) {
    const _this = this;
    const regexes = _fpa.substitution.RegularExpressions;

    if (exp) {
      const exp_length = exp.length;
      if (exp_length > 1 && exp[0].match(regexes.StartQuote) && exp[exp_length - 1].match(regexes.EndQuote)) {
        exp = exp.slice(1, exp_length - 1);
      }
      else if (exp.toLowerCase() == 'null') {
        exp = null
      }
      else if (isNaN(parseInt(exp))) {
        exp = _this.value_for_tag(exp, new_data)
      }
      else {
        exp = parseInt(exp)
      }
    }

    if (!isNaN(parseInt(exp)) && !isNaN(parseInt(tag_value))) tag_value = parseInt(tag_value)

    let no_operator = null;

    let comp;
    switch (op) {
      case '===':
        comp = tag_value == exp;
        break;
      case '!==':
        comp = tag_value != exp;
        break;
      case '==':
        comp = tag_value == exp;
        break;
      case '!=':
        comp = tag_value != exp;
        break;
      case 'in':
        comp = exp.indexOf(tag_value) >= 0;
        break;
      case '!in':
        comp = exp.indexOf(tag_value) < 0;
        break;
      case 'includes':
        comp = tag_value.indexOf(exp) >= 0;
        break;
      case '!includes':
        comp = tag_value.indexOf(exp) < 0;
        break;
      default:
        no_operator = true
        break;
    }

    if (isNaN(parseInt(tag_value))) {
      if (no_operator) console.log(`The specified #is condition '${op}' is not valid.`)

      return comp
    }

    no_operator = null;

    switch (op) {

      case '>=':
        comp = tag_value >= exp;
        break;
      case '&gt;=':
        comp = tag_value >= exp;
        break;
      case '<=':
        comp = tag_value <= exp;
        break;
      case '&lt;=':
        comp = tag_value <= exp;
        break;
      case '>':
        comp = tag_value > exp;
        break;
      case '&gt;':
        comp = tag_value > exp;
        break;
      case '<':
        comp = tag_value < exp;
        break;
      case '&lt;':
        comp = tag_value < exp;
        break;
      default:
        console.log(`The specified for integer #is condition '${op}' is not valid.`)
        no_operator = true
        break;
    }
    return comp;
  }

}

// Shared patterns avoid rebuilding the substitution parser's regular expressions for every rendered record.
_fpa.substitution.RegularExpressions = (function () {
  const tag_name = '[0-9a-zA-Z_.:\\-]+';
  const if_block = `({{#if +(${tag_name})}}([^]+?){{/if}})`;
  const start_quote = `[\"'‘“]`;
  const end_quote = `[\"'’”]`;
  const is_operator = '(.+?)';
  const is_conditions = `([0-9a-zA-Z_.:-]+) ${start_quote}${is_operator}${end_quote} (${start_quote}?.+?${end_quote}?)`;
  const is_block = `({{#is ${is_conditions}}}(.+?){{/is}})`;

  return {
    ConfigConditionalTag: /{{(\s*(?:#is\b|else\s+is\b)[^{}]*?)}}/g,
    IfBlocks: new RegExp(if_block, 'gms'),
    IfBlock: new RegExp(if_block, 'ms'),
    IsBlocks: new RegExp(is_block, 'gms'),
    IsBlock: new RegExp(is_block, 'ms'),
    ElseIfBoundary: new RegExp(`{{else if +(${tag_name})}}`, 'ms'),
    Else: /{{else}}/ms,
    ElseIsBoundary: new RegExp(`{{else is +${is_conditions}}}`, 'ms'),
    Tag: new RegExp(`{{${tag_name}}}`, 'g'),
    StartQuote: new RegExp(start_quote),
    EndQuote: new RegExp(end_quote),
  };
})();
_fpa.substitution.ConfigConditionalTagRegEx = _fpa.substitution.RegularExpressions.ConfigConditionalTag;
