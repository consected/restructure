_fpa.form_utils = {

  filtered_selector: function(){
    var d = $('select[data-filters-selector]')
    
    var do_filter = function(sel){
        
        var a = sel.attr('data-filters-selector');
        var el = $(a);
        var v = sel.val();
        el.find('option').removeClass('filter-option-show').hide();

        el.find('option[data-filter-id="'+v+'"]').addClass('filter-option-show').show();
        
        el.val(null);
    };
    
    d.each(function(){
        do_filter($(this));
    });
    
    d.on('change', function(){
        do_filter($(this));
    });
  }

};


