_fpa_admin.dynamic_models.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.dynamic_models.admin_edit_form(block, data)

    aef.setup_form()
  }

  // Placeholder
  setup_form() {
    var block = this.block

  }


}