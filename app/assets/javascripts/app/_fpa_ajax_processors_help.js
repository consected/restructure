_fpa.postprocessors_help = {
  help_sidebar: function (block, data) {
    // Setup the relative path for the links
    var data_doc_path = block.find('[data-doc-path]').attr('data-doc-path');
    // Extend each anchor tag to be a remote request, to use the relative path
    // rather than the window path, and to request embedded pages.
    block.find('a')
      .on('click', function () {
        const href = $(this).attr('href');
        $('#help-sidebar').attr('data-to-url', href)
      })
      .each(function () {
        var href = $(this).attr('href')
        if (href[0] == '#') {
          $(this).attr('data-toggle', "scrollto-target");
          return;
        }
        if (href[0] != '/' && href.indexOf('http') != 0 && href.indexOf('mailto:') != 0) {
          href = data_doc_path + '/' + href;
        }
        if (href.indexOf('/help') == 0 && href.indexOf('#open-in-new-tab') < 0) {
          $(this).attr('data-remote', 'true')
          if (href.indexOf('display_as=embedded') < 0) {
            if (href.indexOf('?') > 0) {
              href = href.replace('?', '?display_as=embedded&');
            }
            else if (href.indexOf('#') > 0) {
              href = href.replace('#', '?display_as=embedded#');
            }
            else {
              href = `${href}?display_as=embedded`;
            }
            $(this).attr('href', href);
          }
          $(this).attr('data-working-target', '#help-sidebar-body')
        }
        else {
          $(this).attr('target', '_blank');
        }
      });

    // Ensure image tags with relative paths point to the correct location
    block.find('img').each(function () {
      var src = $(this).attr('src');
      if (src[0] != '/' && src.indexOf('http') != 0) {
        src = data_doc_path + '/' + src;
        $(this).attr('src', src);
      }
    });

    block
      .find('img')
      .on('error', function () {
        $(this).addClass('broken-image');
      })
      .on('load', function () {
        $(this).addClass('loaded-image');
      });

    if (document.hidden) {
      document.addEventListener('visibilitychange', function () {
        block.find('img').not('.loaded-image').addClass('loaded-image');
      });
    }

    // Add table class to tables
    block.find('table').addClass('table');

    block.find('pre code').each(function () {
      hljs.highlightBlock($(this)[0]);
    });

    // Handle the expander
    $('[data-toggle="sidebar-expand"]')
      .not('.toggle-added-sidebar-expander')
      .on('click', function () {
        var target = $(this).attr('data-target');
        $(target).addClass('expanded');
      });

    $('[data-toggle="sidebar-shrink"]')
      .not('.toggle-added-sidebar-shrinker')
      .on('click', function () {
        var target = $(this).attr('data-target');
        $(target).removeClass('expanded');
      });

    const to_url = $('#help-sidebar').attr('data-to-url');
    if (to_url) {
      var hash_pos = to_url.indexOf('#');
    }
    if (hash_pos && hash_pos > 0) {
      var c = $(to_url.substring(hash_pos));
    }
    else {
      var c = $('#help-doc-content')
    }
    _fpa.utils.scrollTo(c, 0, -60, block);

    // Special case when loading a standalone page into the sidebar
    _fpa.page_layouts.load_columns('#help-sidebar-body');

    block
      .find('.help-embedded-content')
      .not('.spra-setup')
      .on('click', '.standalone-page-row a', function () {
        const $link = $(this);
        const $parent = $link.parents('.standalone-page-row').first();
        var orig_path = $parent.attr('data-req-path');
        if (!orig_path) return;
        var orig_subparts = orig_path.split('/');
        orig_subparts.pop();
        const orig_subpath = orig_subparts.join('/');
        var href = $link.attr('href');

        if (href.indexOf('/content/') == 0 || href.indexOf('/help/') == 0) {
          href = `${href}#open-in-sidebar`;
          var changed = true;
        }

        if (href.indexOf('./') == 0 || href.indexOf('../') == 0 || href.indexOf('/') < 0) {
          href = href.replace(/^\.\//, '');
          href = `${orig_subpath}/${href}#open-in-sidebar`;
          var changed = true;
        }

        if (changed) {
          $link.attr('href', href);
          _fpa.form_utils.setup_extra_actions($parent);
        }
      })
      .addClass('spra-setup');
  },
};
$.extend(_fpa.postprocessors, _fpa.postprocessors_help);
