_fpa.postprocessors_admin = {

  // When an edit form is shown
  admin_edit_form: function (block, data) {
    _fpa_admin.all.admin_edit_form.setup(block, data)
  },



  // When the result from an create / update is shown
  admin_result: function (block, data) {

    // Clear the edit form
    $('#admin-edit-').html('');

    // Refresh the tablesorter to include the new / updated rows
    var b = $('.attached-tablesorter').trigger("update");;

    // Handle the scrolling by fixing up the flag classes and scrolling to the new result block after a short delay
    $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');
    window.setTimeout(function () {
      _fpa.utils.scrollTo(block, 200, -50);
    }, 100);
    window.setTimeout(function () {
      $('prevent-scroll').removeClass('prevent-scroll');
    }, 1000);
  },

  admin_result_re_edit: function (block, data) {
    // Clear the edit form
    $('#admin-edit-').html('');
    // Refresh the tablesorter to include the new / updated rows
    var b = $('.attached-tablesorter').trigger("update");

    window.setTimeout(function () {
      block.find('a.simple-admin-edit').click();
    }, 200);


  },

  search_attr_definer_setup: function (block, data) {
    console.log('search_attr_definer_setup')
    // Run at next step to avoid UI lock ups
    window.setTimeout(function () {
      var aef = new _fpa_admin.reports.admin_edit_form(block, data)
      aef.setup_search_attr_config();
    })
  }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_admin);

