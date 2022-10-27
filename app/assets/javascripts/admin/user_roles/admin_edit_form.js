_fpa_admin.user_roles.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.user_roles.admin_edit_form(block, data)

    aef.setup_role_name()
  }

  // Setup role name typeahead field
  setup_role_name() {
    var block = this.block

    block.find('#admin_user_role_role_name').not('.added-user-role-typeahead').each(function () {
      var el = $(this);
      _fpa.cache.get_definition('user_roles', function () {
        _fpa.form_utils.setup_typeahead(el, 'user_roles', "user_roles", 50);
      });
    }).addClass('added-user-role-typeahead');

  }


}