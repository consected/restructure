$.big_select = function ($field, $target, full_hash, before, after, options) {

  var setup_with = function (hash, $target, $field) {
    var $outer = $(`<div class="big-select"></div>`).appendTo($target);
    var group_num = 0

    var selected_value = $field.val();
    $outer.called_from_field = $field;

    var main_sorted = sort_option_items(hash);

    for (var [k, val] of main_sorted) {
      var val = hash[k]

      if (typeof val == 'object') {
        var $group_title_h = $(`
        <div class="big-select-group-head" data-bsi-key="${k}" id="big-select-group-head--${field_parent_id}-${group_num}">
          <a role="button" data-toggle="collapse" data-parent="#${field_parent_id}" class="collapsed"
             href="#big-select-panel--${field_parent_id}-${group_num}" aria-expanded="false" aria-controls="big-select-item--${k}">
             <i class="caret"></i> ${k}
          </a>
        </div>`
        )
        $outer.append($group_title_h)

        var $panel_h = $(`
        <div class="collapse" role="tabpanel" aria-labelledby="big-select-group-head--${field_parent_id}-${group_num}" 
        id="big-select-panel--${field_parent_id}-${group_num}"></div>
        `)

        $outer.append($panel_h)

        var sorted = sort_option_items(val);

        for (var [k_in, val_in] of sorted) {
          var val_in = val[k_in]
          append_item(k_in, val_in, selected_value, $panel_h)
        }

        if ($panel_h.find('.bsi-selected').length) {
          $panel_h.addClass('in')
          $group_title_h.find('a').removeClass('collapsed').attr('aria-expanded', 'true')
        }

        group_num++
      }
      else {
        append_item(k, val, selected_value, $outer)
      }

    }
    append_item('big-select-clear', '(none)', selected_value, $outer)
    return $outer
  }

  var sort_option_items = function (val) {
    return Object.entries(val).sort(function (itema, itemb) {
      var a = itema[1];
      var b = itemb[1];
      if (a < b) return -1;
      if (a > b) return 1;
      return 0;
    })
  }

  // Add an item to the list. If "hide_key" option is set, hide the key
  // Then if the label has the string '>>>' split it to show like a key / value
  var append_item = function (k, val, selected_value, $container) {
    var selected_class = (selected_value == k) ? 'bsi-selected' : ''

    var show_k = k;
    if (options.hide_key) {
      show_k = null;

      var split = val.trim().split(/(>>>|\n)/)

      if (split.length > 1) {
        show_k = split[0];
        val = split.slice(1).join("\n");
      }
    }

    var kid = k
    if (show_k == 'big-select-clear') {
      show_k = null
      k = ''
      val = '(none)'
      kid = 'big-select-clear'
    }

    if (!show_k) {
      var html = `
      <div class="big-select-item ${selected_class}" data-bsi-key="${k}" id="big-select-item--${kid}">
        <div class="bsi--head">${val}</div>
      </div>
      `
    }
    else {
      var html = `
      <div class="big-select-item ${selected_class}" data-bsi-key="${k}" id="big-select-item--${kid}">
        <div class="bsi--head">${show_k}</div>
        <div class="bsi--body">${val}</div>
      </div>
      `
    }
    $container.append(html)
  }

  var set_info = function (init_val) {
    if (!init_val) return

    var pre_val = init_val.split(' >>>')[0];

    var flat_hash = flatten_hash(hash)
    var val = flat_hash[pre_val]
    // $desc.attr('title', 'show definition')
    $desc.attr('data-content', val);

    val = val || ''
    $field_overlay.val(val.replace(/\n/g, ' '));
  }


  // Hashes can be simple key : value pairs, or they 
  // can be group : key : value, where the group is essentially disposed of
  var flatten_hash = function (hash) {
    var fh = {}

    for (var k of Object.keys(hash)) {
      var val = hash[k]
      if (typeof val == 'object') {
        for (var k_in of Object.keys(val)) {
          fh[k_in] = val[k_in]
        }
      }
      else {
        fh[k] = val
      }
    }

    return fh
  }

  var set_hash = function (full_hash) {
    var subtype = $field.attr('data-big-select-subtype') || 'big_select_default'
    return full_hash[subtype]
  }

  //
  // Start initialization
  //
  var init_val = $field.val()

  var $field_parent = $field.parent()
  var field_parent_id = $field_parent.prop('id')
  var $desc = $field_parent.find('.big-select-description')

  options = options || {}
  var field_id = $field.prop('id')
  var field_overlay = `#${field_id}---overlay`
  var $field_overlay = $(field_overlay)

  if (!options.hide_popover) {
    $desc.popover({ trigger: 'click hover' });
  }

  var hash = set_hash(full_hash)
  set_info(init_val)

  $field.on('focus', function () {
    if (before) before()
    if (!options.hide_popover) {
      $desc.popover('hide')
    }
    hash = set_hash(full_hash)
    if (!hash) return

    var res = setup_with(hash, $target, $field);

    window.setTimeout(function () {
      _fpa.utils.scrollTo($target.find('.bsi-selected'), 0, -200, $target)
    }, 300)

    res.on('click', '.big-select-item', function () {
      var val = $(this).attr('data-bsi-key')
      var $field = res.called_from_field
      $field.val(val)
      set_info(val)
      if (after) after()
    })
  })

}