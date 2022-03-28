_fpa.postprocessors_model_refs = {
  model_references_item: function (block) {
    var crosses = block.siblings('[data-preprocessor="model_references_item"]');

    _fpa.form_utils.setup_data_toggles(block);
    block.find('a[data-toggle="clear"]').on('click', function () {
      crosses.show();
    })

    crosses.hide();
  },

  // model_references_activity_log__zeus_bulk_message_create_bulk_message_result_template: function (block) {
  //
  // }
};

$.extend(_fpa.postprocessors, _fpa.postprocessors_model_refs);
