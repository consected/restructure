"use strict";

var SecureViewAppSpecific = function () {
  var _this = this;

  this.setup = function (secure_view) {

    this.secure_view = secure_view;

    this.$show_files = $('#sv-extra-actions-show_files');

    this.$show_files.not('.sv-added-click-ev').on('click', function (ev) {
      var $owner_el = _this.secure_view.$owner_el;
      var $el = $owner_el;

      if ($el.hasClass('sv-file-listing')) {
        // The folder is shown - hide it
        _this.close_folder();
      }
      else {
        //  The folder is not shown - show it
        $el.addClass('sv-file-listing');
        $(this).addClass('glyphicon-folder-close');
        $(this).removeClass('glyphicon-folder-open');
        $owner_el.find('a.refresh-container-list').attr('disabled', true);
      }
      ev.preventDefault();
    }).addClass('sv-added-click-ev');

    this.$search_doc = $('#sv-extra-actions-search_doc, #sv-close-search');
    this.$search_doc.not('.sv-added-click-ev').on('click', function (ev) {
      var $search_panel = _this.secure_view.$search_panel;

      if ($search_panel.hasClass('sv-search-panel')) {
        // The panel is shown - hide it
        _this.close_search_panel();
      }
      else {
        //  The panel is not shown - show it
        _this.show_search_panel();
      }
      ev.preventDefault();
    }).addClass('sv-added-click-ev');


    this.close_folder();

    return this;
  }

  this.close = function () {
    this.close_folder();
    this.close_search_panel();
  }

  this.close_folder = function () {
    // Close the folder if it is open
    this.secure_view.$owner_el.removeClass('sv-file-listing');
    this.$show_files.addClass('glyphicon-folder-open');
    this.$show_files.removeClass('glyphicon-folder-close');
    this.secure_view.$owner_el.find('a.refresh-container-list').attr('disabled', false);

  }

  this.show_search_panel = function () {
    this.secure_view.$search_panel.addClass('sv-search-panel').animate({ width: '250px' });
    this.secure_view.$search_results.html('');
    this.secure_view.$search_form.find('[name="search_string"]').val('').focus();
  }

  this.close_search_panel = function () {
    this.secure_view.$search_panel.removeClass('sv-search-panel').animate({ width: '0' });
  }

};
