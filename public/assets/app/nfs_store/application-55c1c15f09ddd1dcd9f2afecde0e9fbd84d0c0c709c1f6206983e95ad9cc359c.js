var _nfs_store = {};
_nfs_store.fs_browser = function ($outer) {
  'use strict';

  var last_count = {};

  var get_container_id = function ($this) {
    var d = $this.attr('data-container-id');
    if (d) {
      return d;
    }
    else {
      return $this.parents('.container-browser-outer').attr('data-container-id');
    }
  };

  var get_$browser = function () {
    return $('.container-browser-outer[data-container-id="' + container_id + '"] .container-browser');
  };

  var disable_submit = function ($this, disable, total_checked, total_checked_folders) {
    disable_submit_type('download', $this, disable);
    disable_submit_type('trash', $this, disable);
    disable_submit_type('move-files', $this, disable);

    if (!disable) {
      disable = total_checked != 1;
      disable_submit_type('rename-file', $this, disable);
      disable_trigger_file_actions($this, disable);
      disable = total_checked_folders != 1;
      disable_submit_type('rename-folder', $this, disable);
      disable = total_checked == 0;
      disable_trigger_file_actions($this, disable);
    }
    else {
      disable_submit_type('rename-file', $this, disable);
      disable_submit_type('rename-folder', $this, disable);
      disable_trigger_file_actions($this, disable);
    }

  };

  var disable_submit_type = function (name, $this, disable) {

    if (!disable) {
      var can = $browser.attr('data-can-submit-' + name) == "true";
      disable = !can;
    }

    var disval = disable ? 'disabled' : null;

    $('#container-browse-' + name + '-' + container_id).attr('disabled', disval);
    $('#container-browse-' + name + '-in-form-' + container_id).attr('disabled', disval);
  };

  var disable_trigger_file_actions = function ($this, disable) {

    $(`[data-target-browser="#container-browser-${container_id}"][data-can-trigger-actions]`).each(function () {
      var name = $(this).attr('data-trigger-file-action');

      if (!disable) {
        var can = $(this).attr('data-can-trigger-actions') == "true";
        disable = !can;
      }

      var disval = disable ? 'disabled' : null;

      $(this).attr('disabled', disval);
      $(`#container-browse-trigger-file-action-${name}-in-form-${container_id}`).attr('disabled', disval);
    })

  };

  var set_submit_download_caption = function ($this, caption) {
    $('#container-browse-download-' + container_id + ' .btn-caption').html(caption);
  };


  var submit_download_form = function ($this) {

    var btn = $('#container-browse-download-in-form-' + container_id);

    var form = btn.parents('form').first();
    form.removeAttr("data-remote");
    form.removeData("remote");

    $('body').addClass('prevent-page-transition');
    btn.click();
  };


  var submit_action_form = function ($this, action, extra_params) {

    var btn = $('#container-browse-' + action + '-in-form-' + container_id);


    var form = btn.parents('form').first();
    if (!form || form.length === 0) return;

    var form_ep = form.find('.extra_params');

    form_ep.html('');

    if (extra_params) {
      for (var k in extra_params) {
        if (extra_params.hasOwnProperty(k)) {
          var v = extra_params[k];
          v = v.replace(/"/, '&quot;')
          form_ep.append('<input type="hidden" name="nfs_store_download[' + k + ']" value="' + v + '" />');
        }
      }
    }


    form.attr('data-remote', 'true');
    form[0].app_callback = function () {
      refresh_browser($outer, container_id);
    }

    $('body').addClass('prevent-page-transition');
    btn.click();
  };

  var refresh_browser = function (outer, container_id) {
    var $refresh_btn = $('.refresh-container-list[data-container-id="' + container_id + '"]');
    // Only allow one refresh every 8 seconds (don't do 10, as this will conflict with the recurring refresh time)
    // We can't do this on the refresh button itself, since the remote event is not easy to stop
    var time = (new Date).getTime() / 1000;
    var dt = $refresh_btn.attr('data-last-click-at');
    if (dt && time - parseInt(dt) < 8) {
      var $browse_container = outer.find('.browse-container');
      // Do reset the refresh counter to zero though, so we wait for this action to finish
      $browse_container.attr('data-refresh-count', '0')
      return;
    }

    $refresh_btn.click();
    refresh(outer);
  };


  var refresh = function ($this) {
    $outer.removeClass('ajax-running');
    disable_submit($this, true);
    count_downloads($this);
  };

  var folder_action = function ($this, e, collapse) {
    e.stopPropagation();
    var $icon = $browser.find('.folder-icon[aria-controls="' + $this.attr('id') + '"]');
    if (collapse) {
      $icon.removeClass('folder-open');
      $icon.addClass('glyphicon-folder-close');
      $icon.removeClass('glyphicon-folder-open');
      $icon.attr('title', 'expand folder');
    }
    else {
      $icon.addClass('folder-open');
      $icon.addClass('glyphicon-folder-open');
      $icon.removeClass('glyphicon-folder-close');
      $icon.attr('title', 'shrink folder');
    }
  };

  var set_metadata_views = function ($radio, preventJump) {
    var $b = $outer.find('.container-browser');
    $b.addClass('browser-hide-meta browser-hide-classifications')

    if (!$radio) {
      $radio = $('input[name="container-meta-controls-' + container_id + '"]:checked')
    }

    if ($radio) {
      var val = $radio.val();
      $b.removeClass('browser-hide-' + val);
    }

    var $els = $outer.parents('.multi-model-reference-result .is-activity-log');
    if ($els.length > 0) return;
    var $el = $outer.parents('.common-template-item.is-activity-log').first();

    var prevent_nfs_resize = $el.hasClass('prevent_nfs_resize');

    if (!prevent_nfs_resize) {
      var wasSmall = $el.hasClass('col-md-8');
      var nowSmall = false;
      $el.removeClass('col-md-8 col-lg-6 col-lg-8 col-md-12 col-lg-12');

      if (val == 'classifications')
        $el.addClass('col-md-12 col-lg-12');
      else if (val == 'meta')
        $el.addClass('col-md-12 col-lg-12');
      else {
        nowSmall = true;
        $el.addClass('col-md-8 col-lg-6');
      }
      // Prevent scrolling and resizing if the block has not changed size
      // This prevents the scroll position jumping up and down during load
      // and prevents it shifting during the background refresh due to processing large zips
      if (wasSmall != nowSmall) {
        window.setTimeout(function () {
          if (!preventJump) {
            _fpa.utils.jump_to_linked_item($el, null, { no_highlight: true });
          }
          _fpa.form_utils.resize_children($outer);
        }, 100);
      }
    }


  };

  var count_downloads = function ($this) {
    var all_checked = $browser.find('.container-entry input[type="checkbox"]:checked');
    var all_checked_folders = $browser.find('.container-folder input[type="checkbox"]:checked');
    var total_checked = all_checked.length;
    var total_checked_folders = all_checked_folders.length;

    var first_file = all_checked.first().siblings('.browse-filename').html();

    var $folders = all_checked.first().parents('.container-folder-items');
    var $folder_top = $folders.not('[data-folder-items="."]').last();
    if ($folder_top.length == 0 || $folder_top.attr('data-folder-items').indexOf('__mounted-archive__') == -1) {
      $folder_top = $folders.last();
    }
    $folder_top = $folder_top.prev().add($folder_top);
    var $folder_in = $folders.first();
    $folder_in = $folder_in.prev().add($folder_in);

    set_submit_download_caption($this, 'download ' + total_checked + ' ' + (total_checked != 1 ? 'files' : 'file'));
    disable_submit($this, !total_checked, total_checked, total_checked_folders);

    $browser.find('.container-entry.checked').removeClass('checked');
    all_checked.each(function () {
      if ($(this).is(':checked'))
        $(this).parent().addClass('checked');
    });

    $browser.find('.container-folder.checked').removeClass('checked');
    all_checked_folders.each(function () {
      if ($(this).is(':checked'))
        $(this).parent().addClass('checked');
    });

    last_count = { total_checked: total_checked, total_checked_folders: total_checked_folders, first_file: first_file, $folder_top: $folder_top, $folder_in: $folder_in };

    return last_count;
  };


  var entry_checked = function ($this) {
    var folder = $this.parents('.container-folder-items').first();
    var path = folder.attr('data-folder-items');
    var $checkboxes_in_folder = folder.find('> .container-entry input[type="checkbox"]');
    var all_checked = $checkboxes_in_folder.length == $checkboxes_in_folder.closest(':checked').length;

    $browser.find('.container-folder input[type="checkbox"][data-folder-path="' + path + '"] ').prop('checked', all_checked);

    count_downloads($this);
  };

  var folder_checked = function ($this) {
    var path = $this.attr('data-folder-path');
    var checked = $this.is(':checked');
    $browser.find('.container-folder-items[data-folder-items="' + path + '"] li input[type="checkbox"]').prop('checked', checked);
    count_downloads($this);
  };

  var submit_modal = function (action) {
    var target = $($(this).attr('data-target-browser'));
    var extra_params = {};
    $modal.find('.container-browse-action-extra-params').each(function () {
      var el = $(this);
      extra_params[el.attr('name')] = el.val();
    });
    submit_action_form(target, action, extra_params);
    disable_submit(target, true);
    $modal.modal('hide');
  };

  var set_move_path = function (v, path) {
    var v = v.replace(/^\.?\/?/, '');

    if (v) {
      if (path) {
        var new_path = [path, v].join('/');
      }
      else {
        var new_path = v;
      }
      var new_path = new_path.replace(/^\.?\/?/, '');
      var new_path = new_path.replace(/^[^\/]+\.__mounted-archive__(\/|$)/, '');

      $modal.find('input[name="new_path"]').val(new_path);
    }
  };

  var set_move_from = function () {
    var new_path = $modal.find('.browse-move-to-folders .container-folder.checked [data-folder-path]').first().attr('data-folder-path');
    if (new_path) {
      var new_path = new_path.replace(/^\.?\/?/, '');
      var new_path = new_path.replace(/^[^\/]+\.__mounted-archive__(\/|$)/, '');
    }

    $modal.find('.container-browser-move-from').html(new_path);
  };

  var container_id = get_container_id($outer);
  var $browser = get_$browser();

  $outer.find('img').on('error', function () {
    $(this).addClass('broken-image')
  }).on('load', function () {
    $(this).addClass('loaded-image')
  });

  $outer.on('change', '.container-browser .container-entry input[type="checkbox"]', function () {
    entry_checked($(this));
  }).on('change', '.container-browser .container-folder input[type="checkbox"]', function () {
    folder_checked($(this));
  }).on('hidden.bs.collapse', '.container-browser .container-folder-items', function (e) {
    folder_action($(this), e, true);
  }).on('shown.bs.collapse', '.container-browser .container-folder-items', function (e) {
    folder_action($(this), e, false);
  }).on('click', '.container-browse-download', function () {
    var target = $($(this).attr('data-target-browser'));
    submit_download_form(target);
    disable_submit(target, true);
    set_submit_download_caption(target, "request submitted");
  }).on('click', '.container-browse-trash-submit', function () {
    var target = $($(this).attr('data-target-browser'));
    submit_action_form(target, 'trash');
    disable_submit(target, true);
  }).on('click', '.container-browse-trigger-file-action', function () {
    var target = $($(this).attr('data-target-browser'));
    var action_id = $(this).attr('data-trigger-file-action');
    submit_action_form(target, 'trigger-file-action-' + action_id);
    disable_submit(target, true);
    window.setTimeout(function () {
      refresh_browser($outer, container_id);
    }, 10000)

  }).on('click', '.container-browse-move-files', function () {
    var target = $($(this).attr('data-target-browser'));
    var msg = $('#container-browse-move-files-form-' + container_id).html();
    var title = 'Move Files to a folder';
    _fpa.show_modal(msg, title);

    var $ff = last_count.$folder_top;
    var $move_folders = $ff.find('.container-folder, .container-folder-items');
    var $bmtf = $modal.find('.browse-move-to-folders');
    $ff.clone().appendTo($bmtf);

    if ($ff.first().hasClass("root-folder")) {
      $bmtf.find('.container-folder-items').each(function () {
        var $this = $(this);
        if ($this.attr('data-folder-items').indexOf('.__mounted-archive__') >= 0) {
          $this.prev().remove();
          $this.remove();
        }
      });
    }

    $bmtf.find('.container-entry').remove();
    $bmtf.find('.container-folder-items').each(function () {
      var $this = $(this);
      var $folder_line = $this.prev();
      var id = $this.attr('id');
      $this.attr('id', 'bmtf-' + id);
      $this.attr('aria-expanded', 'true');
      $this.addClass('in');
      var dfp = $this.attr('data-folder-items');
      var $newf = $('<a class="container-add"><input type="checkbox" class="container-folder-add hidden" data-folder-path="' + dfp + '" /> <span class="glyphicon glyphicon-plus"></span> folder</a>').appendTo($folder_line);
      $newf.on('click', function (e) {
        e.preventDefault();
        $(this).find('input.container-folder-add').prop('checked', true).change();

        var $cnfn = $modal.find('.container-new-folder-name');
        $cnfn.slideDown();
        set_move_path($cnfn.val(), dfp);

        $cnfn.on('keyup', function () {
          var v = $(this).val();
          set_move_path(v, dfp);
        });

        $folder_line.append($cnfn);
      });
    });

    $bmtf.find('.folder-icon').each(function () {
      var $this = $(this);
      var href = $this.attr('href');
      if (href) {
        var new_href = '#bmtf-' + href.replace(/^#/, '');
        $this.attr('href', new_href);
        $this.attr('aria-controls', new_href);
      }
      $this.addClass('folder-open glyphicon-folder-open').removeClass('glyphicon-folder');
    });

    var $checkboxes = $bmtf.find('input[type="checkbox"]')

    $checkboxes.each(function () {
      var $this = $(this);
      $this.prop('checked', false);
    });

    $modal.find('.container-new-folder-name').parent().slideUp();

    $bmtf.on('change', 'input[type="checkbox"]', function () {
      var $this = $(this);
      var dfp = $this.attr('data-folder-path');
      $checkboxes.not('[data-folder-path="' + dfp + '"]').prop('checked', false);

      var $cnfn = $modal.find('.container-new-folder-name');
      if (!$this.hasClass('container-folder-add'))
        $cnfn.slideUp();

      set_move_path(dfp);
    });

    set_move_from();


  }).on('click', '.container-browse-rename-file', function () {
    var target = $($(this).attr('data-target-browser'));
    var msg = $('#container-browse-rename-file-form-' + container_id).html();
    var title = 'Rename file';
    _fpa.show_modal(msg, title);
    $modal.find('input[name="new_name"]').val(last_count.first_file);
  });

  var $modal = $('#primary-modal');

  $modal.on('click', '.container-browse-move-files-submit', function () {
    submit_modal('move-files');
  }).on('click', '.container-browse-rename-file-submit', function () {
    submit_modal('rename-file');
  });

  $(document).on('click', '.refresh-container-list[data-container-id="' + container_id + '"]', function (e) {
    $outer.find('.container-browser').addClass('ajax-running');
    var time = (new Date).getTime() / 1000;
    $(this).attr('data-last-click-at', time);
  }).on('change', 'input[name="container-meta-controls-' + container_id + '"]', function (e) {
    set_metadata_views($(this));
  });

  var classification_radio = $('input[name="container-meta-controls-' + container_id + '"]:checked');
  set_metadata_views(classification_radio, true);
  refresh($outer);


  return this;
};
_nfs_store.uploader = function ($outer) {
  'use strict';

  var fileupload_config = {
    url: '/nfs_store/chunk',
    dataType: 'json',
    autoUpload: false,
    dropZone: $outer.find('.upload-dropzone'),
    // acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i,
    // maxFileSize: 99900000000,
    disableImageResize: true,
    singleFileUploads: true,
    sequentialUploads: true,

    // Enable image resizing, except for Android and Opera,
    // which actually support image resizing, but fail to
    // send Blob objects via XHR requests:
    // disableImageResize: /Android(?!.*Chrome)|Opera/.test(window.navigator.userAgent),
    previewMaxWidth: 100,
    previewMaxHeight: 100,
    previewCrop: true,
    maxChunkSize: 10000000,
    headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') }
  };

  // From https://stackoverflow.com/questions/46232170/checksum-md5-before-uploading-file-using-jquery-file-upload

  var md5;
  var md5_callback;
  var md5_exited;
  var chunk_hashes = [];
  var blobSlice = File.prototype.slice || File.prototype.mozSlice || File.prototype.webkitSlice,
    file = null,
    chunkSize = fileupload_config.maxChunkSize,
    chunks = 0,
    currentChunk = 0,
    spark = new SparkMD5.ArrayBuffer(),
    spark_chunk = new SparkMD5.ArrayBuffer();
  var abortClicked;
  var uploadedIds;
  var uploadSet;

  var frOnload = function (e) {

    var chunk_data = e.target.result;
    spark_chunk.reset();
    spark_chunk.append(chunk_data);

    chunk_hashes.push(spark_chunk.end());

    spark.append(chunk_data); // append array buffer
    currentChunk++;
    if (currentChunk < chunks)
      md5Chunk();
    else {
      md5 = spark.end();

      md5_exited = true;
      if (md5_callback)
        md5_callback(md5);

    }
  };

  var frOnerror = function () {
    md5_exited = true;
  };

  function md5Chunk(new_file, callback) {
    if (abortClicked) {
      callback = null;
      return;
    }

    if (new_file) {
      currentChunk = 0;
      md5 = null;
      file = new_file;
      chunks = Math.ceil(file.size / chunkSize);
      md5_callback = callback;
      md5_exited = false;
      chunk_hashes = [];
    }

    var fileReader = new FileReader();
    fileReader.onload = frOnload;
    fileReader.onerror = frOnerror;
    var start = currentChunk * chunkSize,
      end = ((start + chunkSize) >= file.size) ? file.size : start + chunkSize;
    fileReader.readAsArrayBuffer(blobSlice.call(file, start, end));

  };


  var addFileBlock = function (data, index, file, e, that) {
    var $block = $outer.find('.template .file-block').clone(true).attr('data-file-index', index);
    $block.find('.file-name').text(file.name);
    abortClicked = false;

    $block.find('.button-upload-abort').on('click', function () {
      var $this = $(this),
        data = $this.data();
      $this.hide();
      abortClicked = true;
      $block.find('.button-upload-resume').show();
      data.abort();
    }).data(data);

    $block.find('.button-upload-resume').on('click', function () {
      $(this).hide();
      $block.find('.button-upload-abort').show();
      abortClicked = false;
      setBlockReady($block);
      // $.blueimp.fileupload.prototype.options.add.call(that, e, data);
      // setTimeout(function() { data.submit(); }, 100);
      submitNext(that, e);
    });


    $block.find('.started-at').html(new Date().toLocaleTimeString());

    var $context = $outer.find('.data-context');
    $block.appendTo($context);
    $block.data(data);

    var rect = $context.get(0).getBoundingClientRect();
    var not_visible = !(rect.top >= 0 && rect.top <= $(window).height() * 0.8);
    if (not_visible)
      $.scrollTo($context, 0, { offset: -$(window).height() * 0.8 });

    $block.find('.close').on('click', function () {
      $block.slideUp();
    });

    return $block;
  };

  var setBlockComplete = function ($block) {
    $block.removeClass('process-ready').addClass('process-complete');
    $block.removeClass('progress-running');
    removeAbortButton($block);
    console.log('completed upload of file');
  };

  var setBlockFailed = function (error_array, $block) {
    if (!$block)
      $block = getFileBlock();

    if (!error_array.join) error_array = [error_array];
    $block.find('.file-error').text('file upload failed: ' + error_array.join(' | '));
    $block.find('.progress-bar').addClass('progress-bar-failed').removeClass('progress-bar-success');
    $block.find('.progress-bar-status-text').text('failed');
    $block.removeClass('progress-running');
    removeAbortButton($block);
    showAddFilesButton();
  };

  var setBlockReady = function ($block) {
    $block.addClass('process-ready').removeClass('process-complete');
    $block.find('.file-error').text('');
    $block.find('.progress-bar').removeClass('progress-bar-failed').addClass('progress-bar-success');
    $block.find('.progress-bar-status-text').text('processing');

  };

  var removeAbortButton = function ($block) {
    $block.find('.button-upload-abort').hide();
  };

  var showAddFilesButton = function () {
    $outer.find('.fileinput-button').show();
  };
  var hideAddFilesButton = function () {
    $outer.find('.fileinput-button').hide();
  };

  var clearFileBlocks = function () {
    $outer.find('.data-context .file-block[data-file-index]').remove();
  };

  var getFileBlock = function () {
    return $outer.find('.data-context .file-block.process-ready').first();
  };

  var getFileBlocks = function () {
    return $outer.find('.data-context .file-block');
  };

  var errorFromResponse = function (data) {
    var error_array = [];

    var dm = data.jqXHR.responseJSON;
    if (dm && dm.message) {
      error_array.push(dm.message);
      return error_array;
    }

    var dh = data.jqXHR.getResponseHeader('X-Upload-Errors');

    var d = JSON.parse(dh);
    for (var p in d) {
      if (d.hasOwnProperty(p)) {
        error_array.push(p.replace('_', ' ') + ' ' + d[p].join('; '));
      }
    }

    if (error_array.length == 0) {
      error_array.push("unknown server error")
    }

    return error_array;
  }

  var refreshContainerList = function () {
    $outer.find('.refresh-container-list').click();
  };

  var uploadAllDone = function () {
    var al = getActivityLog();
    var containerId = getContainerId();


    var test_params = {
      activity_log_id: al.activity_log_id,
      activity_log_type: al.activity_log_type,
      container_id: containerId,
      do: 'done',
      uploaded_ids: uploadedIds.join(',')
    };

    $.ajax({
      url: fileupload_config.url + '/' + containerId,
      data: test_params,
      type: 'PUT',
      success: function (result) {
        console.log('Sent all done message');
      }
    });
  };

  var getContainerId = function () {
    return $outer.find('#uploader_container_id').val();
  };

  var getActivityLog = function () {
    var b = $outer.find('.nfs-store-container-block');
    return {
      activity_log_id: b.attr('data-activity-log-id'),
      activity_log_type: b.attr('data-activity-log-type')
    }
  };

  var submitNext = function (that, e) {
    var $block = getFileBlock();
    if ($block.length == 0) return;
    var data = $block.data();

    abortClicked = false;
    $block.addClass('progress-running');
    $block.find('.progress-bar-status-text').text('processing');

    uploadSet = uploadSet || (getFileBlocks().length.toString() + '--' + Date.now().toString() + '--' + Math.random().toString());

    md5Chunk(data.files[0], function (md5) {
      if (!data.formData) data.formData = {};
      data.formData.file_hash = md5;
      data.formData.container_id = getContainerId();
      data.formData.upload_set = uploadSet;
      if (data.files[0].relativePath && data.files[0].relativePath != '')
        data.formData.relative_path = data.files[0].relativePath;
      if (chunk_hashes.length == 1)
        data.formData.chunk_hash = chunk_hashes.shift();

      var al = getActivityLog();
      if (that) {

        var test_params = {
          file_name: data.files[0].name,
          file_hash: data.formData.file_hash,
          relative_path: data.formData.relative_path,
          activity_log_id: al.activity_log_id,
          activity_log_type: al.activity_log_type
        };

        $.getJSON(fileupload_config.url + '/' + getContainerId(), test_params, function (result) {
          if (result.result == 'found' && !result.completed) {
            var file_size = result.file_size;
            var chunk_count = result.chunk_count;
            data.uploadedBytes = file_size;

            // Run through the chunk count to get to the correct starting point for MD5 hashes
            for (var i = 0; i < chunk_count; i++) {
              data.formData.chunk_hash = chunk_hashes.shift();
            }

            $.blueimp.fileupload.prototype.options.add.call(that, e, data);
          }

          setTimeout(function () { data.submit(); }, 100);

        }).fail(function (result) {
          var error_array = ['The upload failed'];
          if (result.responseJSON && result.responseJSON.message) {
            error_array = result.responseJSON.message;
          }
          setBlockFailed(error_array);
        });

      } else {
        setTimeout(function () { data.submit(); }, 100);
      }

    });
  }

  $outer.find('.upload-dropzone').on('dragover', function () {
    $(this).addClass('on-drag');
  }).on('dragleave', function () {
    $(this).removeClass('on-drag');
  }).on('drop', function () {
    // Don't allow a any uploads if the fileinput-button is not visible,
    // since this indicates that the uploader is readonly
    if (!$outer.find('.fileinput-button').is(':visible')) {
      console.log('Upload not enabled!');
      return;
    }
    hideAddFilesButton();
    clearFileBlocks();
    $(this).removeClass('on-drag');
  });


  var $main_uploader = $outer.find('input.nfs-store-fileupload').fileupload(fileupload_config).on('click', function () {
    clearFileBlocks();
  }).on('fileuploadadd', function (e, data) {

    if ($outer.find('.container-browser').attr('data-container-writable') == 'false') {
      console.log('Upload not enabled!');
      return;
    }

    hideAddFilesButton();
    var that = this;
    $.each(data.files, function (index, file) {
      var first_file = getFileBlock().length == 0;
      var $block = addFileBlock(data, index, file, e, that);
      if (first_file) {
        uploadedIds = [];
        setTimeout(function () {
          submitNext(that, e);
        }, 1000);
      }
    });

  }).on('fileuploadchunkbeforesend', function (e, data) {
    if (!data.formData) data.formData = {};
    data.formData.chunk_hash = chunk_hashes.shift();
    data.formData.upload_set = uploadSet;
    var $block = getFileBlock();
    $block.find('.progress-bar-status-text').text('uploading');

  }).on('fileuploadchunksend', function (e, data) {
    return !abortClicked;
  }).on('fileuploadprocessalways', function (e, data) {
    console.log('fileuploadprocessalways');
    var index = 0,
      file = data.files[index],
      $block = getFileBlock();

    $block.find('.progress-bar-status-text').text('uploading');
    if (file.error) {
      $block.find('.file-error').text(file.error);
    }

  }).on('fileuploadprogress', function (e, data) {

    var $block = getFileBlock();
    var progress = parseInt(data.loaded / data.total * 100, 10);


    $block.find('.progress .progress-bar').css(
      'width',
      progress + '%'
    );


    var rect = $block.get(0).getBoundingClientRect();
    var not_visible = !(rect.top >= 0 && rect.top <= $(window).height() * 0.8);
    if (not_visible)
      $.scrollTo($block, 0, { offset: -$(window).height() * 0.8 });

  }).on('fileuploaddone', function (e, data) {
    console.log('fileuploadaddone');
    var file = data.result.file;
    var $block = getFileBlock();

    if (file.url) {
      $block.find('.progress-bar-status-text').text('completed');
      uploadedIds.push(file.id);
    } else if (file.error) {
      $block.find('.file-error').text(file.error);
    }

    // setBlockComplete($block);


  }).on('fileuploadfail', function (e, data) {
    var error_array;
    console.log('fileuploadfail');
    if (abortClicked) {
      error_array = ['Upload canceled'];
    }
    else {
      error_array = errorFromResponse(data);
    }
    setBlockFailed(error_array);
  }).on('fileuploadalways', function (e, data) {
    console.log('fileuploadalways');
    var that = this;
    $.each(data.files, function (index) {
      var $block = getFileBlock();
      $block.find('.ended-at').text(new Date().toLocaleTimeString());
      setBlockComplete($block);

      // blocks left to complete?
      var next_block = getFileBlock();
      if (!abortClicked && next_block.length > 0) {
        submitNext(that, e);
      }
      else {
        showAddFilesButton();
        refreshContainerList();
        uploadAllDone();
      }
    })



  }).prop('disabled', !$.support.fileInput)
    .parent().addClass($.support.fileInput ? undefined : 'disabled');
};
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.


;
