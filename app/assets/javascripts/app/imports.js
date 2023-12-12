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
    $('.dynamic-details-fields').hide();
    $('#import_file').hide();

    $('#analyze_csv_form_res').on('load', function () {
      var res = $('#analyze_csv_form_res').contents()
      if (res) {
        if (res[0] && res[0].body && res[0].body.innerText) {
          res = res[0].body.innerText;
        }
        else {
          res = res.text();
        }
      }
      if (res == 'ok') {
        $('#analyze_csv_refresh').trigger('click');
      }
      else {
        $('#upload-message').html('<p class="upload-failed">Failed to evaluate CSV file: ' + res + '</p><p class="upload-failed">Try uploading again</p>');

        $('#import_file').show();
      }
    })

    $('#analyze_csv').trigger('submit.rails');


  })

}