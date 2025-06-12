_fpa.before_send_processors_report_admin = {

  // Before sending the report admin form, base64 encode the SQL field
  // to avoid WAFs from blocking the request.
  // This simply takes the SQL, encodes it and adds a token to the start of the string,
  // so that the server knows to decode it.
  // The encoded string is put back into the textarea. Since the form refreshes from the server
  // response, the original SQL will be displayed back to the user in the code editor.
  report_admin_form(block) {
    const EncodingTokenBase64 = "<Base64Encoded>";
    // Handle Base64 encoding of SQL field

    var $sql_field = block.find('textarea[name="report[sql]"]');
    if ($sql_field.length > 0) {

      var sql_value = $sql_field.val();
      if (sql_value) {
        // Encode the SQL value in Base64 and add a token
        const send_val = `${EncodingTokenBase64}${btoa(sql_value)}`
        $sql_field.val(send_val);
      }
    }
  }
}

Object.assign(_fpa.before_send_processors, _fpa.before_send_processors_report_admin)
