_fpa.preprocessors_page_layouts = {
}

_fpa.postprocessors_page_layouts = {

  // Ensure we have a way to force load_columns on specific blocks
  load_columns: function (block, data) {
    _fpa.page_layouts.load_columns(block)
  },

  // Handle replacing the current page embed main activity logs block with one with a new master
  // if the main result that comes back has a different master. This allows for activity logs
  // that create a new master and move themselves to it to operate without the equivalent
  // save_action.go_to_master, which is a brute force reload of the page.
  page_embed_activity_log_block: function (block, data) {
    if (!block.hasClass('force-logs-container-to-first-master-result')) return;

    var ds;
    for (var e in data) {
      if (data.hasOwnProperty(e) && e != '_control') {
        ds = data[e];
        break;
      }
    }

    if (ds.master_id == null) return;

    const master_id = ds.master_id;
    const lf = block.attr('data-linked-from');
    if (!lf) return;

    const $a = $(lf);
    const href = $a.attr('href');
    const new_href = href.replace(/%5Bmaster_id%5D=[\-0-9]*/, `%5Bmaster_id%5D=${master_id}`)

    if (href === new_href) return;

    $a.attr('href', new_href);
    window.setTimeout(function () {
      $a.click();
    }, 600)
  }

}

$.extend(_fpa.preprocessors, _fpa.preprocessors_page_layouts);
$.extend(_fpa.postprocessors, _fpa.postprocessors_page_layouts);

