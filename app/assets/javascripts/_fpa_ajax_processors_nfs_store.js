_fpa.postprocessors_nfs_store = {

  nfs_store_browse_list_results: function(block) {
    var p = block.parents('.nfs-store-container-block').first();
    p.fs_browser = _nfs_store.fs_browser;
    setTimeout(function() {
      p.fs_browser(p);
      _fpa.form_utils.resize_children(block);
    }, 100);
  }

};

$.extend(_fpa.postprocessors, _fpa.postprocessors_nfs_store);
