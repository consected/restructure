_fpa.loaded.imports = function () {
  $('#import_file').on('change', function () {
    $('#upload-message').html('Uploading file');
    $('#import_file').hide();
    $('#new_import').trigger('submit.rails');
  })

}

_fpa.loaded.model_generators = function () {
  $(document).on('change', '#import_file', function () {
    $('#upload-message').html('Uploading file');
    $('#import_file').hide();
    $('#new_import').trigger('submit.rails');
  })

}