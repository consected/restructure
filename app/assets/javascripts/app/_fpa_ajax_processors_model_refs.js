_fpa.postprocessors_model_refs = {
  model_references_item: function (block) {
    _fpa.form_utils.setup_data_toggles(block);
  },

  // model_references_activity_log__zeus_bulk_message_create_bulk_message_result_template: function (block) {
  //
  // }
};

$.extend(_fpa.postprocessors, _fpa.postprocessors_model_refs);
