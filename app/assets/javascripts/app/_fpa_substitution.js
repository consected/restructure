_fpa.substitution = class {

  constructor(text, data) {
    this.text = text;
    this.data = data;
    this.block = null;
  }

  static substitute(text, data) {
    this.substitution = new _fpa.substitution(text, data);
    return this.substitution.substitute();
  }

  get_data() {
    const data = this.data;
    var new_data = {};
    if (data && (data.master_id || data.vdef_version)) {
      var master_id = data.master_id;
    } else if (this.block) {
      var master_id = this.block.parents('.master-panel').first().attr('data-master-id');
    }

    if (data) {
      // Clone the data
      new_data = Object.assign({}, data);

      //  Set user_preference and current_user_roles in the data for possible substitution
      _fpa.state.current_user = _fpa.state.current_user || {}
      if (!new_data.user_preference) new_data.user_preference = _fpa.state.current_user_preference;
      if (!new_data.current_user) new_data.current_user = _fpa.state.current_user;
      if (!new_data.current_user_id) new_data.current_user_id = _fpa.state.current_user.id;
      if (!new_data.current_user_email) new_data.current_user_email = _fpa.state.current_user.email;
      if (!new_data.current_user_roles) {
        new_data.current_user_roles = {}
        if (_fpa.state.current_user_roles && _fpa.state.current_user_roles.forEach) {
          _fpa.state.current_user_roles.forEach(function (v) {
            new_data.current_user_roles[v.id_underscore()] = v;
          });
        }
      }
    }

    // Get the master data saved in state for this instance.
    var master = _fpa.state.masters && _fpa.state.masters[master_id];
    if (master) {
      // Add a clone of the master data into the master: attribute
      new_data.master = Object.assign({}, master);
    }

    return new_data;
  };

  value_for_tag(tag, new_data) {
    var elsplit = tag.split('.');
    var iter_data = new_data;
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
      else if (iter_data.hasOwnProperty(next_tag)) {
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

  substitute() {
    var text = this.text;
    var data = this.data;
    const _this = this;
    if (!text || text.length < 1) return;

    // Special escaping of double curly braces allows Handlebars substitutions
    // to be skipped if these can't provide what is needed, reverting to handling
    // by this function.
    text = text.replaceAll('{^{', '{{').replaceAll('}^}', '}}')

    const TagnameRegExString = '[0-9a-zA-Z_.:\-]+';
    const IfBlockRegExString = `({{#if +(${TagnameRegExString})}}([^]+?){{/if}})`;
    const StartQuote = `["'‘“]`
    const EndQuote = `["'’”]`
    const IsOperator = '(.+?)'
    const IsConditions = `([0-9a-zA-Z_.:-]+) ${StartQuote}${IsOperator}${EndQuote} (${StartQuote}?.+?${EndQuote}?)`
    const IsBlockRegExString = `({{#is ${IsConditions}}}(.+?){{/is}})`;

    // [^]+? if the Javascript way to get everything across multiple lines (non-greedy)
    const IfBlocksRegEx = new RegExp(IfBlockRegExString, 'gms');
    const IfBlockRegEx = new RegExp(IfBlockRegExString, 'ms');
    const IsBlocksRegEx = new RegExp(IsBlockRegExString, 'gms');
    const IsBlockRegEx = new RegExp(IsBlockRegExString, 'ms');
    const ElseIfBoundaryRegEx = new RegExp(`{{else if +(${TagnameRegExString})}}`, 'ms');
    const ElseRegEx = /{{else}}/ms;
    const ElseIsBoundaryRegEx = new RegExp(`{{else is +${IsConditions}}}`, 'ms');
    const TagRegEx = new RegExp(`{{${TagnameRegExString}}}`, 'g');

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
        text = text.replace(block_container, sub_text || '');
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
        text = text.replace(block_container, sub_text || '');
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
        if (ignore_missing == 'show_blank') {
          got = '';
        } else {
          got = '(?)';
        }
      } else if (formatters) {
        got = _fpa.tag_formatter.format_all(got, formatters, tag_name, data);
      }

      text = text.replace(el, got);
    });

    return text;
  };

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

  eval_is_comp(op, tag_value, exp, new_data) {
    const _this = this;
    const StartQuote = `["'‘“]`
    const EndQuote = `["'’”]`
    const NotEndQuote = '[^"\'’”]'
    const PossQuotedRegEx = new RegExp(`(${StartQuote})?(.+${NotEndQuote})?(${EndQuote})?`);

    if (exp) {
      const exp_length = exp.length;
      if (exp_length > 1 && exp[0].match(new RegExp(StartQuote)) && exp[exp_length - 1].match(new RegExp(EndQuote))) {
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