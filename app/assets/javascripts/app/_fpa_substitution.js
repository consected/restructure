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
    const IfBlockRegExString = `({{#if (${TagnameRegExString})}}([^]+?)({{else}}([^]+?))?{{/if}})`;
    const StartQuote = `["'‘]`
    const EndQuote = `["'’]`
    const IsBlockRegExString = `({{#is ([0-9a-zA-Z_.:-]+) ${StartQuote}(===|!===|==|!==|<|>|<=|>=)${EndQuote} (${StartQuote}?.+?${EndQuote}?)}}(.+?)({{else}}(.+?))?{{/is}})`;

    // [^]+? if the Javascript way to get everything across multiple lines (non-greedy)
    const IfBlocksRegEx = new RegExp(IfBlockRegExString, 'gm');
    const IfBlockRegEx = new RegExp(IfBlockRegExString, 'm');
    const IsBlocksRegEx = new RegExp(IsBlockRegExString, 'gm');
    const IsBlockRegEx = new RegExp(IsBlockRegExString, 'm');
    const TagRegEx = new RegExp(`{{${TagnameRegExString}}}`, 'g');
    const PossQuotedRegEx = new RegExp(`(${StartQuote})(.+)(${EndQuote})`);

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
        if (tag_value && tag_value.toString().length) {
          text = text.replace(block_container, if_block[3] || '');
        }
        else {
          text = text.replace(block_container, if_block[5] || '');
        }
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

        let exp_parts = exp.match(PossQuotedRegEx)
        if (exp_parts[2] && exp_parts[4]) {
          exp = exp_parts[3]
        }
        else if (isNaN(parseInt(exp_parts[3]))) {
          exp = _this.value_for_tag(exp_parts[3], new_data)
        }
        else {
          exp = parseInt(exp_parts[3])
        }


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
          case '>=':
            comp = tag_value >= exp;
            break;
          case '<=':
            comp = tag_value <= exp;
            break;
          case '>':
            comp = tag_value > exp;
            break;
          case '<':
            comp = tag_value < exp;
            break;
          default:
            console.log(`The specified #is condition '${op}' is not valid.`)
            break;
        }

        if (comp) {
          text = text.replace(block_container, is_block[5] || '');
        }
        else {
          text = text.replace(block_container, is_block[7] || '');
        }
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



}