_fpa.admin = {

  index_loaded: function (block) {

    if (!block) block = $('.admin-result-index');

  },

  setup_yaml_viewer: function(block) {

    var code_el = block.get(0);
    var mode = block.attr('data-code-editor-type');
    if(!mode) mode = 'yaml';

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

  }


};
