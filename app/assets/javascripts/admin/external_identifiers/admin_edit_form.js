_fpa_admin.external_identifiers.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.external_identifiers.admin_edit_form(block, data)

    aef.setup_id_attribute_naming()

  }

  // If the attribute id field name hasn't already been set up,
  // create a default one using the provided table name
  setup_id_attribute_naming() {
    var block = this.block

    block.find('input#external_identifier_name').not('.name-click-setup').on('change blur', function () {
      console.log('sss')
      var val = $(this).val()
      var $id_field = block.find('input#external_identifier_external_id_attribute')
      var id_val = $id_field.val()

      if (id_val || !val) return

      id_val = `${val.singularize().underscore()}_ext_id`
      $id_field.val(id_val)
    }).addClass('name-click-setup')

  }

}