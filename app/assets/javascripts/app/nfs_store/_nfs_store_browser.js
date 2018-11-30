_nfs_store.fs_browser = function ($outer) {
    'use strict';

    var get_container_id = function($this) {
      var d = $this.attr('data-container-id');
      if(d) {
        return d;
      }
      else {
        return $this.parents('.container-browser-outer').attr('data-container-id');
      }
    };

    var get_$browser = function() {
      return $('.container-browser-outer[data-container-id="'+container_id+'"] .container-browser');
    };

    var disable_submit = function($this, disable) {
      var disval =  disable ? 'disabled' : null;
      $('#container-browse-submit-'+container_id).prop('disabled', disval);
      $('#container-browse-submit-in-form-'+container_id).prop('disabled', disval);
    };

    var set_submit_caption = function($this, caption) {
      $('#container-browse-submit-'+container_id+' .btn-caption').html(caption);
    };


    var submit_form = function($this) {
      $('#container-browse-submit-in-form-'+container_id).click();
    };

    var refresh = function($this) {
      $outer.removeClass('ajax-running');
      disable_submit($this, true);
      count_downloads($this);
    };

    var folder_action = function($this, e, collapse) {
      e.stopPropagation();
      var $icon = $browser.find('.folder-icon[aria-controls="'+$this.attr('id')+'"]' );
      if(collapse) {
        $icon.addClass('glyphicon-folder-close');
        $icon.removeClass('glyphicon-folder-open');
      }
      else {
        $icon.addClass('glyphicon-folder-open');
        $icon.removeClass('glyphicon-folder-close');
      }
    };

    var set_metadata_views = function($radio) {
      var $b = $outer.find('.container-browser');
      $b.addClass('browser-hide-meta browser-hide-classifications')

      if(!$radio) {
        $radio = $('input[name="container-meta-controls-'+container_id+'"]:checked')
      }

      if($radio) {
        var val = $radio.val();
        $b.removeClass('browser-hide-' + val);
      }

      var $el = $outer.parents('.common-template-item.is-activity-log').first();
      var wasSmall = $el.hasClass('col-md-8');
      var nowSmall = false;
      $el.removeClass('col-md-8 col-lg-6 col-lg-8 col-md-12 col-lg-12');

      if(val == 'classifications')
        $el.addClass('col-md-12 col-lg-12');
      else if(val == 'meta')
        $el.addClass('col-md-12 col-lg-12');
      else {
        nowSmall = true;
        $el.addClass('col-md-8 col-lg-6');
      }
      // Prevent scrolling and resizing if the block has not changed size
      // This prevents the scroll position jumping up and down during load
      // and prevents it shifting during the background refresh due to processing large zips
      if (wasSmall != nowSmall) {
        window.setTimeout(function(){
          _fpa.utils.jump_to_linked_item($el, null, {no_highlight: true});
          _fpa.form_utils.resize_children($outer);
        }, 100);
      }

    };

    var count_downloads = function($this) {
      var all_checked = $browser.find('.container-entry input[type="checkbox"]:checked');
      var all_checked_folders = $browser.find('.container-folder input[type="checkbox"]:checked');
      var total_checked = all_checked.length;

      set_submit_caption($this, 'download ' + total_checked + ' ' + (total_checked != 1 ? 'files' : 'file') );
      disable_submit($this, !total_checked);

      $browser.find('.container-entry.checked').removeClass('checked');
      all_checked.each(function() {
        if($(this).is(':checked'))
          $(this).parent().addClass('checked');
      });

      $browser.find('.container-folder.checked').removeClass('checked');
      all_checked_folders.each(function() {
        if($(this).is(':checked'))
          $(this).parent().addClass('checked');
      });
    };


    var entry_checked = function($this) {
      var folder = $this.parents('.container-folder-items').first();
      var path = folder.attr('data-folder-items');
      var $checkboxes_in_folder = folder.find('> .container-entry input[type="checkbox"]');
      var all_checked = $checkboxes_in_folder.length == $checkboxes_in_folder.closest(':checked').length;

      $browser.find('.container-folder input[type="checkbox"][data-folder-path="'+path+'"] ').prop('checked', all_checked);

      count_downloads($this);
    };

    var folder_checked = function($this) {
      var path = $this.attr('data-folder-path');
      var checked = $this.is(':checked');
      $browser.find('.container-folder-items[data-folder-items="'+path+'"] li input[type="checkbox"]').prop('checked', checked);
      count_downloads($this);
    };

    var container_id = get_container_id($outer);
    var $browser = get_$browser();

    $outer.on('change', '.container-browser .container-entry input[type="checkbox"]', function() {
      entry_checked($(this));
    }).on('change', '.container-browser .container-folder input[type="checkbox"]', function() {
      folder_checked($(this));
    }).on('hidden.bs.collapse', '.container-browser .container-folder-items', function(e) {
      folder_action($(this), e, true);
    }).on('shown.bs.collapse', '.container-browser .container-folder-items', function(e) {
      folder_action($(this), e, false);
    }).on('click', '.container-browse-submit', function() {
      var target = $($(this).attr('data-target-browser'));
      submit_form(target);
      disable_submit(target, true);
      set_submit_caption(target, "request submitted");
    });

    $(document).on('click', '.refresh-container-list[data-container-id="'+container_id+'"]', function(e) {
      $outer.find('.container-browser').addClass('ajax-running');
    }).on('change', 'input[name="container-meta-controls-'+container_id+'"]', function(e) {
        set_metadata_views($(this));
    });

    var classification_radio = $('input[name="container-meta-controls-'+container_id+'"]:checked');
    set_metadata_views(classification_radio);
    refresh($outer);


    return this;
  };
