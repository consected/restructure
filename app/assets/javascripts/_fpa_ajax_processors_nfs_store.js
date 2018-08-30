_fpa.postprocessors_nfs_store = {

  nfs_store_browse_list_results: function(block) {
    var container_block = block.parents('.nfs-store-container-block').first();
    container_block.fs_browser = _nfs_store.fs_browser;
    setTimeout(function() {
      container_block.fs_browser(container_block);
      _fpa.form_utils.setup_extra_actions(block);
      _fpa.form_utils.resize_children(block);
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
    }, 100);
  }

};

$.extend(_fpa.postprocessors, _fpa.postprocessors_nfs_store);
