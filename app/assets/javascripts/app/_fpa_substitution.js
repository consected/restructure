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
    const IfBlockRegExString = `({{#if (${TagnameRegExString})}}([^]+?)({{else if (${TagnameRegExString})}}(.+?))?({{else}}([^]+?))?{{/if}})`;
    const StartQuote = `["'‘“]`
    const EndQuote = `["'’”]`
    const IsOperator = '(.+?)'
    const IsBlockRegExString = `({{#is ([0-9a-zA-Z_.:-]+) ${StartQuote}${IsOperator}${EndQuote} (${StartQuote}?.+?${EndQuote}?)}}(.+?)({{else is ([0-9a-zA-Z_.:-]+) ${StartQuote}${IsOperator}${EndQuote} (${StartQuote}?.+?${EndQuote}?)}}(.+?))?({{else is ([0-9a-zA-Z_.:-]+) ${StartQuote}${IsOperator}${EndQuote} (${StartQuote}?.+?${EndQuote}?)}}(.+?))?({{else}}(.+?))?{{/is}})`;

    // [^]+? if the Javascript way to get everything across multiple lines (non-greedy)
    const IfBlocksRegEx = new RegExp(IfBlockRegExString, 'gms');
    const IfBlockRegEx = new RegExp(IfBlockRegExString, 'ms');
    const IsBlocksRegEx = new RegExp(IsBlockRegExString, 'gms');
    const IsBlockRegEx = new RegExp(IsBlockRegExString, 'ms');
    const MaxElseIfs = 2;
    const TagRegEx = new RegExp(`{{${TagnameRegExString}}}`, 'g');

    var ifres = text.match(IfBlocksRegEx);
    var isres = text.match(IsBlocksRegEx);

    if (ifres && ifres.length) {
      var new_data = _this.get_data();

      ifres.forEach(function (if_blocks) {
        const if_block = if_blocks.match(IfBlockRegEx);
        let block_container = if_block[0];
        let tag = if_block[2]
        let vpair = _this.value_for_tag(tag, new_data)
        let tag_value = vpair[0];
        let else_if_block = if_block[4];
        let else_if_tag = if_block[5];
        let sub_text = null;

        if (tag_value && tag_value.toString().length) {
          sub_text = if_block[3] || ''
        }

        if (sub_text == null && else_if_block) {
          vpair = _this.value_for_tag(else_if_tag, new_data)
          tag_value = vpair[0];
          if (tag_value && tag_value.toString().length) sub_text = if_block[6] || '';
        }
        text = text.replace(block_container, sub_text || '');
      });
    }

    if (isres && isres.length) {
      if (!new_data) {
        var new_data = _this.get_data();
      }

      isres.forEach(function (is_blocks) {
        const is_block = is_blocks.match(IsBlockRegEx);
        let block_container = is_block[0];
        let tag = is_block[2]
        let vpair = _this.value_for_tag(tag, new_data)
        let tag_value = vpair[0];
        let op = is_block[3]
        let exp = is_block[4]
        let comp = _this.eval_is_comp(op, tag_value, exp, new_data)
        let sub_text = null;

        if (comp) {
          sub_text = is_block[5] || '';
        }

        let iters = 1
        let start_pos = iters * 5 + 1
        let else_is_block = is_block[start_pos]
        while (!sub_text && else_is_block) {
          let else_is_tag = is_block[start_pos + 1]
          let else_is_op = is_block[start_pos + 2]
          let else_is_exp = is_block[start_pos + 3]

          vpair = _this.value_for_tag(else_is_tag, new_data)
          let else_is_tag_value = vpair[0];
          comp = _this.eval_is_comp(else_is_op, else_is_tag_value, else_is_exp, new_data)
          if (comp) {
            sub_text = is_block[start_pos + 4] || ''
            break;
          }
          iters++;
          if (iters > MaxElseIfs) break;

          start_pos = iters * 5 + 1;
          else_is_block = is_block[start_pos];
        }
        // Handle {{else}}
        if (sub_text == null) sub_text = is_block[12] || ''

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

  eval_is_comp(op, tag_value, exp, new_data) {
    const _this = this;
    const StartQuote = `["'‘“]`
    const EndQuote = `["'’”]`
    const NotEndQuote = '[^"\'’”]'
    const PossQuotedRegEx = new RegExp(`(${StartQuote})?(.+${NotEndQuote})?(${EndQuote})?`);

    if (exp) {
      const exp_length = exp.length;
      if (exp_length > 1 && exp[0].match(/#{StartQuote}/) && exp[exp_length - 1].match(/#{EndQuote}/)) {
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