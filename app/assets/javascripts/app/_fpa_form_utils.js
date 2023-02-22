_fpa.form_utils = {
  // Although it would be appropriate to make a real object out of these functions,
  // convenience calling them individually on an ad-hoc basis around the code base does
  // not make this a good choice.

  set_field_errors: function (block, obj) {
    if (!obj) {
      // clear previous results
      $('.has-error')
        .each(function () {
          $(this).find('.error-help').remove();
        })
        .removeClass('has-error');
      return;
    }

    var first_field;
    for (var p in obj) {
      if (obj.hasOwnProperty(p)) {
        var v = obj[p];
        var f = block.find("[data-attr-name='" + p.underscore() + "']").parent();

        // In certain cases there may be more than one matching item (such as for radio buttons)
        // If so, try to jump to the main .list-group-item container
        if (f.length > 1) {
          f = f.parents('.list-group-item').first();
        }
        if (f.length == 1) {
          if (!first_field) first_field = f;
          f.addClass('has-error');
          var fn = p.replace(/_/g, ' ');
          if (f.hasClass('showed-caption-before')) fn = 'Entry';

          v = fn + ' ' + v;
          var el = $('<p class="help-block error-help">' + v + '</p>');
          f.append(el);
          delete obj[p];
          obj.form = 'has errors. Check the highlighted fields.';
        }
      }
    }
    if (first_field) _fpa.utils.jump_to_linked_item(first_field, -300);
  },

  clear_content: function (block) {
    block.removeClass('in');
    block.html('');
  },

  toggle_expandable: function (block) {
    if (block.hasClass('expanded')) block.removeClass('expanded');
    else block.addClass('expanded');
  },

  highlight_tracker_history_item: function (block, data) {
    data = _fpa.utils.get_data_attribs($(block));
    window.setTimeout(function () {
      $(data.tracker_history_item).addClass('item-highlight');
    }, 1000);
  },

  toggle_on_click_call: function (block, fn_name) {
    if (!fn_name) fn_name = block.attr('data-on-click-call');

    var els = fn_name.split('.');

    var fn = _fpa[els[0]][els[1]];

    if (fn_name && fn) {
      var attrs = _fpa.utils.get_data_attribs(block);

      fn(block, attrs);
    } else {
      console.log('no data-on-click-call value or function set');
    }
  },

  toggle_on_click_show: function (block) {
    var strdata = block.attr('data-on-click-show');

    var items = strdata.split(',');

    var attrs = _fpa.utils.get_data_attribs(block);

    for (var item, i = 0; (item = items[i]); i++) {
      item = item.trim();
      var name_target = item.split('@');
      block = $(name_target[1]);

      if (block.length == 0)
        console.log('the target provided to toggle_on_click_show does not exist: ' + name_target[1]);
      _fpa.view_template(block, name_target[0], attrs);
    }
  },

  on_open_click: function (block, timeout) {
    var res = block
      .find('.on-open-click a[data-remote="true"], .on-open-click a[data-target]')
      .not('.auto-clicked')
      .addClass('auto-clicked prevent-autoclick-scroll');
    res.each(function () {
      var item = $(this);

      if (item.hasClass('was-autoclicked')) return;
      item.addClass('was-autoclicked');

      var p = timeout;
      if (!p) {
        p = item.attr('data-open-priority');
        if (!p) p = 20;
        else p = parseInt(p);
      }

      window.setTimeout(function () {
        // item.trigger('click.rails');
        item.click();
      }, p);
    });
  },

  // Called on form submit event for AJAX or page submissions, to ensure
  // all fields are appropriately handled
  // In report edit forms, the input fields are outside the DOM block, but refer to the
  // form using the "form" attribute, indicating they belong to it. Check for this
  // and adjust the block to be formatted appropriately.
  on_form_submit: function (block) {
    if (block && block.is('form')) {
      var form_id = block.prop('id');
      if (form_id) {
        var inputs = $(`[form="${form_id}"]`).parent();
        if (inputs.length) {
          block = inputs;
        }
      }
    }

    _fpa.form_utils.date_inputs_to_iso(block);
    _fpa.form_utils.unmask_inputs(block);
  },

  unmask_inputs: function (block) {
    var inputs = block.find("input[data-unmask='number'].is-masked");
    inputs
      .each(function () {
        var res = $(this).cleanVal();
        if (res) {
          $(this).val(res);
        }
      })
      .removeClass('is-masked');
  },

  date_inputs_to_iso: function (block) {
    var dates = block.find('input.date-is-local');
    if (dates.length > 0) {
      dates
        .each(function () {
          var v = $(this).val();
          if (v || v !== '') {
            var res = _fpa.form_utils.locale_date_to_iso(v);
            if (res) {
              $(this).val(res);
            }
          }
        })
        .removeClass('date-is-local');
    }
  },

  locale_date_to_iso(v) {
    if (!v) return;

    return _fpa.utils.parseLocaleDate(v).asYMD();
  },

  locale_datetime_to_iso(v) {
    if (!v) return;

    var d = Date.parse(v);
    var d2 = new Date(d);
    return d2.toISOString();
  },

  // Handle big-select fields
  setup_big_select_fields(block) {
    block
      .find('.use-big-select')
      .not('.big-select-su')
      .each(function () {
        var label = '';
        $.big_select(
          $(this),
          $('#primary-modal .modal-body'),
          $(this)[0].big_select_hash,
          function () {
            _fpa.show_modal('', label);
          },
          function () {
            _fpa.hide_modal();
          },
          $(this)[0].big_select_options
        );
      })
      .addClass('big-select-su');
  },

  setup_select_filtering(block) {
    block
      .find('[data-select-filtering-target]')
      .not('.done-select-filtering')
      .each(function () {
        var sf = $(this).attr('data-select-filtering-target');
        var don = $(this).attr('data-object-name');
        var fn = don && don.replace('__', '_');
        var curr_el = $(this);
        var val = curr_el.val();

        // If an element id has not been specified, assume it is a field name and generate the element id
        if (sf[0] != '#') sf = `#${fn}_${sf}`;

        _fpa.form_utils.select_filtering_changed(val, sf);
        curr_el.on('change', function () {
          _fpa.form_utils.select_filtering_changed($(this).val(), sf);
        });
      })
      .addClass('done-select-filtering');
  },

  select_filtering_changed(val, el) {
    $(el).attr('data-big-select-subtype', val);
    $(`${el} optgroup[label]`).hide().attr('disabled', 'disabled');
    // Case insensitive filtering
    $(`${el} optgroup[label="${val}" i]`).show().attr('disabled', null);
    if ($(el).hasClass('attached-chosen')) {
      // Refresh the associate chosen.js values if chosen is attached to this field
      $(el).trigger('chosen:updated');
    }
  },

  data_from_form: function (block) {
    var form_els = block.find('[data-attr-name][data-object-name]');
    var form_data = {};
    var in_option = null;
    form_els.each(function () {
      var e = $(this);
      var obj_name = e.attr('data-object-name');
      var a_name = e.attr('data-attr-name');

      if (a_name == 'option_type') {
        in_option = e.val();
        if (in_option && in_option != '') var full_option_type = obj_name + '_' + in_option;
        else full_option_type = null;
      }

      if (!form_data[obj_name]) {
        form_data[obj_name] = { item_type: obj_name };
        form_data[obj_name].full_option_type = full_option_type;
      }
      if (e[0] && e[0].type == 'radio') {
        if (e.is(':checked')) form_data[obj_name][a_name] = e.val();
      } else if (e[0] && e[0].type == 'checkbox') {
        if (e.is(':checked')) form_data[obj_name][a_name] = true;
      } else {
        form_data[obj_name][a_name] = e.val();
      }
    });

    var obj_id = block.find('[data-item-id]').attr('data-item-id');
    for (var fo in form_data) {
      if (form_data.hasOwnProperty(fo)) if (!form_data[fo].id) form_data[fo].id = obj_id;
    }

    return form_data;
  },

  // Since the select_from_... fields
  // may be tied through a master association to the current instance,
  // it is not possible to cache the results directly based on a dynamic definition
  // and it must be handled at the time of the request.
  // Therefore this function does not actually provide data that is useful to the front end
  /*
  get_general_selections: function (data) {
    if (!data) return;

    if (data.multiple_results) {
      _fpa.form_utils.get_general_selections(data[data.multiple_results]);
      return;
    }

    if (data.length) {
      for (var n = 0; n < data.length; n++) {
        _fpa.form_utils.get_general_selections(data[n]);
      }
      return;
    }

    if (!data.item_type) {
      var item_key;
      for (item_key in data) {
        if (data.hasOwnProperty(item_key) && item_key != '_control') break;
      }

      var di = data[item_key];
      if (!di) return;
      data = di;
    }

    if (data.embedded_item) {
      _fpa.form_utils.get_general_selections(data.embedded_item);
    }

    var post = data.item_type ? '-item_type+' + data.item_type : '';
    post += data.extra_log_type ? '-extra_log_type+' + data.extra_log_type : '';
    var cname = 'general_selections' + post;

    _fpa.cache.get_definition(cname, function () {
      var pe = _fpa.cache.fetch(cname);
      // _general_selections may be passed as an attribute in the response data
      if (!data._general_selections) data._general_selections = {};
      for (var k in data) {
        if (data.hasOwnProperty(k)) {
          if (data.model_data_type == 'activity_log') {
            var it = data.item_type + '_' + k;
          } else {
            var it = data.item_type + 's_' + k;
          }

          var ibh = _fpa.get_items_as_hash_by('item_type', pe, it, 'value');

          var ibhi = null;
          for (ibhi in ibh) {
            break;
          }

          if (ibhi && !data._general_selections[k]) {
            data._general_selections[k] = ibh;
          }
        }
      }
    });
  },
  */

  handle_sub_list_filters: function ($control, init) {
    var $a = $control;
    var sl = $a.attr('data-filter-sub-list');
    var attr = $a.attr('data-filter-sub-list-attr');
    var val = $a.attr('data-filter-val');
    var $targets = $('[data-sub-list="' + sl + '"] [data-sub-item][data-' + attr + '="' + val + '"]');

    if (!init) {
      var filter_out = $a.hasClass('active');
      if (filter_out) {
        $a.removeClass('active');
      } else {
        $a.addClass('active');
      }
    }

    filter_out = !$a.hasClass('active');

    if (filter_out) {
      $targets
        .slideUp(function () {
          _fpa.form_utils.format_block($(this));
        })
        .addClass('filtered-out');
    } else {
      $targets
        .slideDown(function () {
          _fpa.form_utils.format_block($(this));
        })
        .removeClass('filtered-out');
    }
  },

  handle_sub_list_order: function ($control, init) {
    var $a = $control;
    var sl = $a.attr('data-order-sub-list');
    var val = $a.attr('data-order-val');

    var $targets = $('[data-sub-list="' + sl + '"]');

    if (!init) {
      var order_alt = $a.hasClass('active');
      if (order_alt) {
        $a.removeClass('active');
      } else {
        $a.addClass('active');
      }
    }

    order_alt = $a.hasClass('active');

    _fpa.form_utils.sort_blocks($targets, order_alt);
  },

  handle_sub_list_layout: function ($control, init) {
    var $a = $control;
    var sl = $a.attr('data-layout-sub-list');
    var val = $a.attr('data-force-layout');
    var $targets = $('[data-sub-list="' + sl + '"] .common-template-item, [data-sub-list="' + sl + '"] .new-block');

    if (!init) {
      var layout_alt = $a.hasClass('active');
      if (layout_alt) {
        return;
      } else {
        $('[data-layout-sub-list="' + sl + '"][data-force-layout]').removeClass('active');
        $a.addClass('active');
      }
    }

    if (val == 'wide-block') {
      $targets.removeClass('card-block').addClass('wide-block');
      $targets.find('.list-group').addClass('expandable').attr('data-toggle', 'expandable');
      _fpa.form_utils.format_block($targets.parents('[data-sub-list="' + sl + '"]').parent());
    } else {
      $targets.addClass('card-block').removeClass('wide-block');
      $targets.find('.list-group').removeClass('expandable').attr('data-toggle', null);
      _fpa.form_utils.format_block($targets.parents('[data-sub-list="' + sl + '"]').parent());
    }
  },

  // Setup the typeahead prediction for a specific text input element
  setup_typeahead: function (element, list, name, limit, options) {
    if (typeof list === 'string') list = _fpa.cache.fetch(list);

    var items = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.whitespace,
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      local: list,
    });

    var def = {
      hint: true,
      highlight: true,
      minLength: 1,
      autoselect: true,
    };

    if (!options) options = {};

    for (var i in def) {
      if (def.hasOwnProperty(i)) {
        if (!(i in options)) {
          options[i] = def[i];
        }
      }
    }

    var dataset = {
      name: name,
      source: items,
    };

    if (limit) {
      dataset.limit = limit;
    }

    $(element)
      .typeahead(options, dataset)
      .on('keypress', function (ev) {
        if (ev.keyCode != 13) return;
        var dnf = $(this).attr('data-next-field');
        if (dnf) $(dnf).focus();
        var v = $(this).val();
        if (v && v != '') $(this).addClass('has-value');
      });
  },

  // Format a substitution string like {{player_infos.first_name::ignore_if_missing::capitalize}}
  format_substitution: function (text, ops, tag_name) {
    var res = text;

    if (res == null && ops[0] != 'ignore_missing') {
      return;
    }

    // Automatically titleize names
    if (ops.length == 0 && (tag_name == 'name' || tag_name.match(/_name$/))) {
      ops = ['titleize'];
    }

    for (var i = 0; i < ops.length; i++) {
      var op = ops[i];

      if (op == 'titleize') {
        if (typeof res == 'string') {
          res = res.titleize();
        }
      } else if (op == 'no_html_tag') res;
      else if (op == 'capitalize') res = res.capitalize();
      else if (op == 'uppercase') res = res.toUpperCase();
      else if (op == 'lowercase') res = res.toLowerCase();
      else if (op == 'underscore') res = res.underscore();
      else if (op == 'hyphenate') res = res.hyphenate();
      else if (op == 'initial') res = (res[0] || '').toUpperCase();
      else if (op == 'first') res = res[0];
      else if (op == 'age') {
        res = new Date(res);

        if (res.getFullYear) {
          var today = new Date();
          var age = today.getFullYear() - res.getFullYear();
          var m = today.getMonth() - res.getMonth();
          if (m < 0 || (m === 0 && today.getDate() < res.getDate())) {
            age--;
          }
          res = age;
        }
      } else if (op == 'dicom_datetime') {
        if (typeof res == 'date') {
          res = res.toISOString();
        }
        res = res.split('.')[0].replace(/[\:\-T]/g, '');
      } else if (op == 'dicom_date') {
        if (typeof res == 'date') {
          res = res.toISOString();
        }
        res = res.split('T')[0].replace(/[\:\-T]/g, '');
      } else if (op == 'join_with_space') {
        if (Array.isArray(res)) res = res.join(' ');
      } else if (op == 'join_with_comma') {
        if (Array.isArray(res)) res = res.join(', ');
      } else if (op == 'join_with_semicolon') {
        if (Array.isArray(res)) res = res.join('; ');
      } else if (op == 'join_with_newline') {
        if (Array.isArray(res)) res = res.join('\n');
      } else if (op == 'join_with_2newlines') {
        if (Array.isArray(res)) res = res.join('\n\n');
      } else if (op == 'markup') res = megamark(res);
      else if (op == 'ignore_missing') res = res || '';
      else if (Number(op) != 0) res = res.slice(0, Number(op));
    }

    return res;
  },

  // Make subtitutions in moustaches, when in view mode.
  // This function is called by a handlebars helper rather than in the postprocessor loop
  caption_before_substitutions: function (block, data) {
    block
      .find('.caption-before')
      .not('.cb_subs_done')
      .each(function () {
        var text = $(this).html();
        if (!text || text.length < 1) return;
        var res = text.match(/{{[0-9a-zA-z_\.:]+}}/g);
        if (!res || res.length < 1) return;

        var new_data = {};
        if (data && (data.master_id || data.vdef_version)) {
          var master_id = data.master_id;
          new_data = Object.assign({}, data);
          if (!new_data.user_preference) new_data.user_preference = _fpa.state.current_user_preference;
        } else {
          var master_id = block.parents('.master-panel').first().attr('data-master-id');
        }

        var master = _fpa.state.masters && _fpa.state.masters[master_id];
        if (master) {
          var id = new_data.id;
          new_data = Object.assign(new_data, master);
          new_data.id = id;
        }

        res.forEach(function (el) {
          var formatters = el.replace('{{', '').replace('}}', '').split('::');
          var els = formatters.shift();
          var elsplit = els.split('.');

          if (formatters[0] == 'ignore_missing') {
            var ignore_missing = 'show_blank';
          }

          if (formatters.indexOf('no_html_tag') >= 0) {
            var no_html_tag = true;
          }

          var iter_data = new_data;
          for (const next_tag of Object.values(elsplit)) {
            var got = null;
            var tag_name = next_tag;

            if (iter_data.hasOwnProperty(next_tag)) {
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

          if (got == null) {
            if (ignore_missing == 'show_blank') {
              got = '';
            } else {
              got = '(?)';
            }
          } else if (formatters) {
            got = _fpa.form_utils.format_substitution(got, formatters, tag_name);
          }

          if (no_html_tag == false) {
            got = '<em class="all_caps">' + got + '</em>';
          }

          text = text.replace(el, got);
        });

        $(this).html(text);
      })
      .addClass('cb_subs_done');
  },

  // Resize all labels in a block for nice formatting without tables or fixed widths
  resize_labels: function (block, data, force) {
    if (!block) block = $(document);

    var block_list = block.find('.list-group:visible, .view-object[aria-expanded="true"]');
    if (!force) {
      block_list = block_list.not('.attached-resize-labels');
    }
    block_list.each(function () {
      // Cheap optimization to make the UI feel more responsive in large result sets
      var self = $(this);

      if (_fpa.processor_handlers && _fpa.processor_handlers.label_changes) _fpa.processor_handlers.label_changes(self);

      window.setTimeout(function () {
        var wmax = 0;
        // Get all the items that need resizing PLUS the caption-before each, allowing them to be excluded
        var list_items = self
          .find(
            '.list-group-item.result-field-container, .list-group-item.result-notes-container, .list-group-item.edit-field-container, .list-group-item.caption-before'
          )
          .not('.all-fields-caption, .force-no-caption-before');

        var prev_caption_before = false;
        list_items.each(function () {
          var this_caption_before =
            $(this).hasClass('caption-before') && !$(this).hasClass('caption-before-keep-label');
          if (prev_caption_before && !this_caption_before) {
            $(this).find('small, label').not('.radio-label').remove();
          }
          prev_caption_before = this_caption_before;
        });

        var lgi = self
          .find('.list-group-item.result-field-container, .list-group-item.edit-field-container')
          .not(
            '.is-heading, .is-sub-heading, .is-minor-heading, .is-full-width, .is-combo, .record-meta, .edit-form-header, .has-caption-before'
          );

        var all = lgi.find('small, label').not('.radio-label');
        all
          .addClass('label-resizer')
          .css({ whiteSpace: 'nowrap', width: 'auto', minWidth: 'none', marginLeft: 'inherit' });

        var block_width = lgi.first().parent().width();

        all.each(function () {
          if ($(this).is(':visible')) {
            var wnew = $(this).width();
            if (wnew > wmax) wmax = wnew;
          }
        });

        if (wmax > block_width * 0.5) wmax = block_width * 0.5;

        if (wmax > 10) {
          if (lgi.parents('form').length === 0) {
            lgi.css({ paddingLeft: wmax + 30 }).addClass('labels-resized');
            all
              .css({ minWidth: wmax, width: wmax, marginLeft: -wmax - 14, whiteSpace: 'normal' })
              .addClass('list-small-label');
          } else {
            all.css({ minWidth: wmax + 6, width: wmax + 6, whiteSpace: 'normal' }).addClass('list-small-label');
          }
        }

        _fpa.form_utils.make_labels_placeholders(block);

        lgi.addClass('done-label-resize');
      }, 1);
      self.addClass('attached-resize-labels');
    });
  },

  make_labels_placeholders: function (block) {
    block
      .find('.make-labels-placeholders')
      .not('.done-labels-placeholders')
      .each(function () {
        $(this)
          .find('.edit-field-container label, .edit-field-container small')
          .not('.radio-label')
          .each(function () {
            var f = $(this).attr('for');
            var el = $(`#${f}`);
            if (!el.length || el.attr('type') == 'radio' || el.attr('type') == 'checkbox') return;
            if (el[0].tagName == 'SELECT') {
              if (el.find('option[selected]').length == 0) {
                var selected = 'selected';
              }
              el.prepend(`<option disabled ${selected} class="select-option-placeholder">${$(this).text()}</option>`);
            } else {
              el.attr('placeholder', $(this).text());
            }
            $(this).hide();
          });
      })
      .addClass('done-labels-placeholders');
  },

  // Indicate items that have been entered on a form, making it visually fast to see
  // when there are many search form inputs
  setup_has_value_inputs: function (block) {
    if (!block) block = $(document);

    var set_has = function (item) {
      if (item.val() != '') item.addClass('has-value');
      else item.removeClass('has-value');
    };

    var items = block.find('input, select').not('.attached-has-value');
    items
      .on('change', function () {
        set_has($(this));
      })
      .each(function () {
        set_has($(this));
      })
      .addClass('attached-has-value');
  },

  // Setup the "chosen" tags on multiple select form elements (also used outside forms for
  // simple view of tags
  setup_chosen: function (block) {
    if (!block) block = $(document);

    var sels = block.find('select[multiple], .report-criteria-fields-block select, .use-chosen select').not('.attached-chosen');
    // Place the chosen setup into a timeout, since it is time-consuming for a large number
    // of "tag" fields, and blocks the main thread otherwise.
    sels
      .each(function () {
        var sel = $(this);
        window.setTimeout(function () {
          var no_sel_text = 'no tags selected';
          var alt_nst = sel.attr('data-nothing-selected-text');
          if (alt_nst) no_sel_text = alt_nst;
          sel.chosen({ width: '100%', placeholder_text_multiple: no_sel_text, hide_results_on_select: false, display_disabled_options: false });

          sel.on('chosen:showing_dropdown', function (evt, params) {
            // Access the element
            var $el = params.chosen.container;
            var el = $el[0];
            var style = el.style;
            var bc = el.getBoundingClientRect();

            // Save the original position and sizes
            $el.orig_sizes = {
              width: $el.width(),
              minHeight: $el.height(),
              position: style.position,
              top: style.top,
              left: style.left,
              zIndex: style.zIndex,
            };

            // Set where we want to position the element
            var new_sizes = $.extend({}, $el.orig_sizes);
            new_sizes.position = 'absolute';
            new_sizes.top = bc.top + window.pageYOffset;
            new_sizes.left = bc.left + window.pageXOffset;
            new_sizes.zIndex = 999999;

            // Placeholder to the original position, plus it keeps the correct size for the form
            var $elclone = ($el.elclone = $el.clone());
            $elclone.find('.chosen-drop').remove();
            $el.before($elclone);

            // Set the new position and move the chosen box into the body
            $el.css(new_sizes);
            $('body').append($el);
          });

          sel.on('chosen:hiding_dropdown', function (evt, params) {
            // Move the chosen box back into its form, and remove the placeholder
            var $el = params.chosen.container;
            $el.css($el.orig_sizes);
            $el.elclone.before($el);
            $el.elclone.remove();
          });
        }, 1);
      })
      .addClass('attached-chosen');
  },

  organize_common_templates: function (block) {
    block.find('.common-template-item').each(function () {
      var p = $(this).parents('.common-template-list').first();
      if (p.hasClass('row') && !$(this).hasClass('alt-width')) {
        $(this).addClass('col-md-8 col-lg-6');
      }
    });
  },

  // Call specific view handlers from view_options.view_handlers, which are placed
  // into data-view-handlers markup
  apply_view_handlers: function (block) {
    var bvh = block.find('[data-view-handlers]');
    bvh.each(function () {
      var vh = $(this).attr('data-view-handlers');
      if (vh && _fpa.view_handlers[vh]) _fpa.view_handlers[vh]($(this));
    });

    if (bvh.length == 0) {
      var vh = block.attr('data-view-handlers');
      if (vh && _fpa.view_handlers[vh]) {
        _fpa.view_handlers[vh](block);
      }
    }
  },

  // Blocks marked with the class use-secure-view-on-links are checked
  // to find <a> links for filestore downloads. These are then set to
  //
  setup_secure_view_links: function (block) {
    if (block.hasClass('use-secure-view-on-links-setup')) return;

    var inner = block.find('a');
    //For admins only, _fpa.state.user_can is undefined.
    if (_fpa.state.user_can && !_fpa.state.user_can.view_files_as_image) {
      inner = block.find('.use-secure-view-on-links a');
    }

    inner.each(function () {
      var href = $(this).attr('href');
      if (
        href &&
        href.indexOf('/nfs_store/downloads') >= 0 &&
        $(this).parents('.nfs-store-container-block').length == 0
      ) {
        $(this).addClass('use-secure-view');
      }
    });

    block.addClass('use-secure-view-on-links-setup');

    // Ensure that the viewer is set up with the user's capabilities to view and download
    var sv_opt = { allow_actions: null };
    sv_opt.allow_actions = _fpa.state.user_can;

    _fpa.secure_view.setup_links(block, 'a.use-secure-view', sv_opt);
    block.on('click', 'a.use-secure-view', function (ev) {
      ev.preventDefault();
    });
  },

  // Provide a filtered set of options in a select field, based on the selection of
  // another field. Used exclusively for protocol / sub-process / protocol-event forms at the moment
  // This handle both the initial setup and handling changes made to parent and dependent
  // select fields
  filtered_selector: function (block) {
    if (!block) block = $(document);
    var d = block.find('select[data-filters-selector]').not('.attached-filter');

    var do_filter = function (sel) {
      // get the child select fields this should affect
      var a = sel.attr('data-filters-selector');
      if (!a) return;

      var children = $(a);
      if (children.length === 0) return;

      // get the current value of the parent selector
      var v = sel.val();

      // in all the child select fields hide all possible options
      children.find('option[data-filter-id]').removeClass('filter-option-show').hide();
      // in all the child select fields re-show only those fields matching the parent selector
      var shown = children
        .find('option[data-filter-id="' + v + '"]')
        .addClass('filter-option-show')
        .show();
      // set attribute on the children, so we can sense this has changed (useful in features specs)
      children.attr('data-parent-filter-id', v);

      if (shown.length === 0) {
        children.addClass('no-child-items');
        children.find('option[value=""]').html('-none-');
      } else {
        children.removeClass('no-child-items');
        children.find('option[value=""]').html('-select-');
      }
      // now for each child select field reset it if the current option doesn't match
      // the new parent selection
      children.each(function () {
        // get the data-filter-id (which parent option this belongs to) for any selected items
        var ela = $(this).find('option:selected').attr('data-filter-id');
        // if this option doesn't match the new parent selection
        if (ela != v) {
          // reset the field
          $(this).val(null).removeClass('has-value');

          // If the parent selector has a value and we are resetting
          // the child, add a prevent-submit to prevent the action triggering another call
          if (v) $(this).addClass('prevent-submit');
        }
        do_filter($(this));
      });
    };

    d.each(function () {
      do_filter($(this));
    })
      .on('change', function () {
        do_filter($(this));
      })
      .addClass('attached-filter');
  },

  // Provide select filtering for select fields in user forms
  // Drive on optgroup, where the label is initially id/name and is split out
  // to just show the name and retain the id in an attribute
  // The select item that drives the change must have an attribute data-filters-select
  // with css selector pointing to the select element to be filtered on change
  // NOTE: disabled attribute is set to ensure chosen.js correctly hides options
  setup_form_filtered_select: function (block) {
    block
      .find('select[data-filters-select]')
      .not('.filters-select-attached')
      .each(function () {
        var $el = $(this);
        var filter_sel = $el.attr('data-filters-select');
        $el.on('change', function () {
          var val = $el.val();
          $(`${filter_sel} optgroup[data-group-num]`).hide().attr('disabled', 'disabled');
          $(`${filter_sel} optgroup[data-group-num="${val}"]`).show().attr('disabled', null);
          if ($(filter_sel).hasClass('attached-chosen')) {
            // Refresh the associate chosen.js values if chosen is attached to this field
            $(filter_sel).trigger('chosen:updated');
          }
        });

        var val = $el.val();
        $(`${filter_sel} optgroup[label]`)
          .each(function () {
            if (!$(this).attr('data-group-num')) {
              var l = $(this).attr('label');
              var ls = l.split('/', 2);
              var last = ls.length - 1;
              var first = 0;
              $(this).attr('label', ls[last]);
              $(this).attr('data-group-num', ls[first]);
            }
          })
          .hide().attr('disabled', 'disabled');
        $(`${filter_sel} optgroup[data-group-num="${val}"]`).show().attr('disabled', null);
        if ($(filter_sel).hasClass('attached-chosen')) {
          // Refresh the associate chosen.js values if chosen is attached to this field
          $(filter_sel).trigger('chosen:updated');
        }

      })
      .addClass('filters-select-attached');
  },

  // Use the tablesorter on profile blocks.
  // This has not been generalized at this point and needs attention
  setup_tablesorter: function (block) {
    if (!block) block = $(document);
    var tss = block.find('.tablesorter').not('.attached-tablesorter');

    window.setTimeout(function () {
      tss.each(function () {
        var ts = $(this);

        var i = 0;
        var h = {};
        ts.find('thead tr:first th').each(function () {
          if ($(this).hasClass('no-sort')) {
            $(this).attr('title', null);
            $(this).attr('aria-label', null);
            h[i] = { sorter: false };
          }
          i++;
        });

        //{0: {sorter: false}}
        ts.tablesorter({ dateFormat: 'yyyy-mm-dd', headers: h }).addClass('attached-tablesorter');
      });
    }, 100);
  },

  setup_bootstrap_items: function (block) {
    if (!block) block = $(document);
    block.find('[data-toggle~="tooltip"]').not('.attached_bs').tooltip().addClass('attached_bs');
    block.find('[data-toggle~="popover"]').not('.attached_bs').popover().addClass('attached_bs');
    block.find('[data-show-popover="auto"]').not('.attached_bs').popover('show').addClass('attached_bs');
    block.find('.dropdown-toggle').not('.attached_bs').dropdown().addClass('attached_bs');

    block.find('table').each(function () {
      var c = $(this).attr('class');
      if (c == null || c === '') $(this).addClass('table');
    });
  },

  setup_data_toggles: function (block) {
    if (!block) block = $(document);
    block
      .find('[data-toggle~="clear"]')
      .not('.attached-datatoggle-clear')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var a = $(this).attr('data-target');
        var el = $(a).html('');
        if (el.hasClass('collapse')) el.removeClass('in');
        else el.addClass('hidden');
      })
      .addClass('attached-datatoggle-clear');

    block
      .find('[data-toggle~="unhide"]')
      .not('.attached-datatoggle-uh')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var a = $(this).attr('data-target');
        $(a).removeClass('hidden');
      })
      .addClass('attached-datatoggle-uh');

    block
      .find('[data-toggle~="uncollapse"]')
      .not('.attached-datatoggle-uncoll')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var a = $(this).attr('data-target');
        $(a).collapse('show');
      })
      .addClass('attached-datatoggle-uncoll');

    block
      .find('a.scroll-to-master')
      .not('.attached-datatoggle-stm')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var a;
        if (block.hasClass('panel-collapse')) a = block;
        else a = block.parents('.panel-collapse').first();

        _fpa.utils.scrollTo(a, 100, -60);
      })
      .addClass('attached-datatoggle-stm');

    block
      .find('[data-toggle~="scrollto-target"]')
      .not('.attached-datatoggle-stt')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var a = $(this).attr('data-target');
        _fpa.utils.jump_to_linked_item(a);
      })
      .addClass('attached-datatoggle-stt');

    block
      .find('[data-toggle~="show-modal"]')
      .not('.attached-datatoggle-show-modal')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var a = $(this).attr('data-target');
        _fpa.show_modal(a);
      })
      .addClass('attached-datatoggle-show-modal');

    block
      .find('[data-prevent-on-collapse="true"]')
      .not('.attached-prevent-on-collapse')
      .on('click', function (ev) {
        if ($(this).attr('disabled')) return;
        if (!$(this).hasClass('collapse')) {
          ev.preventDefault();
        }
      })
      .addClass('attached-prevent-on-collapse');

    block
      .find('[data-toggle~="uncollapse-target-parents"]')
      .not('.attached-uncparents')
      .on('click', function () {
        if ($(this).attr('disabled')) return;

        var a;
        var f = $(this).parents('[data-form-container]');
        if (f.length == 1) {
          a = f.attr('data-form-container');
        } else a = $(this).attr('data-target');

        if (!a || a == '') {
          a = $(this).attr('data-result-target');
        }

        if (!a || a == '') return;

        $(a)
          .parents('.collapse')
          .each(function () {
            $(this).collapse('show');
          });
      })
      .addClass('attached-uncparents');

    block
      .find(
        '[data-toggle~="scrollto-result"], [data-toggle~="scrollto-target"], [data-toggle~="collapse"].scroll-to-expanded, [data-toggle~="uncollapse"].always-scroll-to-expanded '
      )
      .not('.attached-datatoggle-str')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        if (
          ($(this).hasClass('scroll-to-expanded') && !$(this).hasClass('collapsed')) ||
          $(this).hasClass('no-scroll-on-collapse')
        )
          return;

        if ($(this).hasClass('prevent-autoclick-scroll') && $(this).hasClass('auto-clicked')) {
          $(this).removeClass('prevent-autoclick-scroll');
          return;
        }

        var a;
        var f = $(this).parents('[data-form-container]');
        if (f.length == 1) {
          a = f.attr('data-form-container');
        } else a = $(this).attr('data-target');

        if (!a || a == '') {
          a = $(this).attr('data-result-target');
        }

        if (a) {
          // Only jump to the target if the current top and bottom of the block are off screen. Usually we
          // attempt to do this so that users do not have to constantly scroll an edit block into view just to type
          // some data.
          // This is approximate, since forms typically make the block larger, but we are trying to avoid unnecessary
          // scrolling, to keep the page from jumping around for the user where possible.
          // Note that the timeout is set to ensure collapse sections have had time to grow to full height

          var attempt_count = 0;
          var doscroll = function () {
            var rect = $(a).get(0);
            if (!rect) {
              if (attempt_count > 10) {
                return;
              }
              attempt_count++;
              window.setTimeout(function () {
                doscroll();
              }, 250);
              return;
            }
            rect = rect.getBoundingClientRect();

            if (rect.height < 6) {
              attempt_count++;
              window.setTimeout(function () {
                doscroll();
              }, 250);
              return;
            }

            var not_visible = !(rect.top >= 0 && 1.25 * rect.bottom < $(window).height());
            if (not_visible) {
              _fpa.utils.jump_to_linked_item(a, -100, { no_highlight: true });
            }
          };

          window.setTimeout(function () {
            doscroll();
          }, 250);
        }
      })
      .addClass('attached-datatoggle-str');

    var exp = block
      .find('[data-toggle~="expandable"]')
      .not('.attached-datatoggle-exp')
      .addClass('attached-datatoggle-exp');

    exp.on('click', function (ev) {
      var ts = ['INPUT', 'SELECT', 'TEXTAREA', 'A', 'BUTTON', 'LABEL', 'FORM', '.browse-container'];
      var bad_target = ts.indexOf(ev.target.nodeName) >= 0 || $(ev.target).parents(ts.join(', ')).length > 0;

      if ($(this).attr('disabled') || bad_target) return;
      _fpa.form_utils.toggle_expandable($(this));
    });

    // call a function on click - name the function 'something' or 'something.other' to call
    // _fpa.something(block, data) or _fpa.something.other(block, data)
    // data is produced by parsing the clicked element's data- attributes
    block
      .find('[data-on-click-call]')
      .not('.attached-toggle_on_click_call')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        _fpa.form_utils.toggle_on_click_call($(this));
      })
      .addClass('attached-toggle_on_click_call');

    block
      .find('[data-result-callback]')
      .not('.attached-toggle_on_result_callback')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var cb = $(this).attr('data-result-callback');
        var cbc = cb.split('.');
        if (cbc[1]) {
          $(this)[0].app_callback = _fpa[cbc[0]][cbc[1]];
        } else {
          $(this)[0].app_callback = _fpa[cbc[0]];
        }
      })
      .addClass('attached-toggle_on_result_callback');

    // this will render a template or partial at some location in the dom
    // comma separate a list of template@domloc to show multiple items for a single click activity
    // data-on-click-show="phone_record-partial@#domid, another-partial@#activity-log2"
    block
      .find('[data-on-click-show]')
      .not('.attached-toggle_on_click_show')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        _fpa.form_utils.toggle_on_click_show($(this));
      })
      .addClass('attached-toggle_on_click_show');

    block
      .find('[data-toggle~="clear-content"]')
      .not('.attached-datatoggle-cc')
      .on('click', function () {
        if ($(this).attr('disabled')) return;
        var a = $(this).attr('data-target');
        _fpa.form_utils.clear_content($(a));
      })
      .addClass('attached-datatoggle-cc');

    block
      .find('[data-toggle-caret]')
      .not('.attached-toggle_caret')
      .on('click', function () {
        if ($(this).hasClass('glyphicon-triangle-bottom')) {
          var el = $(this);
          $(this).removeClass('glyphicon-triangle-bottom');
          $(this).addClass('glyphicon-triangle-top');
          var t = $(this).attr('data-target');
          var tel = t && $(t);
          window.setTimeout(function () {
            el.attr('disabled', true);
            if (tel && tel.find('.list-group-item').length) {
              _fpa.form_utils.format_block(tel.parent());
            }
          }, 10);
        } else {
          var el = $(this);
          $(this).addClass('glyphicon-triangle-bottom');
          $(this).removeClass('glyphicon-triangle-top');
          var t = $(this).attr('data-result-target');
          if (t) $(t).html('');
          window.setTimeout(function () {
            el.attr('disabled', false);
          }, 10);
        }
      })
      .addClass('attached-toggle_caret');
  },

  mask_inputs: function (block) {
    block.find('[pattern]').each(function () {
      var p = $(this).attr('pattern');
      if (!p || p == '') {
        $(this).removeAttr('pattern');
      }
    });

    block
      .find('[pattern]')
      .not('.attached-datatoggle-pattern, [type="password"]')
      .each(function () {
        var p = $(this).attr('pattern');
        var t = $(this).attr('type');
        var d = $(this).attr('data-mask');
        var m;
        if ((!d || d === '') && p && p !== '') {
          if (t != 'text' && t != 'datepicker' && t != 'date') {
            $(this).attr('type', 'text');
            $(this).attr('data-unmask', t);
          }
          m = _fpa.masker.mask_from_pattern(p);

          $(this).attr('data-mask', m.mask);
          $(this).addClass('is-masking');
          $(this).mask(m.mask, { translation: m.translation, reverse: m.reverse });
          $(this).addClass('is-masked');
          $(this).removeClass('is-masking');
        }
      })
      .addClass('attached-datatoggle-pattern');

    block
      .find('[pattern].attached-datatoggle-pattern')
      .not('.is-masked')
      .each(function () {
        var el = $(this);
        var v = el.val();
        if (v && v !== '') {
          var res = el.masked(v);
          el.val(res);
        }
      })
      .addClass('is-masked');

    block
      .find('input.time-entry')
      .not('is-time-masked')
      .each(function () {
        $(this).timepicker({
          timeFormat: 'h:mm p',
          interval: 15,
          minTime: '12:00am',
          maxTime: '11:59pm',
          startTime: '12:00am',
          dynamic: true,
          dropdown: true,
          scrollbar: true,
        });
      });
  },

  setup_datepickers: function (block) {
    // force date type fields to use the date picker by making them fall back to text
    block.find('input[type="date"]').each(function () {
      const datePicker = $(this);
      if (datePicker.prop('type') === 'date') {
        datePicker.addClass('force-datepicker');
      }
      datePicker.prop('type', 'datepicker').prop('autocomplete', 'off');
    });

    // start by setting the date fields to show the date using the locale
    // only for the
    block
      .find('input[type="datepicker"]')
      .not('.date-is-local')
      .each(function () {
        var v = $(this).val();

        if (!_fpa.utils.is_blank(v)) {
          var d = _fpa.utils.YMDtoLocale(v);
          $(this).val(d);
        }
        $(this).addClass('date-is-local').prop('autocomplete', 'off');
      });

    // finally, set up datepickers on any fields that don't already have them
    block
      .find('input.force-datepicker, input[type="datepicker"]')
      .not('.attached-datepicker')
      .each(function () {
        $(this).datepicker({
          startView: 2,
          clearBtn: true,
          autoclose: true,
          todayHighlight: true,
          todayBtn: 'linked',
          format: _fpa.state.current_user_preference.date_format,
        });

        $(this).on('click', function () {
          $(this).datepicker('show');
        });

        $(this).on('keypress', function () {
          $(this).datepicker('hide');
        });

        // Automatically format the date on / being entered by hand,
        // making it easy to type 9/7/1963 and get 09/07/1963
        $(this).on('keyup', function (e) {
          var key = e.which;

          if (key == 191) {
            var v = $(this).val();
            var vparts = v.split('/');
            for (var i in vparts) {
              var vp = vparts[i];
              if (i > 1) break;
              if (vp == null || vp == '') break;
              if (vp.length < 2) vparts[i] = '0' + vp;
            }
            $(this).val(vparts.join('/'));
          }
        });

        $(this).mask('09/09/0000', { translation: _fpa.masker.translation, placeholder: '__/__/____' });
        $(this).addClass('attached-datepicker date-is-local');
      });

    block
      .find('.field-datetime-combo')
      .not('.datetime-setup')
      .each(function () {
        var de = $(this).find('.date-entry');
        var te = $(this).find('.time-entry');
        var he = $(this).find('input[type="hidden"]');

        var dres = null;
        var tres = null;

        de.on('blur change', function () {
          set_hidden_field();
        });

        te.on('blur change', function () {
          set_hidden_field();
        });

        var set_hidden_field = function () {
          tres = te.val();
          dres = de.val();

          if (dres) {
            var text = `${dres} ${tres || ''}`;
            text = _fpa.form_utils.locale_datetime_to_iso(text);
          } else {
            var text = '';
          }
          he.val(text);
        };

        set_hidden_field();
      })
      .addClass('datetime-setup');
  },

  list_view: function (block) {
    var all_blocks = block.parents('.common-template-list').first().find('.common-template-item');
    all_blocks.removeClass('col-lg-6').addClass('col-lg-12 col-lg-offset-6');
    _fpa.form_utils.resize_children(block);
  },

  sort_blocks: function (block, sort_rev) {
    // Sort dom elements within the block's parent,
    // based on the value of the data attribute specified by data-sort-desc in a child of the current block
    // For example:
    // data-sort-desc="data-item-rank"
    // will sort all blocks in the parent of this block with the attribute data-sort-desc, using the
    // value from a child of each block with the data attribute data-item-rank, for example
    // data-item-rank="10"
    // The sort will automatically sort on string, numeric or date/time values
    var sort_block = block;
    var s = sort_block.attr('data-sort-desc');
    if (!s) {
      sort_block = sort_block.find('[data-sort-desc]').first();
      if (sort_block.length) s = sort_block.attr('data-sort-desc');
    }
    if (!s) {
      sort_block = sort_block.find('[data-sub-list]');
      sort_block = sort_block.find('[data-sort-desc]').first();
      if (sort_block.length) s = sort_block.attr('data-sort-desc');
    }

    if (s) {
      var descp = sort_block.parent();
      sort_rev = sort_rev || descp.attr('data-sort-reverse');

      var $sort_els = descp.find('[data-sort-desc]');
      var $sort_marker = descp.find('.sort-marker').first();

      if ($sort_marker.length == 0) {
        $sort_els.first().before($('<div class="sort-marker"></div>'));
        $sort_marker = descp.find('.sort-marker').first();
      }

      $sort_els
        .sort(function (a, b) {
          var bres = $(b)
            .find('[' + s + ']')
            .attr(s);
          var ares = $(a)
            .find('[' + s + ']')
            .attr(s);

          if (bres == null) bres = $(b).attr(s);
          if (ares == null) ares = $(a).attr(s);

          if (bres) {
            var bboth = bres.split('--');
            if (bboth[1] == null) bboth[1] = '';
            bres = _fpa.utils.ISOdatetoTimestamp(bboth[0]) + bboth[1];
          }

          if (ares) {
            var aboth = ares.split('--');
            if (aboth[1] == null) aboth[1] = '';
            ares = _fpa.utils.ISOdatetoTimestamp(aboth[0]) + aboth[1];
          }

          if (ares == null || ares == '') return -1;
          if (bres == null || bres == '') return 1;
          // Force to a number if it is equivalent to the original string
          var n = parseFloat(ares);
          if (ares == n) ares = n;
          n = parseFloat(bres);
          if (bres == n) bres = n;

          var retdir = sort_rev ? -1 : 1;

          if (bres > ares) {
            return retdir;
          }
          if (bres < ares) {
            return -1 * retdir;
          }
          return 0;
        })
        .insertAfter($sort_marker);
    }
  },

  setup_extra_actions: function (block) {
    block
      .find('.collapse')
      .not('.attached-force-collapse')
      .each(function () {
        var el = $(this);
        el.on('show.bs.collapse', function () {
          el.removeClass('hidden');
        });
        el.on('shown.bs.collapse', function () {
          el.removeClass('hidden');
          $(this).find('a.on-show-auto-click').not('.auto-clicked').addClass('auto-clicked').click();
        });
        el.on('hide.bs.collapse', function () { });
      })
      .addClass('attached-force-collapse');

    // Handle auto opening of links in tab panels
    block
      .find('[data-toggle="tab"]')
      .not('.attached-tab-show')
      .on('show.bs.tab', function () {
        $($(this).attr('href')).find('a.on-show-auto-click').not('.auto-clicked').addClass('auto-clicked').click();
      })
      .addClass('attached-tab-show');

    // Handle auto opening of links in tab panels when the initial panel is already open
    block
      .find('[data-toggle="tab"][aria-expanded="true"]')
      .not('.attached-tab-init')
      .each(function () {
        $($(this).attr('href')).find('a.on-show-auto-click').not('.auto-clicked').addClass('auto-clicked').click();
      })
      .addClass('attached-tab-init');

    block
      .find('[data-add-icon]')
      .not('.attached-add-icon')
      .each(function () {
        var icon = $(this).attr('data-add-icon');
        var title = $(this).attr('title');
        $(this).attr('title', null);

        var action = $(this).attr('data-show-modal');

        if (action) {
          var h = $(
            '<a class="add-icon glyphicon glyphicon-' + icon + '" href="#" data-show-modal="' + action + '"></a>'
          );
          $(this).append(h);
          h.click(function (ev) {
            ev.preventDefault();
            var id = $(this).attr('data-show-modal');
            _fpa.show_modal($(id).html(), title);
          });
        } else {
          var h = $(
            `<a data-toggle="popover" data-content="${title}" class="add-icon glyphicon glyphicon-${icon}"></a>`
          );
          $(this).append(h);
          h.popover({ trigger: 'hover click', placement: 'bottom' });
        }
      })
      .addClass('attached-add-icon');

    _fpa.form_utils.sort_blocks(block);

    //block.updatePolyfill();

    block
      .find('input,select,checkbox,textarea')
      .not('[type="submit"],.form-control,.ff')
      .addClass('form-control input-sm ff');
    block.find('.typeahead').css({ width: '100%' });
    block.find('form').not('.form-formatted').addClass('form-inline');

    block
      .find('textarea.auto-grow')
      .not('.attached-auto-grow')
      .each(function () {
        $(this).on('keypress, change', function () {
          $(this).get(0).style.height = '5px';
          $(this).get(0).style.height = $(this).get(0).scrollHeight + 5 + 'px';
        });
      })
      .addClass('attached-auto-grow');

    block
      .find('input.college-input.typeahead')
      .not('.attached-college_ta')
      .addClass('attached-college_ta')
      .each(function () {
        var el = $(this);
        _fpa.cache.get_definition('colleges', function () {
          _fpa.form_utils.setup_typeahead(el, 'colleges', 'colleges');
        });
      });

    block
      .find('[data-format-date-local="true"]')
      .not('.formatted-date-local')
      .each(function () {
        var text = $(this).html();
        text = text.replace(' UTC', 'Z').replace(' ', 'T');
        var d = _fpa.utils.YMDtoLocale(text);
        $(this).html(d);
      })
      .addClass('formatted-date-local');

    block
      .find('[data-format-datetime-local="true"]')
      .not('.formatted-datetime-local')
      .each(function () {
        var text = $(this).html();
        text = text.replace(' UTC', 'Z').replace(' ', 'T');
        var d = _fpa.utils.YMDtimeToLocale(text);
        $(this).html(d);
      })
      .addClass('formatted-datetime-local');

    var uc = block.find('.uncollapse-children');
    uc.find('.collapse').collapse('show');
    window.setTimeout(function () {
      _fpa.form_utils.resize_labels(uc);
    }, 200);

    $('a[href$="#open-in-new-tab"], a[href^="mailto:"], a[href^="tel:"]')
      .not('.added-open-nt')
      .each(function () {
        if ($(this).parents('#help-doc-content, .help-doc-content').length) return;
        // Protect against being in an editor
        if ($(this).parents('.edit-as-custom').length) return;

        $(this).attr('target', '_blank');
        if ($(this).find('.glyphicon-new-window').length) return;
        $(this).append(' <i class="glyphicon glyphicon-new-window"></i>');
      })
      .addClass('added-open-nt');

    $('a[href$="#open-in-sidebar"]')
      .not('.added-open')
      .each(function () {
        // Protect against being in an editor
        if ($(this).parents('.edit-as-custom').length) return;

        $(this)
          .attr('target', '_blank')
          .attr('data-remote', 'true')
          .attr('data-toggle', 'uncollapse')
          .attr('data-target', '#help-sidebar')
          .attr('data-working-target', '#help-sidebar-body');

        let href = $(this).attr('href').replace('#open-in-sidebar', '');

        // Prevent the outer page reloading
        $(this).parents('.standalone-page-col').attr('data-no-load', 'true');

        if (href.indexOf('display_as=embedded') < 0) {
          let sym = href.indexOf('?') > 0 ? '&' : '?';
          $(this).attr('href', `${href}${sym}display_as=embedded#open-in-sidebar`);
        }

        $(this).click(function (ev) {
          $('#help-sidebar').collapse('show');
          ev.preventDefault();
        });
      })
      .addClass('added-open');

    $('a[href$="#open-embedded-report"]')
      .not('.added-open-er')
      .each(function () {
        // Protect against being in an editor
        if ($(this).parents('.edit-as-custom').length) return;

        var url = $(this).attr('href');
        url = url.replace('#open-embedded-report', '');
        url = url.replace('embed=true', '');
        if (url.indexOf('?') >= 0) {
          url = `${url}&embed=true#open-embedded-report`;
        } else {
          url = `${url}?embed=true#open-embedded-report`;
        }

        $(this)
          .attr('href', url)
          .attr('data-remote', 'true')
          .attr('data-preprocessor', 'embedded_report')
          .attr('data-parent', 'primary-modal')
          .attr('data-result-target', '#modal_results_block')
          .attr('data-target', '#modal_results_block')
          .attr('data-target-force', 'true');
      })
      .addClass('added-open-er');
  },

  setup_open_tab_before_requests: function (block) {
    block
      .find('a[data-open-tab-before-request]')
      .not('.setup-open-tab-br')
      .each(function () {
        $(this).on('click', function (ev) {
          var elid = $(this).attr('data-open-tab-before-request');
          var tab_el = $(elid);
          if (tab_el.length === 0 || !tab_el.hasClass('collapsed')) return;

          ev.preventDefault();
          $(this).addClass('prevent-first-ajax');

          // Trigger a click on this tab
          tab_el.click();
          // Save the current link
          var click_a = $(this);

          // Attach a post callback to the tab's target panel
          var panel_el = $(tab_el.attr('data-target'));
          panel_el[0].app_post_callback = function () {
            // Now click the original link again, which will run through the ajax call
            // and then quit because the panel is not collapsed
            click_a.click();
          };
        });
      })
      .addClass('setup-open-tab-br');
  },

  setup_drag_and_drop: function (block) {
    block
      .find('.make-sortable')
      .not('.made-sortable')
      .each(function () {
        var $this = $(this);
        var $sortable_block = $(this).find('.sortable-block');
        var $sortable_block_trash = $(this).find('.sortable-block-trash');

        var get_data_from = $sortable_block.attr('data-get-data-from');
        var items_as = $sortable_block.attr('data-items-as') || 'li';
        var items_splitter = $sortable_block.attr('data-items-splitter') || ' ';

        if (get_data_from) {
          var $get_data_from = $(get_data_from);

          var add_item = function (item) {
            var $new_item = $(`<${items_as} data-field-name="${item}">${item}</${items_as}>`);
            $sortable_block.append($new_item);
          };

          var refresh_from_orig_data = function () {
            var items = $get_data_from.val().split(/[^a-zA-Z0-9_]+/);
            $sortable_block.html('');
            for (var i in items) {
              var item = items[i];
              if (!item || item.trim() == '') continue;
              add_item(item);
            }
          };

          refresh_from_orig_data();

          $get_data_from.on('blur', function () {
            refresh_from_orig_data();
          });
        }

        var refresh_orig_data = function () {
          var texts = [];
          $sortable_block.find(items_as).each(function () {
            // Get the first text element only
            texts.push($(this).contents().first().text());
          });
          $get_data_from.val(texts.join(items_splitter));
        };

        Sortable.create($sortable_block[0], {
          group: {
            name: 'list',
            put: ['trash'],
          },
          onUpdate: function (ev) {
            refresh_orig_data();
          },
          onRemove: function (ev) {
            refresh_orig_data();
          },
        });

        Sortable.create($sortable_block_trash[0], {
          group: {
            name: 'trash',
            put: ['list'],
          },
        });

        var $item_val_add = $this.find('.sortable-add-item-text');
        $item_val_add_btn = $this.find('.sortable-add-item');
        $item_val_add_btn.on('click', function () {
          var val = $item_val_add.val();
          if (!val || val.trim() == '') return;

          add_item(val);
          $item_val_add.val('');
          refresh_orig_data();
        });

        $item_val_add.on('keypress', function (ev) {
          if (ev.keyCode == 13) $item_val_add_btn.trigger('click');
        });
      })
      .addClass('made-sortable');
  },

  setup_sub_lists: function (block) {
    block
      .find('.sublist-filter-selectors')
      .not('.formatted-slfs')
      .each(function () {
        $(this).on('click', '.filter-switch', function (ev) {
          ev.preventDefault();
          _fpa.form_utils.handle_sub_list_filters($(this));
        });

        $(this)
          .find('.filter-switch')
          .each(function () {
            _fpa.form_utils.handle_sub_list_filters($(this), true);
          });

        $(this).on('click', '.filter-switch-all', function (ev) {
          if ($(this).hasClass('filter-all-active')) {
            $(this).parent().find('.filter-switch').not('.active').click();
            $(this).removeClass('filter-all-active');
            $(this).removeClass('glyphicon-plus');
            $(this).addClass('glyphicon-minus');
          } else {
            $(this).parent().find('.filter-switch.active').click();
            $(this).addClass('filter-all-active');
            $(this).addClass('glyphicon-plus');
            $(this).removeClass('glyphicon-minus');
          }
        });
      })
      .addClass('formatted-slfs');

    block
      .find('.sublist-order-selector')
      .not('.formatted-slfs')
      .each(function () {
        $(this).on('click', '.order-switch', function (ev) {
          ev.preventDefault();
          _fpa.form_utils.handle_sub_list_order($(this));
        });
      })
      .addClass('formatted-slfs');

    block
      .find('.sublist-layout-selectors')
      .not('.formatted-slfs')
      .each(function () {
        $(this).on('click', '.layout-switch', function (ev) {
          ev.preventDefault();
          _fpa.form_utils.handle_sub_list_layout($(this));
        });
      })
      .addClass('formatted-slfs');
  },

  setup_contact_field_mask: function (block) {
    var check_rec = function (rec_type, input) {
      if (typeof rec_type == 'string') {
        var val = rec_type;
        var no_rec_type = true;
      } else {
        var val = rec_type.val();
        input = block.find('input[data-attr-name="data"]');
      }

      if (val === 'phone') {
        input
          .mask('(000)000-0000 nn', {
            translation: { 0: { pattern: /\d/ }, n: { pattern: /.*/, recursive: true, optional: true } },
          })
          .attr('type', 'text');
      } else if (val === 'email') {
        input.unmask().attr('type', 'email');
      } else input.unmask().attr('type', 'text');

      if (!no_rec_type) {
        var data_label = _fpa.utils.translate(val, 'field_labels');
        data_label = data_label ? _fpa.utils.capitalize(data_label) : 'Data';

        input.parent().find('label').not('.radio-label').html(data_label);
      }
    };

    var e = block.find('.rec_type_has_phone, .rec_type_has_email').change(function () {
      check_rec($(this));
    });

    check_rec(e);

    block.find('.is_phone').each(function () {
      check_rec('phone', $(this));
    });

    block.find('.is_email').each(function () {
      check_rec('email', $(this));
    });
  },

  setup_textarea_autogrow: function (block) {
    block.find('textarea').each(function () {
      var textarea = $(this)[0];
      textarea.style.resize = 'none';
      textarea.style.boxSizing = 'content-box';

      const $td = $(this).parent('td');
      if ($td.length) {
        const h = $td.height();
        $(this).css({ minHeight: `${h}px` });
      }

      $(this).on('click focus', function () {
        if ($(this).hasClass('done-auto-grow')) return;

        $(this).addClass('done-auto-grow');
        var growingTextarea = new Autogrow(textarea);
        growingTextarea.autogrowFn();
      }).on('blur', function () {
        $(this).removeClass('done-auto-grow');
      });
    });

    setTimeout(function () {
      var notes = block.find(
        '.notes-block .list-group-item strong, .notes-block  .panel-body, .al-shrinkable > ul.list-group'
      );
      _fpa.utils.make_readable_notes_expandable(notes, 100, _fpa.form_utils.resize_children);
    }, 10);
  },

  setup_textarea_editor: function (block) {
    _fpa.custom_editor.setup(block);
  },

  setup_filestore: function (block) {
    block
      .find('.browse-container')
      .not('.nfs-store-setup')
      .each(function () {
        var inblock = $(this);

        // Setup secure-view for the block
        var usv = $(this).attr('data-container-use-secure-view');
        if (!(usv == null || usv == '' || usv == 'false' || usv == 'download_files')) {
          var acts = {};
          var usvitems = usv.split(',');
          for (var k in usvitems) {
            acts[usvitems[k]] = true;
          }

          var spa = null;
          if (usvitems.indexOf('view_files_as_image') >= 0) spa = 'png';
          else if (usvitems.indexOf('view_files_as_html') >= 0) spa = 'html';

          var fn = $(this).html();

          _fpa.secure_view.setup_links($(this), 'a.browse-icon', {
            allow_actions: acts,
            set_preview_as: spa,
            attr_for_filename: 'title',
            link_type: 'icon',
          });
          _fpa.secure_view.setup_links($(this), 'a.browse-filename', { allow_actions: acts, set_preview_as: spa });
          _fpa.secure_view.setup_links($(this), 'a.browse-entry-classifications', {
            allow_actions: acts,
            set_preview_as: spa,
            link_type: 'classifications',
          });
        }
        if (usv == null || usv == '' || usv == 'false') {
          $(this)
            .find('a.browse-filename, a.browse-icon, a.browse-entry-classifications')
            .on('click', function (ev) {
              ev.preventDefault();
            });
        }

        window.setTimeout(function () {
          inblock.find('.refresh-container-list').click();
          (inblock.nfs_store_uploader = _nfs_store.uploader)(inblock);
        }, 10);
      })
      .addClass('nfs-store-setup');
    // Initialize the nfs_store browser and uploader
  },

  setup_e_signature: function (block, force) {
    _fpa.e_signature.setup(block, force);
  },

  setup_error_clear: function (block) {
    block.on('change', '.has-error .form-control', function () {
      var p = $(this).parent();
      p.removeClass('has-error');
      p.find('.error-help').remove();
    });
  },

  resize_children: function (block, doNow) {
    var doResize = function () {
      var curr_top = -1;
      var maxh = -1;

      var ob = block.parents('.resize-children').parent();
      if (ob.length > 0) {
        block = ob;
      }

      block.find('.resize-children').each(function () {
        $(this)
          .find('ul.list-group')
          .each(function () {
            if ($(this).parents('ul.list-group').length == 0) {
              var cs = $(this).first();
              cs.parent().css({ minHeight: '1px' });
            }
          });

        // Set the column width classes based on the content
        $(this)
          .find('.common-template-item, .new-block')
          .not('.resized-width, .model-reference-new-block')
          .each(function () {
            var me = $(this);
            var dc = $(this).parents('.dynamic-container');
            if (dc.length > 0) me = dc;

            var has_dialog = me.find('.in-form-dialog').length > 0;
            var has_e_sign = me.find('#e_signature_document').length > 0;
            var cap_items = me.find('.list-group-item.caption-before, .list-group-item.dialog-before');
            if (!has_e_sign && cap_items.length == 0) return;
            var visible_cap = cap_items.filter(':visible');
            if (visible_cap && visible_cap.length > 0) {
              var cap_height =
                visible_cap.last().position().top +
                visible_cap.last().outerHeight() -
                visible_cap.first().position().top;
            } else {
              cap_height = 0;
            }

            if (cap_height > 800 || has_dialog || has_e_sign) {
              var c = _fpa.layout.item_blocks.regular;
              var max_h = 0;
              cap_items.each(function () {
                var curr_h = $(this).height();
                if (curr_h > max_h) max_h = curr_h;
              });
              if (max_h > 60 || has_dialog || has_e_sign) {
                if (has_e_sign) {
                  c = _fpa.layout.item_blocks.e_signature;
                } else {
                  c = _fpa.layout.item_blocks.wide;
                }
                me.first().removeClass(_fpa.layout.item_blocks.regular);
                me.addClass(c).addClass('resized-width');
                _fpa.form_utils.resize_labels(me, null, true);
              } else {
                if (me.hasClass('new-block')) {
                  me.first().removeClass(_fpa.layout.item_blocks.wide);
                  me.first().removeClass(_fpa.layout.item_blocks.e_signature);
                  me.addClass(_fpa.layout.item_blocks.regular);
                }
              }
            }
          });
      });

      block.find('.resize-children').each(function () {
        // run through all the candidate items
        var cs = $(this).find('ul.list-group');
        cs.each(function () {
          if ($(this).parents('ul.list-group').length > 0) return;
          var el = $(this).parent();

          // attempt to resize row by row if there is overflow
          // so, if the top of this item is lower, resize the height of
          // the recent items that are marked ready to resize,
          // then reset the maxh variable to start again.
          if (el.offset().top > curr_top) {
            if (maxh > 1) var inc = 0;
            // to resize the items go through each
            // add a small increment to each item, to ensure that subpixel issues
            // don't lead to errors
            block.find('.ready-to-resize').each(function () {
              $(this)
                .removeClass('ready-to-resize')
                .css({ minHeight: maxh + inc });
              inc++;
            });
            maxh = 1;
            curr_top = el.offset().top;
          }

          // get the height of this item and see if it is larger
          // also set a class ready-to-resize that keeps this group of items
          // together when resizing just a row
          var h = el.addClass('ready-to-resize').height();
          if (h > maxh) maxh = h;
        });
        // finally, handle the remaining items
        if (maxh > 1) block.find('.ready-to-resize').removeClass('ready-to-resize').css({ minHeight: maxh });
      });
    };

    if (doNow) {
      doResize();
    } else {
      window.setTimeout(function () {
        doResize();
      }, 100);
    }
  },

  // If all children are not visible, add a class that allows this block to be hidden or styled
  hide_empty_blocks: function (block) {
    block.find('.hide-if-children-invisible').each(function () {
      if ($(this).find(':visible').length == 0) {
        $(this).addClass('all-children-invisible');
        $(this).removeClass('some-children-visible');
      } else {
        $(this).removeClass('all-children-invisible');
        $(this).addClass('some-children-visible');
      }
    });
  },

  set_auth_tokens: function (block) {
    var csrf_token = $('head meta[name="csrf-token"]').attr('content');
    $('input.set-auth-token[type="hidden"]').val(csrf_token);
  },

  set_image_classes: function (block) {
    block
      .find('img')
      .on('error', function () {
        $(this).addClass('broken-image').removeClass('image-to-load');
      })
      .on('load', function () {
        $(this).addClass('loaded-image').removeClass('image-to-load');
      })
      .addClass('image-to-load');
  },

  // Check for changes and handle prompt to save
  setup_change_handling: function (block) {
    block.find('input, select, textarea').not('.setup-change-handling').on('keypress change', function () {
      $(this).addClass('field-was-changed');
    }).addClass('setup-change-handling');
  },

  // Run through all the general formatters for a new block to show nicely
  format_block: function (block) {
    if (!block) {
      console.log('format_block was provided no block.');
      block = $(document);
    }

    // If the block has a class list-group we have gone one level too deep.
    // Go up to the parent to allow all the following formatters to work
    if (block.hasClass('list-group')) {
      block = block.parent();
    }

    // add an indicator that lengthy formatting is happening
    if (block.hasClass('formatting-block')) return;
    block.addClass('formatting-block');

    _fpa.form_utils.setup_chosen(block);
    _fpa.form_utils.setup_has_value_inputs(block);
    _fpa.form_utils.organize_common_templates(block);
    _fpa.form_utils.resize_labels(block);
    _fpa.form_utils.filtered_selector(block);
    _fpa.form_utils.setup_tablesorter(block);
    _fpa.form_utils.setup_bootstrap_items(block);
    _fpa.form_utils.setup_data_toggles(block);
    _fpa.form_utils.setup_extra_actions(block);
    _fpa.form_utils.setup_datepickers(block);
    _fpa.form_utils.mask_inputs(block);
    _fpa.form_utils.setup_textarea_autogrow(block);
    _fpa.form_utils.setup_textarea_editor(block);
    _fpa.form_utils.setup_contact_field_mask(block);
    _fpa.form_utils.setup_filestore(block);
    _fpa.form_utils.setup_e_signature(block);
    _fpa.form_utils.hide_empty_blocks(block);
    _fpa.form_utils.setup_open_tab_before_requests(block);
    // Not currently used or tested.
    // _fpa.form_utils.setup_form_filtered_select(block);

    _fpa.form_utils.setup_error_clear(block);
    _fpa.form_utils.resize_children(block);
    _fpa.form_utils.setup_sub_lists(block);
    _fpa.form_utils.apply_view_handlers(block);
    _fpa.form_utils.setup_secure_view_links(block);
    _fpa.form_utils.set_auth_tokens(block);
    _fpa.form_utils.set_image_classes(block);
    _fpa.form_utils.setup_big_select_fields(block);
    _fpa.form_utils.setup_select_filtering(block);
    _fpa.form_utils.setup_change_handling(block);

    block.removeClass('formatting-block');
  },
};
