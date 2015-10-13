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
        }).on('keypress', function(ev){
            if(ev.keyCode != 13) return;
            var dnf = $(this).attr('data-next-field');
            if(dnf)
                $(dnf).focus();
            var v = $(this).val();
            if(v && v !='')$(this).addClass('has-value');
        });
    },

    // Resize all labels in a block for nice formatting without tables or fixed widths
    resize_labels : function(block, data){
        if(!block) block = $(document);
        block.find('.list-group:visible').not('.attached-resize-labels').each(function(){
            // Cheap optimization to make the UI feel more responsive in large result sets
            var self = $(this);
            
            if(_fpa.processor_handlers && _fpa.processor_handlers.label_changes)
                _fpa.processor_handlers.label_changes(self);
            
            window.setTimeout(function(){
                var wmax = 0;
                var lgi = self.find('.list-group-item').not('.is-heading, .is-combo, .record-meta');
                var all = lgi.find('small, label');
                all.css({display: 'inline-block', whiteSpace: 'nowrap'});
                all.each(function(){
                    var wnew = $(this).width();
                    if(wnew > wmax)
                        wmax = wnew;
                });
                if(wmax>10){
                    if(lgi.parents('form').length === 0){                      
                        lgi.css({paddingLeft: wmax+30}).addClass('labels-resized');                  
                        all.css({minWidth: wmax, width: wmax, marginLeft: -wmax-14}).addClass('list-small-label');
                    }else{
                        all.css({minWidth: wmax+6, width: wmax+6}).addClass('list-small-label');
                    }
                }
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
                sel.chosen({width: '100%', placeholder_text_multiple: 'no tags selected'}).addClass('attached-chosen');
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
            if(!a) return;
            
            var children = $(a);
            if(children.length === 0) return;
            
            // get the current value of the parent selector
            var v = sel.val();
            
            // in all the child select fields hide all possible options
            children.find('option[data-filter-id]').removeClass('filter-option-show').hide();
            // in all the child select fields re-show only those fields matching the parent selector
            var shown = children.find('option[data-filter-id="'+v+'"]').addClass('filter-option-show').show();
            // set attribute on the children, so we can sense this has changed (useful in features specs)
            children.attr('data-parent-filter-id', v);
            
            if (shown.length === 0)
                children.find('option[value=""]').html('-none-');
            else
                children.find('option[value=""]').html('-select-');
            
            // now for each child select field reset it if the current option doesn't match
            // the new parent selection
            children.each(function(){                
                // get the data-filter-id (which parent option this belongs to) for any selected items
                var ela = $(this).find('option:selected').attr('data-filter-id');
                // if this option doesn't match the new parent selection
                if(ela != v){
                    // reset the field
                    $(this).val(null).removeClass('has-value');
                    
                    // If the parent selector has a value and we are resetting
                    // the child, add a prevent-submit to prevent the action triggering another call
                    if(v)
                        $(this).addClass('prevent-submit');
                                        
//                    else                
  //                      $(this).trigger('change'); // it was changed back to blank, therefore the form has changed enough to submit
                }
                do_filter($(this));
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
        
        window.setTimeout(function(){
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
        },100);
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
        block.find('[data-toggle="clear"]').not('.attached-datatoggle').on('click', function(){
            var a = $(this).attr('data-target');
            $(a).html('').removeClass('in');
        }).addClass('attached-datatoggle');

        block.find('[data-toggle="scrollto-result"]').not('.attached-datatoggle').on('click', function(){
            var a = $(this).attr('data-target');                                            
            if(!a || a==''){
                a = $(this).attr('data-result-target');
            }
            if(a){
                // Only jump to the target if the current top and bottom of the block are off screen. Usually we
                // attempt to do this so that users do not have to constantly scroll an edit block into view just to type
                // some data.
                // This is approximate, since forms typically make the block larger, but we are trying to avoid unnecessary
                // scrolling, to keep the page from jumping around for the user where possible.                
                window.setTimeout(function(){
                    var rect = $(a).get(0).getBoundingClientRect(); 
                    var not_visible = !(rect.top >= 0 && rect.bottom < $(window).height());
                    if(not_visible)                    
                        $(document).scrollTo(a, 100, {offset: -50});
                }, 100);
            }
            
        }).addClass('attached-datatoggle');

        block.find('[data-toggle="expandable"]').not('.attached-datatoggle').on('click', function(){
            _fpa.form_utils.toggle_expandable($(this));
        }).addClass('attached-datatoggle');
        
    },
    
    setup_extra_actions: function(block){
        
        block.find('[data-add-icon]').not('.attached-add-icon').each(function(){
            var icon = $(this).attr('data-add-icon');
            var title = $(this).attr('title');
            $(this).attr('title', null);
            
            var action= $(this).attr('data-show-modal');
            
            if(action){
                var h = $('<a class="add-icon glyphicon glyphicon-'+icon+'" href="#" data-show-modal="'+action+'"></a>');
                $(this).append(h);
                h.click(function(ev){
                    ev.preventDefault();
                    var id = $(this).attr('data-show-modal');
                    _fpa.show_modal($(id).html(), title);
                });                
            }else{
                var h = $('<a data-toggle="popover" data-content="'+title+'" class="add-icon glyphicon glyphicon-'+icon+'"></a>');
                $(this).append(h);
                h.popover({trigger: 'hover click', placement: 'bottom'});
            }
        }).addClass('attached-add-icon');
        
        
        // Sort dom elements within the block's parent,
        // based on the value of the data attribute specified by data-sort-desc in a child of the current block
        // For example:
        // data-sort-desc="data-item-rank" 
        // will sort all blocks in the parent of this block with the attribute data-sort-desc, using the
        // value from a child of each block with the data attribute data-item-rank, for example
        // data-item-rank="10"
        // The sort will automatically sort on numeric values only
        var s = block.attr('data-sort-desc');
        if(s){            
            var descp = block.parent();
            descp.find('[data-sort-desc]').sort(function(a,b){
                return $(b).find('['+s+']').attr(s) - $(a).find('['+s+']').attr(s);
            }).prependTo(descp);
        }
        
        block.updatePolyfill();
        
        block.find('input,select,checkbox,textarea').not('[type="submit"],.form-control').addClass('form-control input-sm');
        block.find('.typeahead').css({width: '100%'});        
        block.find('form').not('.form-formatted').addClass('form-inline');
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
        _fpa.form_utils.setup_extra_actions(block);
    }
};

