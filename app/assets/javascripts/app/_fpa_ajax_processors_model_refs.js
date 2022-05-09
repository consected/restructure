_fpa.preprocessors_model_refs = {

  dynamic_block_references: function (block, data) {
    var ds;
    if (data.multiple_results) {
      ds = data[data.multiple_results]
    }
    else {
      for (var e in data) {
        if (data.hasOwnProperty(e) && e != '_control') {
          ds = [data[e]];
          break;
        }
      }
    }

    if (!ds || !ds.model_references) return;


    /* Decide whether to show a model reference as embedded or in a list */
    for (var i = 0; i < ds.length; i++) {
      var d = ds[i];
      var no_creatable_references;
      if (d.creatable_model_references) {
        no_creatable_references = true;
        var cr0 = null;
        for (var p in d.creatable_model_references) {
          if (d.creatable_model_references.hasOwnProperty(p) && d.creatable_model_references[p]) {
            for (var p1 in d.creatable_model_references[p]) {
              if (d.creatable_model_references[p].hasOwnProperty(p1)) {
                no_creatable_references = d.creatable_model_references[p][p1] != 'many';
              }
            }
          }
        }
      }

      d._show_embedded_as_single_item = (d.model_references && d.model_references.length == 1 && no_creatable_references);
    }
  }



};

_fpa.postprocessors_model_refs = {
  model_references_item: function (block) {
    var crosses = block.siblings('[data-preprocessor="model_references_item"]');

    _fpa.form_utils.setup_data_toggles(block);
    block.find('a[data-toggle="clear"]').on('click', function () {
      crosses.show();
    })

    crosses.hide();
  },

}

$.extend(_fpa.preprocessors, _fpa.preprocessors_model_refs);
$.extend(_fpa.postprocessors, _fpa.postprocessors_model_refs);
