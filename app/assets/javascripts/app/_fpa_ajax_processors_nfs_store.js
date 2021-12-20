_fpa.preprocessors_nfs_store = {
  // Preprocess data for a filestore browser form,
  // listing downloads
  filestore_browser_form: function (block, data) {
    var downloads = data.nfs_store_container.container_files
    if (!downloads) return

    var folder = block.attr('data-folder').split('/')
    var level = parseInt(block.attr('data-folder-level'))

    data.folder_entries = {}

    const archive_suffix = '.__mounted-archive__'

    // Setup container_dir_path in downloads
    for (var i in downloads) {
      var value = downloads[i]

      var dp = ['.']
      if (value.archive_file) dp.push(`${value.archive_file}${archive_suffix}`)
      if (value.path) dp.push(value.path)
      value.container_dir_path = dp.join('/')
    }


    // Get a list of folders that have files in them, storing a list of folders and
    // a hash of folder entries.
    // Bear in mind that the list of folders may miss some of the intermediate folders
    // if they contain no files. These will be added in a moment.
    data.folders = downloads.map((self) => {
      // Get a list of folder paths for this level(root to this level) - a set of the first element in the path
      var fname = self.container_dir_path || '.'
      data.folder_entries[fname] = data.folder_entries[fname] || []
      data.folder_entries[fname].push(self)
      return fname
    }).filter((value, index, self) => {
      return self.indexOf(value) === index //&& value !== folder
    })

    // Add in the missing intermediate folders that don't have any file entries
    for (var i in data.folders) {
      var fsplit = data.folders[i].split('/')
      var flen = fsplit.length
      for (var j = 1; j < flen; j++) {
        var newf = fsplit.slice(0, j).join('/')
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
        show_folder_name: folder_name == '.' ? 'file status' : folder_name
      }

      if (folder_name.endsWith('.__mounted-archive__')) {
        data.folder_info[curr_folder].show_folder_name = folder_name.replace(/\.__mounted-archive__$/, '')
        data.folder_info[curr_folder].is_archive = true
      }
    }

    for (var i in downloads) {
      var value = downloads[i]
      if (value.id) {
        value.edit_path = `/masters/${data.nfs_store_container.master_id}/filestore/classification/${data.nfs_store_container.id}?download_id=${value.id}&retrieval_type=${value.retrieval_type}`
        value.filename_path = `/nfs_store/downloads/${data.nfs_store_container.id}?activity_log_id=${data.nfs_store_container.parent_id}&activity_log_type=${data.nfs_store_container.parent_type}&download_id=${value.id}&retrieval_type=${value.retrieval_type}`
        value.file_size_mb = Math.floor(value.file_size / 1000000 * 10) / 10
      }
      else {

        if (value.file_name.endsWith('__')) {
          if (value.file_name.match(/\.__processing-archive__$/))
            value.is_processing_arch = true
          else if (value.file_name.match(/\.__failed-archive__$/))
            value.is_failed_arch = true
          else if (value.file_name.match(/\.__processing-index__$/))
            value.is_processing_index = true
          else if (value.file_name.match(/\.__processing__$/))
            value.is_processing = true

          value.file_name = value.file_name.replace(/(.+)\.__processing.*__$/, '$1')
        }
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

          // Only allow one refresh every 8 seconds (don't do 10, as this will conflict with the recurring refresh time)
          // We can't do this on the refresh button itself, since the remote event is not easy to stop
          var time = (new Date).getTime() / 1000;
          var dt = $refresh_btn.attr('data-last-click-at');
          if (dt && time - parseInt(dt) < 8) {
            return;
          }

          $refresh_btn.click();
        }
      }, 10000);
    }
  },

  filestore_browser_form: function (block, data) {
    console.log('filestore_browser_form')
    _fpa.postprocessors_nfs_store.nfs_store_browse_list_results(block, data)
  },

  nfs_store_browse_list_results: function (block, data) {
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

      _fpa.postprocessors_nfs_store.handle_item_flags(block, data)
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
  },

  handle_item_flags: function (block, data) {

    block.find('.browse-entry-classifications').each(function () {
      const id = $(this).attr('data-id')
      if (id == null) return

      const retrieval_type = $(this).attr('data-rt')
      const download = data.downloads.filter((value, index, self) => {
        value.id === +id
      })[0]
      if (!download) return

      const item_flags = download.item_flags

      if (!item_flags) return

      var flag_data = {
        item_flags: item_flags
      };

      if (flag_data.item_flags.length == 0) {
        var res = '<span class="no-item-flags"></span>'
      }
      else {
        flag_data.item_type = `nfs_store__manage__${retrieval_type}`;
        flag_data.readonlyview = true;
        var res = _fpa.partials.item_flag_container(flag_data);
      }

      var block = $(`<span class="bem-class-flags">${res}</span>`);
      $(`#container-entry-${nfs_store_container_id}-${id}-${retrieval_type} .bem-class-title`).first().before(block);

    })
  }

};

$.extend(_fpa.postprocessors, _fpa.postprocessors_nfs_store);
$.extend(_fpa.preprocessors, _fpa.preprocessors_nfs_store);
