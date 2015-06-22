$(document).ready(function(){
    $('.dropdown-toggle').dropdown();
    
    $('table').each(function(){
       var c = $(this).attr('class');
       if(c == null || c === '')
           $(this).addClass('table');
    });
   
    _fpa.timed_flash_fadeout();
});
