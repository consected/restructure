_fpa.reports_custom_handling.add_handler_implementation('expand_subitems_tree', function () {
  $('table').not('.added-expand_subitems_tree').on('click', 'td[data-col-type="id0"] img[id="state"]', function () {
    const $tr = $(this).parents('tr').first();
    var ttid = $tr.attr('data-tt-id');
    console.log(ttid);
    console.log($tr[0].trChildrenVisible);
    if (!$tr[0].trChildrenVisible) return

    $(`tr[data-tt-parent-id="${ttid}"]`).each(function () {
      const tr = $(this)[0];
      tr.trExpand(true)
    })
  }).addClass('added-expand_subitems_tree');
});  
