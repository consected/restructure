_fpa.substitution = class {

  constructor(text, data) {
    this.text = text;
    this.data = data;
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
      new_data = Object.assign({}, data);
      if (!new_data.user_preference) new_data.user_preference = _fpa.state.current_user_preference;
      if (!new_data.current_user_roles) {
        new_data.current_user_roles = {}
        if (_fpa.state.current_user_roles && _fpa.state.current_user_roles.forEach) {
          _fpa.state.current_user_roles.forEach(function (v) {
            new_data.current_user_roles[v.id_underscore()] = v;
          });
        }
      }
    } else {
      var master_id = block.parents('.master-panel').first().attr('data-master-id');
    }

    var master = _fpa.state.masters && _fpa.state.masters[master_id];
    if (master) {
      var id = new_data.id;
      new_data = Object.assign(new_data, master);
      new_data.id = id;
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

      if (is_array && next_tag === 'first') {
        got = iter_data[0];
      }
      else if (is_array && next_tag === 'last') {
        got = iter_data[iter_data.length - 1];
      }
      else if (typeof iter_data == 'string' && next_tag === 'json_parse') {
        got = JSON.parse(iter_data)
      }
      else if (is_array && Number(next_tag) == next_tag) {
        got = iter_data[Number(next_tag)]
      }
      else if (iter_data.hasOwnProperty(next_tag)) {
        got = iter_data[next_tag];
      } else if (iter_data.embedded_item) {
        got = iter_data.embedded_item[next_tag];
      } else if (next_tag.indexOf('glyphicon_') === 0) {
        const icon = next_tag.replace('glyphicon_', '').replace('_', '-');
        got = `<span class="glyphicon glyphicon-${icon}"></span>`;
      }

      if (got) {
        iter_data = got;
      } else {
        continue;
      }
    }

    return [got, tag_name];
  };

  substitute() {
    var text = this.text;
    var data = this.data;
    const _this = this;
    if (!text || text.length < 1) return;

    const TagnameRegExString = '[0-9a-zA-Z_.:\-]+';
    const IfBlockRegExString = `({{#if (${TagnameRegExString})}}([^]+?)({{else}}([^]+?))?{{/if}})`;
    // [^]+? if the Javascript way to get everything across multiple lines (non-greedy)
    const IfBlocksRegEx = new RegExp(IfBlockRegExString, 'gm');
    const IfBlockRegEx = new RegExp(IfBlockRegExString, 'm');
    const TagRegEx = new RegExp(`{{${TagnameRegExString}}}`, 'g');

    var ifres = text.match(IfBlocksRegEx);

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
        got = _fpa.tag_formatter.format_all(got, formatters, tag_name);
      }

      text = text.replace(el, got);
    });

    return text;
  };



}