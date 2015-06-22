$(document).ready(function(){
    var forms = $('.search_master');
    
    forms.each(function(){
        var f = $(this);
        f.find('input, select').on('change', function(e){
            window.setTimeout(function(){
            f.find('input[type="submit"]').click();  
            },1);
        });
    });

    $('#master-search-advanced').on('show.bs.collapse', function () {
        $('#master-search-simple').collapse('hide');
      });
    $('#master-search-simple').on('show.bs.collapse', function () {
        $('#master-search-advanced').collapse('hide');
    });
    
    $('.clear-fields').on('click', function(ev){
        ev.preventDefault();
        forms.find('input, select').not('[type="submit"], [type="hidden"]').val(null);
    });
    
});