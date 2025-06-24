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
  static encode_options_field($options_field) {
    const EncodingTokenBase64 = "<Base64Encoded>";
    if ($options_field.length > 0) {

      var options_value = $options_field.val();
      if (options_value) {
        // Encode the options value in Base64 and add a token
        const send_val = `${EncodingTokenBase64}${Base64.encode(options_value)}`
        $options_field.val(send_val);
      }
    }
  }
}