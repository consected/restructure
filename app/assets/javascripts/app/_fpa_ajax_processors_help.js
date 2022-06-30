_fpa.postprocessors_help = {
  help_sidebar: function (block, data) {

    // Setup the relative path for the links
    var data_doc_path = block.find('[data-doc-path]').attr('data-doc-path');
    // Extend each anchor tag to be a remote request, to use the relative path
    // rather than the window path, and to request embedded pages.
    block.find('a').each(function () {
      var href = $(this).attr('href')
      if (href[0] == '#') {
        $(this).attr('data-toggle', "scrollto-target");
        return;
      }
      if (href[0] != '/' && href.indexOf('http') != 0 && href.indexOf('mailto:') != 0) {
        href = data_doc_path + '/' + href;
      }
      if (href.indexOf('/help') == 0) {
        $(this).attr('data-remote', 'true')
        $(this).attr('href', href + '?display_as=embedded')
        $(this).attr('data-working-target', '#help-sidebar-body')
      }
      else {
        $(this).attr('target', '_blank');
      }
    });

    // Ensure image tags with relative paths point to the correct location
    block.find('img').each(function () {
      var src = $(this).attr('src')
      if (src[0] != '/' && src.indexOf('http') != 0) {
        src = data_doc_path + '/' + src;
        $(this).attr('src', src)
      }
    });


    block.find('img').on('error', function () {
      $(this).addClass('broken-image')
    }).on('load', function () {
      $(this).addClass('loaded-image')
    });

    if (document.hidden) {
      document.addEventListener('visibilitychange', function () {
        block.find('img').not('.loaded-image').addClass('loaded-image')
      })
    }

    // Add table class to tables
    block.find('table').addClass('table')

    block.find('pre code').each(function () {
      hljs.highlightBlock($(this)[0])
    })

    // Handle the expander
    $('[data-toggle="sidebar-expand"]').not('.toggle-added-sidebar-expander').on('click', function () {
      var target = $(this).attr('data-target');
      $(target).addClass('expanded')
    });

    $('[data-toggle="sidebar-shrink"]').not('.toggle-added-sidebar-shrinker').on('click', function () {
      var target = $(this).attr('data-target');
      $(target).removeClass('expanded')
    });

    var c = $('#help-doc-content')
    _fpa.utils.scrollTo(c, 0, -60, block);

    // Special case when loading a standalone page into the sidebar
    _fpa.page_layouts.load_columns('#help-sidebar-body')

  }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_help);
