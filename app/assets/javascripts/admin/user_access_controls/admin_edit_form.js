_fpa_admin.user_access_controls.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.user_access_controls.admin_edit_form(block, data)

    aef.setup_selectors()
  }

  // For the selection of resource types / names in user access control form
  setup_selectors() {
    var block = this.block
    var _this = this
    this.res_type_changed($('#admin_user_access_control_resource_type'));
    block.on('change', '#admin_user_access_control_resource_type', function () {
      _this.res_type_changed($(this))
    })
  }

  res_type_changed($el) {
    var val = $el.val()

    $('#admin_user_access_control_resource_name').attr('data-big-select-subtype', val)
    $('#admin_user_access_control_access optgroup[label]').hide()
    $('#admin_user_access_control_access optgroup[label="' + val + '"]').show()
  }

}