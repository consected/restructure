_fpa.preprocessors_nfs_store = {
  nfs_store_browse_json_results: function (block, data) {
    var downloads = data.nfs_store_container.container_files
    if (!downloads) return

    var folder = block.attr('data-folder').split('/')
    var level = parseInt(block.attr('data-folder-level'))

    data.folder_entries = {}

    // Get a list of folders that have files in them, storing a list of folders and
    // a hash of folder entries.
    // Bear in mind that the list of folders may miss some of the intermediate folders
    // if they contain no files. These will be added in a moment.
    data.folders = downloads.map((self) => {
      // Get a list of folder paths for this level(root to this level) - a set of the first element in the path
      var fname = self.container_dir_path.split('/').slice(0, -1).join('/') || '.'
      data.folder_entries[fname] = self
      return fname
    }).filter((value, index, self) => {
      return self.indexOf(value) === index //&& value !== folder
    })

    // Add in the missing intermediate folders that don't have any file entries
    for (var i in data.folders) {
      var fsplit = data.folders[i].split('/')
      var flen = fsplit.length
      for (var j = 2; j < flen; j++) {
        var newf = fsplit.slice(0, flen - 1).join('/')
        if (data.folders.indexOf(newf) < 0) {
          data.folders.push(newf)
          data.folder_entries[newf] = []
        }
      }
    }

    data.folders = data.folders.sort()

    // Generate a hash of subfolders, with arrays of the folders they have directly within them
    data.subfolders = {}
    for (var i in data.folders) {
      var fsplit = data.folders[i].split('/')
      var flen = fsplit.length
      if (flen > 1) {
        var subf = fsplit.slice(0, -1).join('/')
        data.subfolders[subf] = data.subfolders[subf] || []
        data.subfolders[subf].push(data.folders[i])
      }

    }

    // Generate some information for each folder to assist in the templates
    data.folder_info = {}
    for (var i in data.folders) {
      var curr_folder = data.folders[i]
      var fsplit = curr_folder.split('/')
      var folder_name = fsplit.slice(-1)[0]
      data.folder_info[curr_folder] = {
        folder: curr_folder,
        folder_name: folder_name,
        level: fsplit.length - 1,
        show_folder_name: curr_folder == '.' ? 'file status' : folder_name
      }

      if (curr_folder.indexOf(/\.__mounted - archive__$ /) >= 0) {
        data.folder_info[curr_folder].show_folder_name = curr_folder.replace(/\.__mounted-archive__$/, '')
        data.folder_info[curr_folder].is_archive = true
      }
    }

    data.downloads = downloads

  }
}
_fpa.postprocessors_nfs_store = {

  refresh_container_if_needed: function (block) {
    var tel = block.find('.file-processing-tag');
    if (tel.length) {
      if (!tel.is(':visible')) return;
      window.setTimeout(function () {
        var $browse_container = block.parents('.browse-container');
        var $refresh_btn = $browse_container.first().find('.refresh-container-list').not('[disabled="disabled"]');
        // If the block is not visible just set another poll and get out of here.
        if (!_fpa.utils.inViewport(block) || $refresh_btn.length == 0) {
          _fpa.postprocessors_nfs_store.refresh_container_if_needed(block);
          return;
        }
        // Since the block is visible, go ahead and refresh, until it either works or we run out of attempts
        var req_count = $browse_container.attr('data-refresh-count');
        if (!req_count || parseInt(req_count) < 6) {
          if (!req_count)
            var new_c = 1;
          else
            var new_c = parseInt(req_count) + 1;

          $browse_container.attr('data-refresh-count', new_c);
          $refresh_btn.click();
        }
      }, 10000);
    }
  },

  nfs_store_browse_json_results: function (block) {
    console.log('nfs_store_browse_json_results')
    _fpa.postprocessors_nfs_store.nfs_store_browse_list_results(block)
  },

  nfs_store_browse_list_results: function (block) {
    var container_block = block.parents('.nfs-store-container-block').first();
    container_block.fs_browser = _nfs_store.fs_browser;
    setTimeout(function () {
      container_block.fs_browser(container_block);

      _fpa.postprocessors_nfs_store.refresh_container_if_needed(block);

      var writable = block.find('.container-browser').attr('data-container-writable');
      var button = container_block.find('.fileinput-button');
      if (writable == 'false') {
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

  filestore_classification_block: function (block) {
    _fpa.form_utils.format_block(block);
    window.setTimeout(function () {
      var rect = block.get(0).getBoundingClientRect();
      var winbot = $(window).height() * 0.9;
      var not_visible = !(rect.top >= 0 && rect.bottom <= winbot);
      if (not_visible)
        $.scrollTo(block, { offset: -(winbot - rect.height) });

    }, 100);

  },

  filestore_classification_stored_file_result_template: function (block, data) {
    _fpa.form_utils.format_block(block);
    var container_id = data.nfs_store__manage__stored_file.nfs_store_container_id;
    $('[data-result="filestore-classification-stored-file-edit-form--' + container_id + '"]').remove();
  },

  filestore_classification_archived_file_result_template: function (block, data) {
    _fpa.form_utils.format_block(block);
    var container_id = data.nfs_store__manage__archived_file.nfs_store_container_id;
    $('[data-result="filestore-classification-archived-file-edit-form--' + container_id + '"]').remove();
  }

};

$.extend(_fpa.postprocessors, _fpa.postprocessors_nfs_store);
$.extend(_fpa.preprocessors, _fpa.preprocessors_nfs_store);
