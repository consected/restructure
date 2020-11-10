"use strict";

var SecureViewAppSpecific = function () {
  var _this = this;

  this.setup = function (secure_view) {

    this.secure_view = secure_view;

    this.$show_files = $('#sv-extra-actions-show_files');

    this.$show_files.not('.sv-added-click-ev').on('click', function(ev){
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

    this.close_folder();

    return this;
  }

  this.close = function () {
    this.close_folder();
  }

  this.close_folder = function () {
    // Close the folder if it is open
    this.secure_view.$owner_el.removeClass('sv-file-listing');
    this.$show_files.addClass('glyphicon-folder-open');
    this.$show_files.removeClass('glyphicon-folder-close');
    this.secure_view.$owner_el.find('a.refresh-container-list').attr('disabled', false);

  }

};
