_fpa.loaded.default = function(){
    $('.dropdown-toggle').dropdown();
    $('select[multiple]').chosen({width: '100%'});
    $('table').each(function(){
       var c = $(this).attr('class');
       if(c == null || c === '')
           $(this).addClass('table');
    });
   
    _fpa.timed_flash_fadeout();
    
    
    $('#nav_q').on('keypress', function(){
        $('#nav_q_pro_id').val('');
    });
    
    $('#nav_q_pro_id').on('keypress', function(){
        $('#nav_q').val('');
    });
    

    if(_fpa.loaded[_fpa.status.controller])
        _fpa.loaded[_fpa.status.controller]();
};
