// Handle templates for the report admin page.
// Relies on ReportSearchAttr(s) classes for 
// report criteria field configuration parsing and dumping to YAML.

_fpa.postprocessors_report_admin = {

  handle_admin_report_config: function (block) {

    // Set up codemirror text editors
    _fpa.form_utils.setup_textarea_editor(block)
    ReportSearchAttrsUi.setup_search_attrs(block);
  }
};
$.extend(_fpa.postprocessors, _fpa.postprocessors_report_admin);
