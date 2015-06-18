$(document).ready(function(){
    $('.dropdown-toggle').dropdown();
    
    $('table').each(function(){
       var c = $(this).attr('class');
       if(c == null || c === '')
           $(this).addClass('table');
    });
    
});
