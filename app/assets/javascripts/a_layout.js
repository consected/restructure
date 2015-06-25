$(document).ready(function(){
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
    
    $('form').not('.navbar-form').find('input, select').on('keypress', function(){
        $('.navbar-form input[type="text"]').val('');
    });
    
});
