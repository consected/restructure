_fpa.before_send_processors_report_admin = {

  // Before sending the report admin form, base64 encode the SQL field
  // to avoid WAFs from blocking the request.
  // This simply takes the SQL, encodes it and adds a token to the start of the string,
  // so that the server knows to decode it.
  // The encoded string is put back into the textarea. Since the form refreshes from the server
  // response, the original SQL will be displayed back to the user in the code editor.
  report_admin_form(block) {
    const $options_field = block.find('textarea[name="report[sql]"]');
    _fpa_admin.form_utils.encode_options_field($options_field)
  }
}

Object.assign(_fpa.before_send_processors, _fpa.before_send_processors_report_admin)
