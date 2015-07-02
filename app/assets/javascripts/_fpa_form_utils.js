_fpa.form_utils = {

  setup_chosen: function(block){
    if(!block) block = $(document);

    var sels = block.find('select[multiple]').not('.attached-chosen');
    // Place the chosen setup into a timeout, since it is time-consuming for a large number
    // of "tag" fields, and blocks the main thread otherwise.
    sels.each(function(){
        var sel = $(this);
        window.setTimeout(function(){               
            sel.chosen({width: '100%'}).addClass('attached-chosen');
        }, 1);
    });
  },

  filtered_selector: function(){
    var d = $('select[data-filters-selector]');
    
    var do_filter = function(sel){
        
        var a = sel.attr('data-filters-selector');
        var el = $(a);
        var v = sel.val();
        el.find('option[data-filter-id]').removeClass('filter-option-show').hide();

        el.find('option[data-filter-id="'+v+'"]').addClass('filter-option-show').show();
        
        el.each(function(){
            var ela = $(this).find('option:selected').attr('data-filter-id');
        
            if(ela != v)
                $(this).val(null);
        });
        
    };
    
    d.not('.attached-filter').each(function(){
        do_filter($(this));
    });
    
    d.not('.attached-filter').on('change', function(){
        do_filter($(this));
    }).addClass('attached-filter');
  }

};


