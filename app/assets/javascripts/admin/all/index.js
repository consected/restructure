_fpa_admin.all.index_page = class {

  constructor(block, data) {
    if (!block) block = $('.admin-result-index');
    this.block = block
    this.data = data
  }

  // Called when an admin index page has loaded and needs to be set up
  static loaded(block) {
    var il = new _fpa_admin.all.index_page(block)
    il.setup_shrinkable_blocks()
    il.handle_filter_selections();
  }

  setup_shrinkable_blocks() {

    window.setTimeout(function () {
      var blocks = $('.shrinkable-block')
      _fpa.utils.make_readable_notes_expandable(blocks, 100);

      $(document).on('change click', '#config', function () {
        $('#import-settings-block').collapse('show');
        var ext = $('#config').val().split('.').pop();
        $('input[name="upload_format"]').prop('checked', false);
        $('input[name="upload_format"][value="' + ext + '"]').prop('checked', true);
      })

    }, 10);

  }

  // The filter tabs for an admin index are displayed as an accordian.
  // Set things up 
  handle_filter_selections() {
    $('#filter-accordion .panel').each(function () {
      var selected = $(this).find('.panel-body a.btn-primary').html();
      var headspace = $(this).find('.panel-heading .panel-title .sel-headspace');

      headspace.html(selected);
    })
  }

}