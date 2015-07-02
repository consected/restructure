_fpa.form_utils = {
    // Although it would be appropriate to make a real object out of these functions,
    // convenience calling them individually on an ad-hoc basis around the code base does
    // not make this a good choice.

    resize_labels : function(block, data){
        block.find('.list-group').not('.attached-resize-labels').each(function(){
            // Cheap optimization to make the UI feel more responsive in large result sets
            var self = $(this);
            window.setTimeout(function(){
                var wmax = 0;
                var all = self.find('.list-group-item').not('.is-heading, .is-combo').find('small, label');
                all.css({display: 'inline-block', whiteSpace: 'nowrap'});
                all.each(function(){
                    var wnew = $(this).width();
                    if(wnew > wmax)
                        wmax = wnew;
                });
                if(wmax>10)
                  all.css({minWidth: wmax, width: wmax}).addClass('list-small-label');
            }, 1);          
            self.addClass('attached-resize-labels');  
        });

    },


    setup_has_value_inputs: function(block){
        
        block.find('input, select').not('.attached-has-value').each(function(){ 
            if($(this).val() != '') 
                $(this).addClass('has-value'); 
            else 
                $(this).removeClass('has-value'); 
        }).addClass('attached-has-value');
    },
  

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

    filtered_selector: function(block){
        if(!block) block = $(document);
        var d = block.find('select[data-filters-selector]').not('.attached-filter');

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

        d.each(function(){
            do_filter($(this));
        }).on('change', function(){
            do_filter($(this));
        }).addClass('attached-filter');
    },

    setup_tablesorter: function(block){
        var ts = block.find('.tablesorter').not('.attached-tablesorter');
        ts.tablesorter( {dateFormat: 'us', headers: {0: {sorter: false}, 8: {sorter: false}}}).addClass('attached-tablesorter'); 
    },

    format_block: function(block){
        _fpa.form_utils.setup_chosen(block);  
        _fpa.form_utils.setup_has_value_inputs(block);
        _fpa.form_utils.resize_labels(block);
        _fpa.form_utils.filtered_selector(block);
        _fpa.form_utils.setup_tablesorter(block);

    }
};


