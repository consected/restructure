_fpa.app = {
    set_fields_to_search: function(){
        var forms = $('.search_master');
    
        forms.each(function(){
            var f = $(this);
            f.find('input, select').not('.tt-input, .attached-change').on('change', function(e){
                var dof = $(this).attr('data-only-for');
                var all_null = true;
                if(dof !== null){
                    // Allow multiple fields, any one of which may be entered                    
                    $(dof).each(function(){
                       var el = $(this);
                       if(el.val() !== null && el.val() !== '') all_null = false;
                    });
                }
                if(dof == null || !all_null){
                    window.setTimeout(function(){
                        console.log(e);
                        f.find('input[type="submit"]').click();  
                    },1);
                }

            }).addClass('attached-change');
            f.find('input.tt-input').not('.attached-change').on('blur', function(e){
                window.setTimeout(function(){
                    console.log(e);
                    f.find('input[type="submit"]').click();  
                },1);
            }).addClass('attached-change');
        });
        $('.clear-fields').on('click', function(ev){
            
            ev.preventDefault();
            forms.find('input, select').not('[type="submit"], [type="hidden"]').val(null).removeClass('has-value');
            $('select[multiple]').trigger('chosen:updated');
        });
    

    }
    
};

_fpa.loaded.masters = function(){
    
    _fpa.app.set_fields_to_search();
    
    $('#master-search-advanced').on('show.bs.collapse', function () {
        $('#master-search-simple').collapse('hide');
      });
    $('#master-search-simple').on('show.bs.collapse', function () {
        $('#master-search-advanced').collapse('hide');
    });
    
    
    $('form').not('.navbar-form').find('input, select').on('keypress', function(){
        $('.navbar-form input[type="text"]').val('');
    });

};