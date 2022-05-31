"use strict";

/*
   Setup the viewer like this:

      var sv = new SecureView;
      sv.setup("<%= request.path %>", "<%= @secure_view_preview_as %>");
 */

var SecureView = function () {
  var _this = this;

  this.init = function () {
    this.app_specific = null;
    this.page_count = 0;
    this.preview_as = null;
    this.current_page = 1;
    this.current_zoom = '';
    this.get_page_path = '';
    this.download_path = '';
    this.search_path = '';
    this.allow_actions = {};
    this.initial_html_overflow = null;
    this.initial_body_overflow = null;

    this.$owner_el = null;
    this.$secure_view = null;
    this.$pages_block = null;
    this.$preview_as_selector = null;
    this.$zoom_factor_selector = null;
    this.$page_controls = null;
    this.$zoom_selectors = null;
    this.$loading_page_message = null;
    this.$download_link = null;
    this.$no_preview_possible = null;
    this.$failure_message_block = null;
    this.$failure_message = null;
    this.$control_blocks = null;
    this.$zoom_selector_fit = null;
    this.$extra_actions = null;
    this.$download_actions = null;
    this.$search_panel = null;
    this.$search_form = null;
    this.$search_results = null;
    this.$pages = null;
    this.$preview_item = null;
    this.$body = null;
    this.html = null;

    this.page_defaults = {
      overflow: 'hidden',
      display: 'block'
    }
    this.last_scroll_event_date = 0;
    this.last_keypress_date = 0;
    this.last_scroll_to_date = 0;
  };

  this.init();

  // This function can be called multiple times to set a different context for each container / block
  this.setup_links = function (block, link_selector, options) {
    var _this = this;

    options = options || {};
    var done_cname = 'sv-added-setup-links' + (options.link_type || '');

    if (block && link_selector) {
      $(block).not('.' + done_cname).on('click', link_selector, function (ev) {

        options.page_path = $(this).attr('href');

        options.$owner_el = block;

        var fn;
        if (options.attr_for_filename) {
          fn = $(this).attr(options.attr_for_filename);
        }
        else {
          fn = $(this).html();
        }

        options.file_name = fn;

        $('.sv-selected').removeClass('sv-selected');
        $(this).parent().addClass("sv-selected");

        _this.setup(options.set_preview_as, options);
        ev.preventDefault();
      }).addClass(done_cname);
    }
  }

  this.setup_search = function () {
    console.log('setup search')
    this.search_path = (this.download_path || '').replace('?', '/search_doc?');
    this.$search_form.attr('action', this.search_path);
    var $search_results = this.$search_results;

    this.$search_form.not('.sv-search-form-setup').on('submit', function (ev) {
      ev.preventDefault();
      var block = $(this);

      var action = $(this).attr('action');

      $search_results.find('.sv-search-results-count').remove();

      if (!action) {
        _this.show_failure_message('Error: no document path set to search');
        return;
      }

      var search_string = $(this).find('[name="search_string"]').val().trim();
      $search_results.html('');

      if (!search_string) return;

      _fpa.ajax_working(block);
      var last_response_len = false;
      var response_count = 0;
      // Run the search and enter each line into the search results block as it is returned
      $.ajax(action, {
        data: { search_string: search_string },
        xhrFields: {
          onprogress: function (e) {
            if (response_count > 200) return;

            var this_response, response = e.currentTarget.response;
            if (last_response_len === false) {
              this_response = response;
              last_response_len = response.length;
            }
            else {
              this_response = response.substring(last_response_len);
              last_response_len = response.length;
            }

            var new_responses = this_response.split("\n")
            for (var i in new_responses) {
              var res = new_responses[i]
              var res_parts = res.split(':');
              var text = res_parts.slice(1).join(':')
              if (res_parts.length > 1) {
                $search_results.append(`<a href="#" class="sv-search-result" data-result-page="${res_parts[0]}"><p><b>${res_parts[0]}:</b> ${text}</p></a>`)
                response_count++;
              }
            }
          }
        }
      })
        .done(function (data) {
          console.log('Completed search - results count:' + response_count);
          _fpa.ajax_done(block);

          var res_msg = `${response_count} ${response_count == 1 ? 'result' : 'results'} ${response_count > 200 ? ' - refine search to see all results' : ''}`;

          if (response_count !== null) {
            $search_results.append(`<p class="sv-search-results-count" data-search-count="${response_count}">${res_msg}</p > `);
          }
        })
        .fail(function (data) {
          _fpa.ajax_done(block);

          _this.show_failure_message(`Error: ${data}`);
        });
    }).addClass('sv-search-form-setup');

    this.$search_results.on('click', 'a.sv-search-result', function (ev) {
      ev.preventDefault();
      var search_page = $(this).attr('data-result-page');
      if (!search_page || search_page < 1) return;
      _this.set_current_page(search_page);
      _this.show_page(search_page);
    })
  }


  this.setup = function (set_preview_as, options) {
    var _this = this;

    if (options) {
      this.get_page_path = options.page_path;
      this.download_path = options.download_path || options.page_path;
      this.allow_actions = options.allow_actions || {};
      this.$owner_el = options.$owner_el;
      this.file_name = options.file_name;
    }

    this.set_current_page(1);

    this.$html = $('html');
    this.$body = $('body');
    this.$preview_as_selectors = $('.secure-view-preview-as-selectors');
    this.$preview_as_selector = $('.secure-view-preview-as-selector');
    this.$zoom_factor_selector = $('.secure-view-zoom-factor-selector');
    this.$zoom_selectors = $('.secure-view-zoom-selector');
    this.$page_controls = $('.secure-view-page-controls');
    this.$pages_block = $('#secure-view-pages');
    this.$secure_view = $('.secure-view');
    this.$search_panel = $('#secure-view-search-panel');
    this.$search_form = $('#secure-view-search-form');
    this.$search_results = $('#secure-view-search-results');
    this.$pages = $('#secure-view-pages');
    this.$loading_page_message = $('.secure-view-loading-page');
    this.$download_link = $('.sv-download-link');
    this.$no_preview_possible = $('.secure-view-no-preview');
    this.$control_blocks = $('.sv-control-block');
    this.$no_preview_no_download = $('.secure-view-no-preview-no-download');
    this.$failure_message_block = $('.secure-view-message-block');
    this.$failure_message = $('.secure-view-message-block .secure-view-message');
    this.$zoom_selector_fit = $('#secure-view-zoom-factor-fit');
    this.$extra_actions = $('.secure-view-extra-actions');
    this.$file_name = $('.secure-view-file-name');
    this.$download_actions = $('.secure-download-actions');

    this.$loading_page_message.show();
    _fpa.catch_page_transition(_this.close)

    if (!this.$body.hasClass('fixed-overlay')) {
      this.initial_html_overflow = this.$html[0].style.overflow;
      this.initial_body_overflow = this.$body[0].style.overflow;
      this.$html.css({ overflow: 'hidden' });
      this.$body.css({ overflow: 'hidden' }).addClass('fixed-overlay');
    }

    this.$control_blocks.hide();
    this.$no_preview_possible.hide();
    this.$loading_page_message.show();
    this.close(true);

    // Everything is clean and setup

    this.$file_name.html(this.file_name);
    this.$loading_page_message.show();

    if (set_preview_as) {
      this.preview_as = set_preview_as;
    }
    else if (!this.preview_as) {
      this.preview_as = 'png';
    }

    $('.secure-view-preview-as-selector[data-preview-as="' + this.preview_as + '"]').addClass('focus');
    this.$secure_view.attr('data-preview-as', this.preview_as);

    if (!this.page_count) {
      this.get_info(this.show_first_page);
    }
    else {
      this.show_first_page();
    }

    this.set_controls();

    this.$preview_as_selector.not('.sv-added-click-ev').on('click', function (ev) {
      _this.preview_as = $(this).attr('data-preview-as');
      _this.$preview_as_selector.removeClass('focus');
      $(this).addClass('focus');
      _this.clear();
      _this.setup(_this.preview_as);
      ev.preventDefault();
    }).addClass('sv-added-click-ev');

    this.$zoom_factor_selector.not('.sv-added-click-ev').on('click', function (ev) {

      _this.$preview_item.css({ transition: 'all 0.7s' });
      _this.set_zoom_for_selector($(this));

      // Reset the zoom transition on current page after zoom has completed
      window.setTimeout(function () {
        _this.$preview_item.css({ transition: '' });
      }, 1000);

      // Run all pages that are not current to zoom in the background, avoiding jarring appearance on next show
      window.setTimeout(function () {
        _this.set_zoom(null, $('.secure-view-page').not('#' + _this.page_id(_this.current_page)));
      }, 100);

      ev.preventDefault();
    }).addClass('sv-added-click-ev');


    $('#preview-next-page').not('.sv-added-click-ev').on('click', function (ev) {
      _this.show_next_page();
      ev.preventDefault();
    }).addClass('sv-added-click-ev');

    $('#preview-prev-page').not('.sv-added-click-ev').on('click', function (ev) {
      _this.show_prev_page();
      ev.preventDefault();
    }).addClass('sv-added-click-ev');

    $('#secure-view-current-page').not('.sv-added-keyup-ev').on('keyup', function (ev) {
      const new_keypress_date = Date.now()

      if (new_keypress_date == _this.last_keypress_date) return;

      var $el = $(this);
      window.setTimeout(function () {
        _this.last_keypress_date = new_keypress_date;

        var inval = $el.val();

        if (inval == '') return;
        inval = parseInt(inval);

        if (inval >= 1 && inval <= _this.page_count && inval != _this.current_page) {
          _this.show_page(inval);
        }
        else {
          $el.val(_this.current_page);
        }
      }, 500)
    }).addClass('sv-added-keyup-ev');

    $('.sv-close').not('.sv-added-click-ev').on('click', function (ev) {
      _this.close();
    }).addClass('sv-added-click-ev');


    this.$secure_view.fadeIn(400, 'swing', function () {
      window.setTimeout(function () {
        if (_this.page_count) {
          _this.show_first_page();
        }

        _this.app_specific = (new SecureViewAppSpecific).setup(_this);
      }, 10);

    });

    this.setup_search();

  };

  this.set_controls = function () {
    this.$control_blocks.hide();
    this.$extra_actions.show();
    this.$file_name.show();

    if (this.preview_as == 'html') {
      this.$zoom_selectors.show();
      this.$page_controls.hide();
      this.$zoom_selector_fit.hide();
    }
    else {
      this.$zoom_selectors.show();
      this.$page_controls.show();
      this.$zoom_selector_fit.show();
    }

    this.set_actions();

  }

  this.set_actions = function () {
    this.$preview_as_selectors.hide();

    if (this.allow_actions.download_files) {
      this.$download_link.show().attr('href', this.download_path);
      this.$download_actions.show();
    }
    else {
      this.$download_link.hide();
      this.$download_actions.hide();
    }

    var $sel = $('.secure-view-preview-as-selector[data-preview-as="html"]');
    if (this.allow_actions.view_files_as_html) {
      $sel.show();
      this.$preview_as_selectors.show();
    }
    else {
      $sel.hide();
    }

    var $sel = $('.secure-view-preview-as-selector[data-preview-as="png"]');
    if (this.allow_actions.view_files_as_image) {
      $sel.show();
      this.$preview_as_selectors.show();
    }
    else {
      $sel.hide();
    }
  }

  this.clean_page = function () {
    _this.$control_blocks.hide();
    _this.$no_preview_possible.hide();
    _this.$no_preview_no_download.hide();
    _this.$loading_page_message.hide();
    _this.$failure_message_block.hide();

  }

  this.show_first_page = function () {
    _this.clean_page();
    _this.set_controls();

    if (_this.can_preview) {
      _this.set_current_page(1);
      _this.show_page(_this.current_page);
      _this.$pages.removeClass('.sv-pages-as-png, .sv-pages-as-html').addClass('sv-pages-as-' + _this.preview_as);
    }
    else {
      if (_this.allow_actions.download_files) {
        _this.$no_preview_possible.show();
      }
      else {
        _this.$no_preview_no_download.show();
      }
    }

  };

  this.setup_infinite_scroll = function () {
    _this.$pages_block.on('scroll', function () {

      const new_date = Date.now();
      if (new_date - _this.last_scroll_event_date < 1000) return;

      window.setTimeout(function () {
        _this.last_scroll_event_date = new_date;

        const $last_img = $('.secure-view-page').last();
        if (!$last_img) return;

        const outer_scroll_top = _this.$pages_block.scrollTop(),
          last_img_pos = $last_img.position();
        if (!last_img_pos) return;

        const last_img_top = $last_img.position().top;

        if (last_img_top - outer_scroll_top < 50) {
          _this.show_next_page(true);
        }

        _this.set_current_page_for_scroll()
      }, 1000)

    });

    if (_this.page_count > 1) {
      _this.page_defaults.overflow = 'auto';
      _this.$pages_block.css({ overflow: _this.page_defaults.overflow })
    }


  }

  // Based on infinite scroll position, set the current page number
  this.set_current_page_for_scroll = function () {

    window.setTimeout(function () {

      $('.secure-view-page').each(function () {
        const img_top = $(this).position().top,
          b_height = _this.$pages_block.height();

        if (img_top >= -10 && img_top < b_height / 2) {
          _this.set_current_page($(this).attr('data-page-num'));
          return false;
        }
      })

    }, 250)
  }

  this.get_info = function (callback) {

    var params = {
      secure_view: {
        do: 'info',
        preview_as: _this.preview_as
      }
    };

    var url = _this.get_page_path;
    if (url.indexOf('?') > 0) {
      url += '&';
    }
    else {
      url += '?';
    }
    url += $.param(params);

    $.ajax({ url: url }).done(function (data) {
      _this.page_count = data.page_count;
      _this.current_zoom = data.default_zoom;
      _this.can_preview = data.can_preview;

      $('#secure-view-page-count').html(_this.page_count);

      _this.setup_infinite_scroll();

      if (callback) {
        callback();
      }
    }).fail(function (jqXHR, textStatus, errorThrown) {
      _this.clean_page();
      if (jqXHR.status == 401) {
        _this.$no_preview_no_download.show();
      }
      else if (jqXHR.status == 0) {
        _this.show_failure_message('Failed to get the requested item from the server: possible network error');
      }
      else {
        _this.show_failure_message('Failed to get the requested item from the server: ' + errorThrown);
      }
      console.log('Failed to get info: ' + errorThrown);
    });
  };

  this.show_failure_message = function (msg) {
    _this.$failure_message.html(msg);
    _this.$failure_message_block.show();
  }

  this.set_zoom = function (z, $items) {

    $items = $items || _this.$preview_item;

    if (!$items) return;

    if (z) {
      _this.current_zoom = z;
    }

    if (!_this.current_zoom) {
      _this.set_zoom_for_selector();
      return;
    }

    if (_this.preview_as == 'html') {
      if (_this.current_zoom == 'fit') {
        _this.current_zoom = 100;
      }
      _this.$pages_block.css({ overflow: 'hidden' });
      $('#sv-preview-item-html-1')[0].contentWindow.document.body.style.zoom = "" + _this.current_zoom + "%";
    }
    else {

      if (_this.current_zoom == 'fit') {
        _this.$pages_block.css({ overflow: _this.page_defaults.overflow });
      }
      else {
        _this.$pages_block.css({ overflow: 'auto' });
      }

      $items.each(function () {
        var $item = $(this);
        if (_this.current_zoom == 'fit') {

          var ch = _this.$pages.height();
          var ih = $item.height();
          var iw = $item.width();
          var cw = _this.$pages.parent().width();

          if (ch == 0 || ih == 0 || cw == 0 || iw == 0) {
            return;
          }

          var pw = iw / cw;
          var ph = ih / ch;

          if (ph > pw) {
            $item.width(iw / ph);
          }
          else {
            $item.width(iw / pw);
          }

        }
        else {

          var iw = $item[0].naturalWidth || 1200;

          var p = iw * parseInt(_this.current_zoom) / 100;

          $item.width(p + "px");
        }
      });
    }


    $('.secure-view-zoom-factor-selector').removeClass('focus');
    $('.secure-view-zoom-factor-selector[data-zoom-factor="' + _this.current_zoom + '"]').addClass('focus');
  };

  this.set_zoom_for_selector = function ($el) {
    if (!$el) {
      $el = _this.$zoom_factor_selector.filter('.focus');
    }

    var z = $el.attr('data-zoom-factor');
    _this.set_zoom(z);
  };

  this.show_page = function (page, no_scroll) {
    if (!_this.got_page(page)) {
      _this.$loading_page_message.show();
    }
    _this.get_page(page);
    // $(".secure-view-page").hide();

    _this.$preview_item = $("#" + _this.page_id(page));
    _this.$preview_item.show();

    if (_this.preview_as == 'png') {
      _this.show_img_page(_this.current_page);
    }
    else if (_this.preview_as == 'html') {
      _this.show_html_page(_this.current_page);
    }


    if (no_scroll) return;

    if (_this.$preview_item.hasClass('sv-img-not-loaded')) {
      _this.$preview_item.on('load', function () {
        _this.scroll_to($(this))
      })
    }
    else {
      // The page was previously loaded, just scroll to it
      _this.scroll_to(_this.$preview_item)
    }

  };

  this.scroll_to = function ($preview_item) {
    const new_scroll_date = Date.now();
    if (_this.last_scroll_to_date > new_scroll_date) return;

    _this.last_scroll_to_date = new_scroll_date;

    window.setTimeout(function () {
      _fpa.utils.scrollTo($preview_item, 0, 0, _this.$pages_block)
      _this.set_current_page_for_scroll()
    }, 10);
  }


  this.show_img_page = function (page) {
    _this.set_zoom();
    if (page + 1 <= _this.page_count)
      _this.get_page(page + 1);
    if (page - 1 >= 1)
      _this.get_page(page - 1);
    if (page + 2 <= _this.page_count)
      _this.get_page(page + 2);
    if (page + 3 <= _this.page_count)
      _this.get_page(page + 3);

  };

  this.show_html_page = function (page) {

  };


  this.set_current_page = function (page) {
    _this.current_page = parseInt(page);
    _this.$preview_item = $("#" + _this.page_id(page));
    $('#secure-view-current-page').val(_this.current_page);
    $('#preview-next-page').attr('disabled', _this.current_page == _this.page_count);
    $('#preview-prev-page').attr('disabled', _this.current_page == 1);
  };

  this.show_next_page = function (no_scroll) {
    var page = _this.current_page + 1;
    if (page > _this.page_count) return;
    _this.show_page(page, no_scroll);
  };

  this.show_prev_page = function () {
    var page = _this.current_page - 1;
    if (page < 1) return;
    _this.show_page(page);
  };

  this.page_loaded = function ($preview_item) {
    _this.$loading_page_message.hide();
    _this.set_zoom(null, $preview_item);
    $preview_item.removeClass('sv-img-not-loaded');
  };

  this.got_page = function (page) {
    var page_id = _this.page_id(page);
    return $('#' + page_id).length;
  };

  _this.page_id = function (page) {
    return 'sv-preview-item-' + _this.preview_as + '-' + page;
  }

  _this.get_page = function (page) {

    if (page > _this.page_count) return;

    var page_id = _this.page_id(page);

    // Return if the page is already present
    if (_this.got_page(page)) return;

    var params = {
      secure_view: {
        page: page,
        do: "convert_to",
        preview_as: _this.preview_as
      }
    };

    var url = _this.get_page_path;
    if (url.indexOf('?') > 0) {
      url += '&';
    }
    else {
      url += '?';
    }
    url += $.param(params);

    var display_page = _this.page_defaults.display;

    if (_this.preview_as == 'png') {
      var $preview_item = $(`<img id="${page_id}" src="${url}" data-page-num="${page}" class="sv-img-not-loaded secure-view-page" data-secure-view-page="${page}" style="display: ${display_page}; width: 1px;" draggable="false" />`);
    }
    else if (_this.preview_as == 'html') {
      var $preview_item = $(`<iframe id="${page_id}" src="${url}" data-page-num="${page}" class="secure-view-page-iframe" data-secure-view-page="${page}" style="display: ${display_page};" ></iframe>`);
    }
    else {
      console.log('preview_as not set');
    };

    if (page > 1) {
      var $after_page;
      // Scan through the pages until we find the point to place the new page
      $('.secure-view-page').each(function () {
        var curr_page = $(this).data('pageNum');
        if (curr_page > page) {
          $after_page = $(this);
          return false;
        }
      })
    }

    if ($after_page) {
      $after_page.before($preview_item);
    }
    else {
      _this.$pages.append($preview_item);
    }

    $preview_item.on('hover', function (ev) {
      ev.preventDefault();
    });

    if ($preview_item[0].complete || $preview_item[0].readyState == 4) {
      _this.page_loaded($preview_item);
    }
    else {
      $preview_item.on('load', function () {
        _this.page_loaded($(this));
      }).on('error', function (ev) {
        _this.clean_page();
        $('.secure-view-page').hide();
        _this.show_failure_message('Failed to get the requested page from the server');
      });
    }


  };

  _this.clear = function () {
    $('.secure-view-page').remove();
    $('.secure-view-page-iframe').remove();
    $('#secure-view-page-count').html('');
    _this.$file_name.html('');
    _this.clean_page();

  };

  _this.close = function (keep_view) {

    if (!keep_view) {
      _this.$secure_view.fadeOut();
      _this.$html.css({ overflow: _this.initial_html_overflow });
      _this.$body.css({ overflow: _this.initial_body_overflow }).removeClass('fixed-overlay');;
      $('.sv-selected').removeClass('sv-selected');
      _fpa.default_page_transition();
    }
    _this.clear();
    _this.page_count = null;
    _this.preview_as = null;
    _this.$preview_as_selector.removeClass('focus');

    if (_this.app_specific) {
      _this.app_specific.close();
    }
  }

  return this;
};
