_fpa.loaded.default = function(){
    $('.dropdown-toggle').dropdown();
    _fpa.form_utils.setup_chosen();
    $('table').each(function(){
       var c = $(this).attr('class');
       if(c == null || c === '')
           $(this).addClass('table');
    });
   
    _fpa.timed_flash_fadeout();
    
    
    $('#nav_q').on('keypress', function(){
        $('#nav_q_pro_id').val('');
    }).on('change', function(){
        var v = $(this).val();
        if(v && v != '')
            $('form.navbar-form').submit();
    });
    
    $('#nav_q_pro_id').on('keypress', function(){
        $('#nav_q').val('');
    }).on('change', function(){
        var v = $(this).val();
        if(v && v != '')
            $('form.navbar-form').submit();
    });
    
    $(document).on('click', '[data-toggle="clear"]', function(){
        var a = $(this).attr('data-target');
        $(a).html('').removeClass('in');
    });
    
    $(document).on('click', '[data-toggle="scrollto-result"]', function(){
        var a = $(this).attr('data-result-target');
        if(!a || a=='')
            a = $(this).attr('data-target');
        $(window).scrollTo(a, 100);
    });
    
    
    
    _fpa.form_utils.filtered_selector();

    if(_fpa.loaded[_fpa.status.controller])
        _fpa.loaded[_fpa.status.controller]();
};
