$.big_select = function ($field, $target, full_hash, before, after) {

  var setup_with = function (hash, $target, selected_value) {
    var $outer = $target.append(`<div class="big-select"></div>`);
    var group_num = 0
    for (var k of Object.keys(hash)) {
      var val = hash[k]

      if (typeof val == 'object') {
        var $group_title_h = $(`
        <div class="big-select-group-head" data-bsi-key="${k}" id="big-select-group-head--${field_parent_id}-${group_num}">
          <a role="button" data-toggle="collapse" data-parent="#${field_parent_id}" class="collapsed"
             href="#big-select-panel--${field_parent_id}-${group_num}" aria-expanded="true" aria-controls="big-select-item--${k}">
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

        for (var k_in of Object.keys(val)) {
          var val_in = val[k_in]
          append_item(k_in, val_in, selected_value, $panel_h)
        }

        group_num++
      }
      else {
        append_item(k, val, selected_value, $outer)
      }

    }

    return $outer
  }

  var append_item = function (k, val, selected_value, $container) {
    var selected_class = (selected_value == k) ? 'bsi-selected' : ''
    var html = `
    <div class="big-select-item ${selected_class}" data-bsi-key="${k}" id="big-select-item--${k}">
      <div class="bsi--head">${k}</div>
      <div class="bsi--body">${val}</div>
    </div>
    `
    $container.append(html)
  }

  var set_info = function (init_val) {
    if (!init_val) return

    var flat_hash = flatten_hash(hash)
    var val = flat_hash[init_val]
    $desc.attr('title', 'show definition')
    $desc.attr('data-content', val);
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
  var res
  var init_val = $field.val()

  var $field_parent = $field.parent()
  var field_parent_id = $field_parent.prop('id')
  var $desc = $field_parent.find('.big-select-description')

  $desc.popover({ trigger: 'click hover' });

  var hash = set_hash(full_hash)
  set_info(init_val)

  $field.on('focus', function () {
    if (before) before()
    $desc.popover('hide')
    hash = set_hash(full_hash)
    if (!hash) return

    res = setup_with(hash, $target, $field.val());

    res.on('click', '.big-select-item', function () {
      var val = $(this).attr('data-bsi-key')
      $field.val(val)
      set_info(val)
      if (after) after()
    })
  })

}