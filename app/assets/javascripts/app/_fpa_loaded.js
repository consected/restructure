_fpa.loaded.preload = function () {

  $('body').addClass('page-loading');

  $(document).on('change', '#use_app_type_select', function () {
    window.location.href = '/masters/search?use_app_type=' + $(this).val()
  });

  $(document).on('click', 'a[disabled], btn[disabled]', function (ev) {
    ev.preventDefault();
  });


  window.addEventListener('focus', function () {
    // Check the session timeout
    if (_fpa.status.session.is_counting) _fpa.status.session.count_down();

    // Check if another tab has changed the app type
    if (_fpa.state.current_user) {
      var atid = _fpa.state.current_user.app_type_id;
      var prev_atid = window.localStorage.getItem('session_app_type_id');
      if (atid && prev_atid && prev_atid != atid) {
        _fpa.clear_flash_notices();
        _fpa.flash_notice(`The application being used has switched in another tab. To avoid issues you should <a class="btn btn-default" href="/pages/app_home">reopen this page<a>`, 'warning')
      }
    }

    // Force a reload of images when the window gains focus
    $('.image-to-load').each(function () {
      $(this)[0].src = `${$(this)[0].src}#`
    })
  })
};
_fpa.loaded.default = function () {

  _fpa.cache.clean();

  _fpa.timed_flash_fadeout();
  _fpa.form_utils.format_block();

  // Setup handler for each crosswalk attr search field in the nav bar
  for (var i in _fpa.state.crosswalk_attrs) {
    var field = _fpa.state.crosswalk_attrs[i];
    $('#external_id_' + field).on('keypress', function () {
      $('.nav-external-id-search').not('#' + $(this).prop('id')).val('');
      $('#nav_q_id').val('');
    }).on('change', function () {
      var v = $(this).val();
      if (v && v != '')
        $('form.navbar-form').submit();
    });
  }

  $('#nav_q_id').on('keypress', function () {
    $('.nav-external-id-search').val('');
  }).on('change', function () {
    var v = $(this).val();
    if (v && v != '')
      $('form.navbar-form').submit();
  });


  // Perform the controller callback only after everything else is in place
  // Otherwise we can break some standard functionality by performing on change type
  // handlers out of order
  var has_loaded_callback = false;
  if (_fpa.loaded[_fpa.status.controller]) {
    _fpa.loaded[_fpa.status.controller]();
    has_loaded_callback = true;
  }

  // Allow for _fpa.loaded.custom to be defined in the page ui template to call at load time
  if (_fpa.loaded.custom) {
    _fpa.loaded.custom();
  }


  // Trigger a warning if user tries to print without using the app functionality
  window.onbeforeprint = _fpa.printing.beforePrintHandler;
  window.onafterprint = _fpa.printing.afterPrintHandler;

  // Allow Safari to handle onbeforeprint
  var mediaQueryList = window.matchMedia('print');
  mediaQueryList.addListener(function (mql) {
    if (mql.matches) {
      _fpa.printing.beforePrintHandler();
    }
  });
  var mediaQueryList = window.matchMedia('screen');
  mediaQueryList.addListener(function (mql) {
    if (mql.matches) {
      _fpa.printing.afterPrintHandler();
    }
  });

  $('#print-action').click(function () {
    _fpa.printing.appPrintHandler();
  });

  if (_fpa.state.current_user.sign_in_count < 3 && $('body.rails-env-test').length == 0 && _fpa.status.controller !== 'registrations') {
    const key_viewed_intro = `viewed-introduction-${_fpa.state.current_user.email}`;
    var viewed = localStorage.getItem(key_viewed_intro);
    if (!viewed) {
      var help_icon = $('a[data-target="#help-sidebar"]');
      var help_href = help_icon.attr('href');
      help_icon.attr('href', '/help/user_reference/main/first_login.md?display_as=embedded').click()
      window.setTimeout(function () {
        help_icon.attr('href', help_href);
      })

    }
    localStorage.setItem(key_viewed_intro, true);
  }

  // Finally, if a hash is set in the URL, jump to it:
  var target = window.location.hash;

  target = decodeURIComponent(target);
  // If no target provided, check if a login page previously cached one and use it instead
  if (!target && !$('body.sessions').length) {
    var hash_res = _fpa.cache.fetch('login-redirect-hash');
    target = hash_res && hash_res.hash;
    _fpa.cache.store('login-redirect-hash', {})
  }

  // Ensure a sensible target is passed
  if (target && target.length > 5) {
    // If we are on a login page, we need to store the hash, since it isn't passed to the server
    if ($('body.sessions').length) {
      _fpa.cache.store('login-redirect-hash', { hash: target });
    }
    else {

      var targets = target.split(':');
      var num_targets = targets.length;
      var i = 0;
      var attempts = 0;
      _fpa.state.prevent_jump = targets[num_targets - 1];

      var timed_jump = function (i) {
        var target = targets[i];
        if (!target) {
          // No more targets to try.
          // Prevent additional jumps for a while then exit
          window.setTimeout(function () {
            _fpa.state.prevent_jump = false;
          }, 10000);
          return;
        }

        window.setTimeout(function () {
          console.log('Jumping to linked target based on hash')
          // Highlight if this is the last target and the number of targets > 1
          console.log(target);
          _fpa.utils.jump_to_linked_item(target, null, { no_highlight: !(num_targets > 1 && (i + 1 == num_targets)) });

          // Wait a little then test if the target is there (if it is an id target)
          // If not try a few more times
          window.setTimeout(function () {
            if (target[0] == '#') {
              if ($(target).length == 0 && attempts < 8) {
                attempts++;
                timed_jump(i);
              }
              else {
                timed_jump(i + 1);
              }
            }
            else {
              timed_jump(i + 1);
            }
          }, 1000);
        }, 1000);
      }


      timed_jump(0);


    }
  }



  $(document).on('click', 'a', function () {
    var href = $(this).attr('href');
    var data_remote = $(this).attr('data-remote');
    if (!href || data_remote) return;
    if (href.indexOf('/nfs_store/downloads/') >= 0) {
      $('body').addClass('prevent-page-transition');
    }
  });

  window.onbeforeunload = function (ev) {

    if ($('body').hasClass('prevent-page-transition')) {
      $('body').removeClass('prevent-page-transition');
      return
    }

    if ($('.common-template-item .field-was-changed, .new-block .field-was-changed').length) {
      ev.preventDefault();
      return ev.returnValue = 'You have unsaved data. Are you sure you want to navigate away?';
    }

    $('body').addClass('page-transition');
  }

  // Prevent page change, especially with a back button...
  // For example where a full screen overlay such as the secure viewer
  // might lead users to use "back" rather than the in page close button
  window.addEventListener('popstate', function (event) {
    if (!$('body').hasClass('prevent-page-change')) return;

    if (_fpa.page_transition_callback) _fpa.page_transition_callback();
    history.pushState(null, null, document.referrer);
  })

  $('a.on-loaded-auto-click').not('[disabled], .clicked-on-loaded-auto-click').each(function () {
    $(this).click();
  }).addClass('clicked-on-loaded-auto-click')

  $('body').removeClass('page-loading');
};
