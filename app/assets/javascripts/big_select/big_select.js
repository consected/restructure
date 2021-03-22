$.big_select = function ($field, $target, hash, before, after) {

  var setup_with = function (hash, $target, value) {
    var res = $target.append(`<div class="big-select"></div>`);
    for (var k of Object.keys(hash)) {
      var val = hash[k]
      var selected_class = (value == k) ? 'bsi-selected' : ''
      var html = `
    <div class="big-select-item ${selected_class}" data-bsi-key="${k}">
      <div class="bsi--head">${k}</div>
      <div class="bsi--body">${val}</div>
    </div>
    `
      res.append(html)
    }

    return res
  }

  var set_info = function (init_val) {
    if (!init_val) return
    $desc.attr('title', 'show definition')
    $desc.attr('data-content', hash[init_val]);
  }

  var res
  var init_val = $field.val()

  var $field_parent = $field.parent()
  var $desc = $field_parent.find('.big-select-description')

  $desc.popover({ trigger: 'click hover' });
  set_info(init_val)



  $field.on('focus', function () {
    if (before) before()

    res = setup_with(hash, $target, $field.val());

    res.on('click', '.big-select-item', function () {
      var val = $(this).attr('data-bsi-key')
      $field.val(val)
      set_info(val)
      if (after) after()
    })
  })

}