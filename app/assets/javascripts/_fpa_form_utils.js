_fpa.form_utils = {
    // Although it would be appropriate to make a real object out of these functions,
    // convenience calling them individually on an ad-hoc basis around the code base does
    // not make this a good choice.

    toggle_expandable: function(block){
        if(block.hasClass('expanded'))
            block.removeClass('expanded');
        else
            block.addClass('expanded');
    },


    // Setup the typeahead prediction for a specific text input element
    setup_typeahead: function(element, list, name){
      
        if(typeof list === 'string')  
          list = _fpa.cache(list);  

        var items = new Bloodhound({
          datumTokenizer: Bloodhound.tokenizers.whitespace,
          queryTokenizer: Bloodhound.tokenizers.whitespace,        
          local: list
        });

        $(element).typeahead({
          hint: true,
          highlight: true,
          minLength: 1,
          autoselect: true
        },
        {
          name: name,
          source: items
        });
    },

    // Resize all labels in a block for nice formatting without tables or fixed widths
    resize_labels : function(block, data){
        if(!block) block = $(document);
        block.find('.list-group:visible').not('.attached-resize-labels').each(function(){
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

    // Indicate items that have been entered on a form, making it visually fast to see
    // when there are many search form inputs
    setup_has_value_inputs: function(block){
        if(!block) block = $(document);
                
        var set_has = function(item){          
            if(item.val() != '') 
                item.addClass('has-value'); 
            else 
                item.removeClass('has-value'); 
        };
        
        var items = block.find('input, select').not('.attached-has-value');
        items.on('change', function(){ 
            set_has($(this));
        }).each(function(){
            set_has($(this));
        }).addClass('attached-has-value');
        
        
    },
  
    // Setup the "chosen" tags on multiple select form elements (also used outside forms for 
    // simple view of tags
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

    // Provide a filtered set of options in a select field, based on the selection of 
    // another field
    // This handle both the initial setup and handling changes made to parent and dependent 
    // select fields
    filtered_selector: function(block){
        if(!block) block = $(document);
        var d = block.find('select[data-filters-selector]').not('.attached-filter');

        var do_filter = function(sel){
            // get the child select fields this should affect
            var a = sel.attr('data-filters-selector');
            var el = $(a);
            // get the current value of the parent selector
            var v = sel.val();
            
            // in all the child select fields hide all possible options
            el.find('option[data-filter-id]').removeClass('filter-option-show').hide();
            // in all the child select fields re-show only those fields matching the parent selector
            el.find('option[data-filter-id="'+v+'"]').addClass('filter-option-show').show();

            // now for each child select field reset it if the current option doesn't match
            // the new parent selection
            el.each(function(){
                // get the data-filter-id (which parent option this belongs to) for any selected items
                var ela = $(this).find('option:selected').attr('data-filter-id');
                // if this option doesn't match the new parent selection
                if(ela != v){
                    // reset the field
                    $(this).val(null).removeClass('has-value');
                    // previously we were triggering a change (maybe to work with chosen?)
                    // this breaks the parent selection for data-only-for fields
                    // and therefore if needed must be reworked                    
                    //
                    // Instead, if the parent selector has a value and we are resetting
                    // the child, add a prevent-submit to prevent the action triggering the
                    // master submit call
                    if(v)
                        $(this).addClass('prevent-submit');
                    else
                        $(this).trigger('change'); // it was changed back to blank, therefore the form has changed enough to submit
                }
            });

        };

        d.each(function(){
            do_filter($(this));
        }).on('change', function(){
            do_filter($(this));
        }).addClass('attached-filter');
    },

    // Use the tablesorter on profile blocks.
    // This has not been generalized at this point and needs attention
    setup_tablesorter: function(block){
        if(!block) block = $(document);
        var tss = block.find('.tablesorter').not('.attached-tablesorter');
        
        tss.each(function(){
           var ts = $(this);
           
           var i = 0;
           var h = {};
           ts.find('thead tr:first th').each(function(){
               if($(this).hasClass('no-sort'))
                   h[i] = {sorter: false};
               i++;
           });
           
           //{0: {sorter: false}}
           ts.tablesorter( {dateFormat: 'us', headers: h}).addClass('attached-tablesorter');  
        });                
    },

    setup_bootstrap_items: function(block){
        if(!block) block = $(document);
        block.find('[data-toggle="tooltip"]').not('.attached_bs').tooltip().addClass('attached_bs');    
        block.find('[data-toggle="popover"]').not('.attached_bs').popover().addClass('attached_bs');;
        block.find('[data-show-popover="auto"]').not('.attached_bs').popover('show').addClass('attached_bs');
        block.find('.dropdown-toggle').not('.attached_bs').dropdown().addClass('attached_bs');

        block.find('table').each(function(){
            var c = $(this).attr('class');
            if(c == null || c === '')
                $(this).addClass('table');
         });
   

    },

    setup_data_toggles: function(block){
        if(!block) block = $(document);
        block.on('click', '[data-toggle="clear"]', function(){
            var a = $(this).attr('data-target');
            $(a).html('').removeClass('in');
        });

        block.on('click', '[data-toggle="scrollto-result"]', function(){
            var a = $(this).attr('data-result-target');
            if(!a || a==''){
                a = $(this).attr('data-target');                                
                $(document).scrollTo(a, 100, {offset: -50});
            }
        });

        block.on('click', '[data-toggle="expandable"]', function(){
            _fpa.form_utils.toggle_expandable($(this));
        });

    },

    // Run through all the general formatters for a new block to show nicely
    format_block: function(block){
        if(!block) block = $(document);
        _fpa.form_utils.setup_chosen(block);  
        _fpa.form_utils.setup_has_value_inputs(block);
        _fpa.form_utils.resize_labels(block);
        _fpa.form_utils.filtered_selector(block);
        _fpa.form_utils.setup_tablesorter(block);
        _fpa.form_utils.setup_bootstrap_items(block);
        _fpa.form_utils.setup_data_toggles(block);
    }
};


