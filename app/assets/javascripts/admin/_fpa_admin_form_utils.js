// Provide a namespace for admin classes
var _fpa_admin = {
  all: {},
  activity_logs: {},
  dynamic_models: {},
  external_identifiers: {},
  reports: {},
  user_access_controls: {},
  user_roles: {}
}

_fpa_admin.form_utils = class {
  // Handle Base64 encoding of options field
  // Ensures CodeMirror content is saved to the textarea before encoding,
  // which is critical when the user has edited the CodeMirror editor
  // but the content hasn't been synced back to the underlying textarea
  static encode_options_field($options_field) {
    const EncodingTokenBase64 = "<Base64Encoded>";
    if ($options_field.length > 0) {
      // Sync CodeMirror content to the textarea before reading
      var options_el = $options_field.get(0);
      if (options_el && options_el.CodeMirror) {
        options_el.CodeMirror.save();
      }

      var options_value = $options_field.val();
      if (options_value) {
        // Encode the options value in Base64 and add a token
        const send_val = `${EncodingTokenBase64}${Base64.encode(options_value)}`
        $options_field.val(send_val);
      }
    }
  }
}