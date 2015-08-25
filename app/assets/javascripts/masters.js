/*
 * Functionality specific to the FPHS Phase 1 app are found here
 * The aim is to keep most of the non-generic functionality outside of the main _fpa*.js files
 * 
 */

_fpa.masters = {
    
    max_results: 100,
    
    // Function called when the main search page loads, initializing seach form specific functionality    
    set_fields_to_search: function(){
        var forms = $('.search_master');
        
        // There are currently two search forms available. Step through each of these in turn
        forms.each(function(){
            var f = $(this);
            // For every input and drop down on the form that is not a \
            // typeahead field and is not already processed
            // check for changes
            // We add a class attached-change at the end to indicate that this field has been
            // has been processed and should not have another listener attached. Can avoid hard to debug 
            // issues and provide extra information when looking at what has and hasn't been changed in the DOM
            f.find('input, select').not('.tt-input, .attached-change').on('change', function(e){
                // Cancel any search-related Ajax requests that are still running
                _fpa.cancel_remote();
                
                
                // Handle the [data-only-for] marked up fields as special cases. 
                // These fields will not automatically submit the form when changed, since they
                // are typically used to filter the content of a related select field.
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
                    // Assuming that we are not in data-only-for field, and all the fields on the form are not null,
                    // then fire a submit
                    // We do this within a timeout, to allow any DOM changes and CSS transitions to smoothly work through
                    // otherwise the result is a very jerky experience
                    window.setTimeout(function(){                        
                        f.find('input[type="submit"]').click();  
                    },1);
                }
                // Clean up after ourselves
                $('.prevent-submit').removeClass('prevent-submit');

            }).addClass('attached-change');
            
            // Specifically for typeahead fields, we need to explicitly submit on blur. We assume that a typeahead can not 
            // be a data-only-for field
            f.find('input.tt-input').not('.attached-change').on('blur', function(e){
                window.setTimeout(function(){                    
                    f.find('input[type="submit"]').click();  
                },1);
            }).addClass('attached-change');
        }).on('keypress', function(e){
            // On any keypress inside a form, cancel an existing ajax search, since the user is probably doing something else
            _fpa.cancel_remote();
        }).on('submit', function(){
            // When we submit the form, give the user a visual spinner so they know what's going on
            // This also clears existing search results to make it clear when a result is complete
            $('#master_results_block').html('<h3 class="text-center"><span class="glyphicon glyphicon-search search-running"></span></h3>');
        });
        
        $('.clear-fields').not('.attached-clear-fields').on('click', function(ev){
            
            ev.preventDefault();
            // Clear all values in the form
            forms.find('input, select').not('[type="submit"], [type="hidden"]').val(null).removeClass('has-value');
            // Handle the "Chosen" tag fields 
            $('select[multiple]').trigger('chosen:updated');
            // Clear any existing results
            $('#master_results_block').html('<h3 class="text-center"></h3>');
            // Clear the results count 
            $('#search_count_simple').html('');
            $('#search_count').html('');
        }).addClass('attached-clear-fields');
    

    }
    
};

// Page specific loaded callback
_fpa.loaded.masters = function(){
    
    _fpa.masters.set_fields_to_search();
    
    // Handle the switch between the advanced and simple forms
    $('#master-search-advanced').on('show.bs.collapse', function () {
        $('#master-search-simple').collapse('hide');
      });
    $('#master-search-simple').on('show.bs.collapse', function () {
        $('#master-search-advanced').collapse('hide');
    });
    
    // On any entry in a form, clear the entries in the navbar search forms so there is no confusion
    // over what is being used
    $('form').not('.navbar-form').find('input, select').on('keypress change', function(){
        $('.navbar-form input[type="text"]').removeClass('has-value').val('');
    });

};