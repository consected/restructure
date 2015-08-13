_fpa.masters = {
    
    max_results: 100,
    
    set_fields_to_search: function(){
        var forms = $('.search_master');
    
        forms.each(function(){
            var f = $(this);
            f.find('input, select').not('.tt-input, .attached-change').on('change', function(e){
                _fpa.cancel_remote();
                
                
                var dof = $(this).attr('data-only-for');
                var all_null = true;
                if(dof){
                    // Allow multiple fields, any one of which may be entered                    
                    $(dof).each(function(){
                       var el = $(this);
                       if(el.val() !== null && el.val() !== '' && !el.hasClass('prevent-submit')) all_null = false;
                    });
                }
                if(!dof || !all_null){
                    window.setTimeout(function(){
                        console.log(e);
                        f.find('input[type="submit"]').click();  
                    },1);
                }
                $('.prevent-submit').removeClass('prevent-submit');

            }).addClass('attached-change');
            f.find('input.tt-input').not('.attached-change').on('blur', function(e){
                window.setTimeout(function(){
                    console.log(e);
                    f.find('input[type="submit"]').click();  
                },1);
            }).addClass('attached-change');
        }).on('keypress', function(e){
            _fpa.cancel_remote();
        }).on('submit', function(){
            $('#master_results_block').html('<h3 class="text-center"><span class="glyphicon glyphicon-search search-running"></span></h3>');
        });
        $('.clear-fields').on('click', function(ev){
            
            ev.preventDefault();
            forms.find('input, select').not('[type="submit"], [type="hidden"]').val(null).removeClass('has-value');
            $('select[multiple]').trigger('chosen:updated');
            $('#master_results_block').html('<h3 class="text-center"></h3>');
        });
    

    }
    
};

// Page specific loaded callback
_fpa.loaded.masters = function(){
    
    _fpa.masters.set_fields_to_search();
    
    $('#master-search-advanced').on('show.bs.collapse', function () {
        $('#master-search-simple').collapse('hide');
      });
    $('#master-search-simple').on('show.bs.collapse', function () {
        $('#master-search-advanced').collapse('hide');
    });
    
    
    $('form').not('.navbar-form').find('input, select').on('keypress change', function(){
        $('.navbar-form input[type="text"]').removeClass('has-value').val('');
    });

};