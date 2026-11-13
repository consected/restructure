_fpa_admin.reports.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.reports.admin_edit_form(block, data)

    aef.setup_auto_options_visibility()

    // Set up codemirror text editors
    _fpa.form_utils.setup_textarea_editor(block)
    // Run at next step to avoid UI lock ups
    window.setTimeout(function () {
      aef.setup_search_attr_config();
    })
  }


  setup_auto_options_visibility() {
    const $reportType = this.block.find('select[name$="[report_type]"]');
    const $autoOptions = this.block.find('.report-auto-options');
    if (!$reportType.length || !$autoOptions.length) return;

    const updateVisibility = () => $autoOptions.toggleClass('hidden', $reportType.val() === 'report');
    $reportType.off('change.report-auto-options').on('change.report-auto-options', updateVisibility);
    updateVisibility();
  }

  // Handle templates for the report admin page.
  // Relies on ReportSearchAttr(s) classes for 
  // report criteria field configuration parsing and dumping to YAML.
  setup_search_attr_config() {
    var block = this.block

    ReportSearchAttrsUi.setup_search_attrs(block);
  }

}
