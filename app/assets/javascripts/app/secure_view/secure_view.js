"use strict";

/*
   Setup the viewer like this:

      var sv = new SecureView;
      sv.setup("<%= request.path %>", "<%= @preview_as %>");
 */

var SecureView = function () {
  var _this = this;

  this.init = function () {
    this.page_count = 0;
    this.preview_as = null;
    this.current_page = 1;
    this.current_zoom = '';
    this.get_page_path = '';

    this.$secure_view = null;
    this.$preview_as_selector = null;
    this.$zoom_factor_selector = null;
    this.$page_controls = null;
    this.$zoom_selectors = null;
    this.initial_body_overflow = null;
    this.$loading_page_message = null;
    this.$pages = null;
    this.$preview_item = null;
    this.$body = $('body');
  };

  this.init();


  this.setup = function (page_path, set_preview_as) {
    var _this = this;

    this.get_page_page = page_path;

    this.set_current_page(1);

    this.$preview_as_selector = $('.secure-view-preview-as-selector');
    this.$zoom_factor_selector = $('.secure-view-zoom-factor-selector');
    this.$zoom_selectors = $('.secure-view-zoom-selector');
    this.$page_controls = $('.secure-view-page-controls');


    this.initial_body_overflow = this.$body[0].style.overflow;
    this.$body.css({ overflow: 'hidden' });
    this.$secure_view = $('.secure-view');
    this.$pages = $('#secure-view-pages');
    this.$loading_page_message = $('.secure-view-loading-page');
    this.$loading_page_message.show();

    if (set_preview_as) {
      this.preview_as = set_preview_as;
      console.log('preview as: ' + this.preview_as);

      this.get_info(this.init_setup);
    }
    else {
      this.init_setup();
    }


    if (this.preview_as == 'html') {
      this.$zoom_selectors.hide();
      this.$page_controls.hide();
    }
    else {
      this.$zoom_selectors.show();
      this.$page_controls.show();
    }



    this.$preview_as_selector.not('.sv-added-click-ev').on('click', function(ev){
      _this.preview_as = $(this).attr('data-preview-as');
      _this.$preview_as_selector.removeClass('focus');
      $(this).addClass('focus');
      _this.clear();
      _this.setup(_this.preview_as);
      ev.preventDefault();
    }).addClass('sv-added-click-ev');

    this.$zoom_factor_selector.not('.sv-added-click-ev').on('click', function(ev){
      _this.set_zoom_for_selector($(this));
      ev.preventDefault();
    }).addClass('sv-added-click-ev');


    $('#preview-next-page').not('.sv-added-click-ev').on('click', function(ev){
      _this.show_next_page();
      ev.preventDefault();
    }).addClass('sv-added-click-ev');

    $('#preview-prev-page').not('.sv-added-click-ev').on('click', function(ev){
      _this.show_prev_page();
      ev.preventDefault();
    }).addClass('sv-added-click-ev');

    $('#secure-view-current-page').not('.sv-added-keyup-ev').on('keyup', function(ev) {
      var inval = $(this).val();

      if (inval == '') return;
      inval = parseInt(inval);

      if (inval >= 1 && inval <= _this.page_count && inval != _this.current_page) {
        _this.show_page(inval);
      }
      else {
        $(this).val(_this.current_page);
      }
    }).addClass('sv-added-keyup-ev');

    $('#secure-view-close-btn').not('.sv-added-click-ev').on('click', function(ev) {
      _this.close();
    }).addClass('sv-added-click-ev');


    this.$secure_view.fadeIn(400, 'swing', function () {
      window.setTimeout(function () {
        _this.init_setup();
      }, 10);

    });


  };

  this.init_setup = function () {
    _this.set_current_page(1);
    _this.show_page(_this.current_page);
    _this.$pages.removeClass('.sv-pages-as-png, .sv-pages-as-html').addClass('sv-pages-as-' + _this.preview_as);
  };



  this.get_info = function (callback) {

    $.ajax({url: _this.get_page_path + '?do=info&preview_as=' + _this.preview_as }).done(function (data) {
      _this.page_count = data.page_count;
      _this.current_zoom = data.default_zoom;

      $('#secure-view-page-count').html(_this.page_count);

      if (callback) {
        callback ();
      }
    });
  };

  this.set_zoom = function (z) {

    if (!_this.$preview_item) return;

    if (z) {
      _this.current_zoom = z;
    }

    if (!_this.current_zoom) {
      _this.set_zoom_for_selector();
    }


    if (_this.current_zoom == 'fit') {
      var ch = _this.$pages.height();
      var ih = _this.$preview_item.height();
      var iw = _this.$preview_item.width();
      var cw = _this.$pages.width();

      if(ch == 0 || ih == 0 || cw == 0 || iw == 0) {
        return;
      }

      var pw = iw / cw;
      var ph = ih / ch;

      if (ph > pw) {
        _this.$preview_item.width(iw / ph);
      }
      else {
        _this.$preview_item.width(iw / pw);
      }

    }
    else {
      _this.$preview_item.width(_this.current_zoom + "%");
    }

    $('.secure-view-zoom-factor-selector').removeClass('focus');
    $('.secure-view-zoom-factor-selector[data-zoom-factor="'+_this.current_zoom+'"]').addClass('focus');
  };

  this.set_zoom_for_selector = function ($el) {
    if (!$el) {
      $el = _this.$zoom_factor_selector.filter('.focus');
    }

    var z = $el.attr('data-zoom-factor');
    _this.set_zoom(z);
  };

  this.show_page = function (page) {
    if (!_this.got_page(page)) {
      _this.$loading_page_message.show();
    }
    _this.get_page(page);
    $(".secure-view-page").hide();

    _this.$preview_item = $("#sv-preview-item-"+(page));
    _this.$preview_item.show();

    if (_this.preview_as == 'png') {
      _this.show_img_page(_this.current_page);
    }
    else if (_this.preview_as == 'html') {
      _this.show_html_page(_this.current_page);
    }

    _this.set_current_page(page);

  };


  this.show_img_page = function (page) {
    _this.get_page(page + 1);
    _this.get_page(page + 2);
    _this.get_page(page + 3);
    _this.set_zoom();
  };

  this.show_html_page = function (page) {

  };


  this.set_current_page = function (page) {
    _this.current_page = page;
    _this.$preview_item = $("#sv-preview-item-"+(page));
    $('#secure-view-current-page').val(_this.current_page);
    $('#preview-next-page').attr('disabled', _this.current_page == _this.page_count);
    $('#preview-prev-page').attr('disabled', _this.current_page == 1);
  };

  this.show_next_page = function () {
    var page = _this.current_page + 1;
    if (page > _this.page_count) return;
    _this.show_page(page);
  };

  this.show_prev_page = function () {
    var page = _this.current_page - 1;
    if (page < 1)  return;
    _this.show_page(page);
  };

  this.page_loaded = function ($preview_item) {
    _this.$loading_page_message.hide();
    _this.set_zoom();
  };

  this.got_page = function (page) {
    var page_id = 'sv-preview-item-'+_this.preview_as+'-'+page;
    return $('#'+page_id).length;
  };

  _this.get_page = function (page) {

    var page_id = 'sv-preview-item-'+page;

    // Return if the page is already present
    if (_this.got_page(page)) return;

    var params = {
      page: page,
      do: "convert_to",
      preview_as: _this.preview_as
    };

    var url = _this.get_page_path + '?' + $.param(params);

    if (_this.preview_as == 'png') {
      var $preview_item = $('<img id="'+page_id+'" src="'+url+'" class="secure-view-page" data-secure-view-page="'+page+'" style="display: none;" draggable="false" />');
    }
    else if (_this.preview_as == 'html') {
      var $preview_item = $('<iframe id="'+page_id+'" src="'+url+'" class="secure-view-page-iframe" data-secure-view-page="'+page+'" style="display: none;" ></iframe>');
    }
    else {
      console.log('preview_as not set');
    };

    _this.$pages.append($preview_item);

    $preview_item.on('hover', function (ev) {
      ev.preventDefault();
    });

    if ($preview_item[0].complete || $preview_item[0].readyState == 4) {
      _this.page_loaded($preview_item);
    }
    else {
      $preview_item.on('load', function () {
        _this.page_loaded($(this));
      });
    }


  };

  _this.clear = function () {
    $('.secure-view-page').remove();
    $('.secure-view-page-iframe').remove();
    $('#secure-view-page-count').html();
  };

  _this.close = function () {
    _this.$secure_view.fadeOut();
    _this.$body.css({ overflow: _this.initial_body_overflow });
    _this.clear();
  }

  return this;
};
