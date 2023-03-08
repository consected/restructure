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
    $block.find('li.activity-list-name').on('click', function () {
      let val = $(this).text()

      let el = $block.find('.code-editor')
      let code_el = $(el).get(0);
      let cm = code_el.CodeMirror;
      let cursor = cm.getSearchCursor(new RegExp(`^${val}:`));
      cursor.findNext();
      cm.scrollIntoView({ line: cm.lastLine() })
      cm.setSelection(cursor.from(), cursor.to());
      cm.scrollIntoView({ line: cursor.from().line + 1 })
    })

  }

}