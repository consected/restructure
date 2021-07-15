_fpa.admin = {

  index_loaded: function (block) {

    if (!block) block = $('.admin-result-index');

    _fpa.admin.handle_filter_selections(block);


    setTimeout(function () {
      var blocks = $('.shrinkable-block')
      _fpa.utils.make_readable_notes_expandable(blocks, 100);

      $(document).on('change', '#config', function () {
        var ext = $('#config').val().split('.').pop();
        $('input[name="upload_format"]').prop('checked', false);
        $('input[name="upload_format"][value="' + ext + '"]').prop('checked', true);
      })

    }, 10);


  },

  setup_yaml_viewer: function (block) {

    var code_el = block.get(0);
    var mode = block.attr('data-code-editor-type');
    if (!mode) mode = 'yaml';

    var cm = CodeMirror.fromTextArea(code_el, {
      lineNumbers: true,
      mode: mode,
      readOnly: true,
      foldGutter: true,
      gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
    });

    var cme = cm.getWrapperElement();
    cme.style.width = '100%';
    cme.style.height = '100%';
    cme.style.backgroundColor = 'rgba(255,255,255, 0.2)';
    code_el.CodeMirror = cm;
    cm.refresh();

  },

  setup_yaml_editor: function (block) {

    var code_el = block.get(0);
    var mode = block.attr('data-code-editor-type');
    if (!mode) mode = 'yaml';

    var cm = CodeMirror.fromTextArea(code_el, {
      lineNumbers: true,
      mode: mode,
      readOnly: false,
      foldGutter: true,
      gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
    });

    var cme = cm.getWrapperElement();
    cme.style.width = '100%';
    cme.style.height = '100%';
    cme.style.backgroundColor = 'rgb(255,255,255)';
    code_el.CodeMirror = cm;
    cm.refresh();

  },

  handle_filter_selections: function (block) {
    $('#filter-accordion .panel').each(function () {
      var selected = $(this).find('.panel-body a.btn-primary').html();
      var headspace = $(this).find('.panel-heading .panel-title .sel-headspace');

      headspace.html(selected);
    })
  },


};
