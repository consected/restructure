_fpa.loaded.default = function(){
    var has_loaded_callback = false;
    if(_fpa.loaded[_fpa.status.controller]){
        _fpa.loaded[_fpa.status.controller]();
        has_loaded_callback = true;
    }

    _fpa.timed_flash_fadeout();
    _fpa.form_utils.format_block();
    
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
        
};
