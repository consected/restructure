_fpa.postprocessors_nfs_store = {

  refresh_container_if_needed: function (block) {
    var tel = block.find('.file-processing-tag');
    if (tel.length) {
      if(!tel.is(':visible')) return;
      window.setTimeout(function () {
        // If the block is not visible just set another poll and get out of here.
        if(!_fpa.utils.inViewport(block)) {
          _fpa.postprocessors_nfs_store.refresh_container_if_needed(block);
          return;
        }
        // Since the block is visible, go ahead and refresh, until it either works or we run out of attempts
        var $browse_container = block.parents('.browse-container');
        var req_count = $browse_container.attr('data-refresh-count');
        if (!req_count || parseInt(req_count) < 6) {
          if(!req_count)
            var new_c = 1;
          else
            var new_c = parseInt(req_count) + 1;

          $browse_container.attr('data-refresh-count', new_c);
          $browse_container.first().find('.refresh-container-list').not('[disabled="disabled"]').click();
        }
      }, 10000);
    }
  },

  nfs_store_browse_list_results: function(block) {
    var container_block = block.parents('.nfs-store-container-block').first();
    container_block.fs_browser = _nfs_store.fs_browser;
    setTimeout(function() {
      container_block.fs_browser(container_block);

      _fpa.postprocessors_nfs_store.refresh_container_if_needed(block);

      var writable = block.find('.container-browser').attr('data-container-writable');
      var button = container_block.find('.fileinput-button');
      if(writable == 'false') {
        button.hide();
        container_block.parents('.upload-dropzone').removeClass('upload-dropzone').addClass('upload-dropzone-disabled');
      }
      else {
        button.show();
        container_block.parents('.upload-dropzone-disabled').removeClass('upload-dropzone-disabled').addClass('upload-dropzone');
      }

      _fpa.form_utils.format_block(block);
    }, 100);
  },

  filestore_classification_block: function(block) {
    _fpa.form_utils.format_block(block);
    window.setTimeout(function() {
      var rect = block.get(0).getBoundingClientRect();
      var winbot = $(window).height()*0.9;
      var not_visible = !(rect.top >= 0 && rect.bottom <= winbot);
      if(not_visible)
      $.scrollTo(block, { offset: -(winbot-rect.height) });

    }, 100);

  },

  filestore_classification_stored_file_result_template: function(block, data) {
    _fpa.form_utils.format_block(block);
    var container_id = data.nfs_store__manage__stored_file.nfs_store_container_id;
    $('[data-result="filestore-classification-stored-file-edit-form--'+container_id+'"]').remove();
  },

  filestore_classification_archived_file_result_template: function(block, data) {
    _fpa.form_utils.format_block(block);
    var container_id = data.nfs_store__manage__archived_file.nfs_store_container_id;
    $('[data-result="filestore-classification-archived-file-edit-form--'+container_id+'"]').remove();
  }

};

$.extend(_fpa.postprocessors, _fpa.postprocessors_nfs_store);
