_fpa_admin.reports.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.reports.admin_edit_form(block, data)

    // Set up codemirror text editors
    _fpa.form_utils.setup_textarea_editor(block)
    aef.setup_search_attr_config()
  }

  // Handle templates for the report admin page.
  // Relies on ReportSearchAttr(s) classes for 
  // report criteria field configuration parsing and dumping to YAML.
  setup_search_attr_config() {
    var block = this.block

    ReportSearchAttrsUi.setup_search_attrs(block);
  }

}