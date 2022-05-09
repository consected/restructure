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
      data.formData.activity_log_id = al.activity_log_id
      data.formData.activity_log_type = al.activity_log_type

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
