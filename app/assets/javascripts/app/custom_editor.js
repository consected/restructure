_fpa.custom_editor = class {

  constructor(block) {
    this.$block = block;
  }

  static setup(block) {
    const custom_editor = new _fpa.custom_editor(block);

    block.find('.custom-editor-container').not('.edit-as-custom-setup').each(function () {
      const $this = $(this)
      custom_editor.setup_editor_container($this)
      custom_editor.setup_image_list($this)
    }).addClass('edit-as-custom-setup');
  }

  setup_editor_container($this) {
    if ($this.hasClass('edit-as-markdown')) {
      var $edta = $this.find('textarea.text-notes');
      var $eddiv = $this.find('div.custom-editor');
      var edid = $eddiv.attr('id');
      var $edtools = $this.find('.btn-toolbar[data-target="#' + edid + '"]');
      var editor = $eddiv.wysiwyg({ dragAndDropImages: true });
      var wysiwygEditor = editor.wysiwygEditor;

      $edtools.hide();
      $eddiv.on('focus', function () {
        // Protect against link dialog form being open, to avoid losing the selection
        if ($(this).parent().find('.btn-group.open').length) return;

        $('.custom-editor-container .btn-toolbar').not("[data-target='" + $edtools.attr('data-target') + "']").hide();
        $edtools.slideDown();

        if (_fpa.state.previous_wysiwyg_editor == editor) {
          wysiwygEditor.restoreSelection()
        }
        else {
          _fpa.state.previous_wysiwyg_editor = editor
        }

      }).on('change', function () {
        $eddiv.data('editor-changed', true);
        wysiwygEditor.saveSelection()
      }).on('blur', function () {
        wysiwygEditor.saveSelection()

      }).on('paste', function () {
        window.setTimeout(function () {
          var obj = { html: editor.cleanHtml() };
          var prev_html = obj.html;
          var txt = _fpa.utils.html_to_markdown(obj);

          if (prev_html != obj.html) {
            editor.html(obj.html);
          }

          $edta.val(txt);
          $eddiv.data('editor-changed', null);
        }, 100);

      });

      // Setup periodic parsing of the html if there have been changes to the editor
      var autoparse = function () {
        if ($eddiv.length && $edta.length) {
          if ($eddiv.data('editor-changed')) {
            // Only if there has been a change
            $eddiv.data('editor-changed', null);


            var obj = { html: editor.cleanHtml() };
            var txt = _fpa.utils.html_to_markdown(obj);

            $edta.val(txt);
          }

          window.setTimeout(function () {
            autoparse();
          }, 500);
        }
      };

      window.setTimeout(function () {
        autoparse();
      }, 500);
    }
  }

  setup_image_list($this) {

    const $bg_input = $this.find('input[name="imglist"]');
    const $bg_input_overlay = $this.find('input[name="big_select_overlay"]');
    const $bg_button = $this.find('.btn-editor-add-image')
    const $ed_field = $this.find('input[data-edit="insertImage"]')
    $bg_input_overlay.attr('placeholder', 'select')

    $bg_input.on('change', () => {
      const prev_val = $ed_field.val();
      const new_val = $bg_input.val();
      if (new_val === prev_val) return;

      $ed_field.val(new_val).change();
      $bg_button.click();
      window.setTimeout(() => {
        $bg_input.val('');
        $bg_input_overlay.val('');
      })
    })
  }
}
