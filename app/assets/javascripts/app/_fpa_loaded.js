_fpa.loaded.default = function(){


    _fpa.timed_flash_fadeout();
    _fpa.form_utils.format_block();


    $('#nav_q').on('keypress', function(){
        $('#nav_q_pro_id').val('');
        $('#nav_q_id').val('');
    }).on('change', function(){
        var v = $(this).val();
        if(v && v != '')
            $('form.navbar-form').submit();
    });

    $('#nav_q_pro_id').on('keypress', function(){
        $('#nav_q').val('');
        $('#nav_q_id').val('');
    }).on('change', function(){
        var v = $(this).val();
        if(v && v != '')
            $('form.navbar-form').submit();
    });

    $('#nav_q_id').on('keypress', function(){
        $('#nav_q').val('');
        $('#nav_q_pro_id').val('');
    }).on('change', function(){
        var v = $(this).val();
        if(v && v != '')
            $('form.navbar-form').submit();
    });

    $('#use_app_type_select').on('change', function(){
      window.location.href = '/masters/search?use_app_type=' + $(this).val()
    });

    $(document).on('click', 'a[disabled], btn[disabled]', function(ev) {
      ev.preventDefault();
    });
    // Perform the controller callback only after everything else is in place
    // Otherwise we can break some standard functionality by performing on change type
    // handlers out of order
    var has_loaded_callback = false;
    if(_fpa.loaded[_fpa.status.controller]){
        _fpa.loaded[_fpa.status.controller]();
        has_loaded_callback = true;
    }

    // Trigger a warning if user tries to print without using the app functionality
    window.onbeforeprint = _fpa.printing.beforePrintHandler;
    window.onafterprint = _fpa.printing.afterPrintHandler;

    // Allow Safari to handle onbeforeprint
    var mediaQueryList = window.matchMedia('print');
    mediaQueryList.addListener(function(mql) {
      if(mql.matches) {
        _fpa.printing.beforePrintHandler();
      }
    });
    var mediaQueryList = window.matchMedia('screen');
    mediaQueryList.addListener(function(mql) {
      if(mql.matches) {
        _fpa.printing.afterPrintHandler();
      }
    });

    $('#print-action').click(function (){
      _fpa.printing.appPrintHandler();
    });



    // Finally, if a hash is set in the URL, jump to it:
    var target = window.location.hash;
    // If no target provided, check if a login page previously cached one and use it instead
    if (!target && !$('body.sessions').length) {
      var hash_res = _fpa.cache('login-redirect-hash');
      target = hash_res && hash_res.hash;
      _fpa.set_cache('login-redirect-hash', {})
    }

    // Ensure a sensible target is passed
    if(target && target.length > 5) {
      // If we are on a login page, we need to store the hash, since it isn't passed to the server
      if($('body.sessions').length) {
        _fpa.set_cache('login-redirect-hash', {hash: target});
      }
      else {
        window.setTimeout(function(){
          console.log('Jumping to linked target based on hash')
          _fpa.utils.jump_to_linked_item(target, null, {no_highlight: true});
        }, 1000);
      }

    }
};
