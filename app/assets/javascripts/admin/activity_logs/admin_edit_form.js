_fpa_admin.activity_logs.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.activity_logs.admin_edit_form(block, data)

    aef.setup_find_activity()
  }

  setup_find_activity() {
    const $block = this.block;
    $block.find('li.activity-list-name, span.activity-list-name').on('click', function (event) {
      var $this = $(this);
      const $span = $this.find('span.activity-list-name');
      if ($span.length) {
        $this = $span;
      }
      let val = $this.text()

      let el = $block.find('.code-editor')
      let code_el = $(el).get(0);
      let cm = code_el.CodeMirror;
      let cursor = cm.getSearchCursor(new RegExp(`^${val}:`));
      cursor.findNext();
      cm.scrollIntoView({ line: cm.lastLine() })
      cm.setSelection(cursor.from(), cursor.to());
      cm.scrollIntoView({ line: cursor.from().line + 1 })

      // And set the sample form
      $('#extra_log_type').val(val);

      // Style this item
      $block.find('.al-name-selected').removeClass('al-name-selected');
      $this.parents('li').first().addClass('al-name-selected')
      const alib = $this.attr('data-al-elt-block') || $this.parents('[data-al-elt-block]').attr('data-al-elt-block')
      $block.find('.activity-list-item-block.in').collapse('hide');
      $block.find(alib).collapse('show');

      event.stopPropagation();
    })

  }

}