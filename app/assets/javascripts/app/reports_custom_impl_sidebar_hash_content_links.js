// Report results handler for opening documentation within the sidebar
_fpa.reports_custom_handling.add_handler_implementation('sidebar_hash_content_links', function () {

  const $block = this.$block;
  window.setTimeout(function () {

    const target = "table td[data-col-type] a[href^='/content']";
    $(target).each(function (ev) {
      let href = $(this).attr('href');

      $(this)
        .attr('target', '_blank')
        .attr('data-remote', 'true')
        .attr('data-toggle', 'uncollapse')
        .attr('data-target', '#help-sidebar')
        .attr('data-working-target', '#help-sidebar-body')
        .attr('data-orig-href', href);

      // Prevent the outer page reloading
      $(this).parents('.standalone-page-col').attr('data-no-load', 'true');
    })

    $block.on('click', target, function (ev) {
      let href = $(this).attr('href');
      let hash = href.split('#')[1];
      if (hash) hash = `#${hash}`;
      $('#help-sidebar').collapse('show').attr('data-onload-scrollto', hash);
      ev.preventDefault();
    });
  }, 500);
});


