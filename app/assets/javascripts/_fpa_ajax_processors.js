_fpa.preprocessors = {
    
    default: function(block, data, has_preprocessor){
            
    }
};

_fpa.postprocessors = {
    default: function(block, data, has_postprocessor){
    
        // Allow easy default processing where not already performed by the postprocessor
        if(!has_postprocessor){
            _fpa.form_utils.format_block(block);
        }
    
    },    
    
    search_results_template: function(block, data){
        // Ensure we format the viewed item on expanding it 

        

        if(data.masters && data.masters.length < 5){
            _fpa.form_utils.format_block(block);
            _fpa.postprocessors.tracker_notes_handler(block);            
        }

        $('a.master-expander').click(function(ev){
            ev.preventDefault();
            var id = $(this).attr('href');
            
            $(id).on('shown.bs.collapse', function(){
                _fpa.form_utils.format_block($(this));
                _fpa.postprocessors.tracker_notes_handler($(this));
                $.scrollTo($(this), 200, {offset:-50} );

                $(this).off('shown.bs.collapse');
            });
            
            
        });
   
    },
    
    tracker_notes_handler: function(block){
        $('td.tracker-notes .cell-holder, td.tracker-history-notes .cell-holder').not('attached-expandable').each(function(){
            if($(this).height() > 30){
                $(this).click(function(){
                    _fpa.form_utils.toggle_expandable($(this));
                }).addClass('expandable').attr('title', 'click to expand / shrink');
            }else{
                $(this).addClass('not-expandable');
            };
        }).addClass('attached-expandable');
        
    },
    
    tracker_histories_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
    },
    
    tracker_chron_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
    },
    
    tracker_tree_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
    },
    

    tracker_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
    },
    
    tracker_edit_form: function(block, data){
  
        // Handle auto date entry in the tracker edit form
        _fpa.form_utils.format_block(block);

        block.find('#tracker_outcome, #tracker_event').change(function(){
            var el = block.find('#'+$(this).prop('id')+'_date');
            if(!_fpa.utils.is_blank($(this).val())){

                var v = (new Date()).asYMD();
                el.val(v);
            }else{
                el.val(null);
            }

        });

    },
      

    item_flags_result_template: function(block, d) {
        _fpa.form_utils.format_block(block);
        if(d.item_flags.update_action){          
            var master_id = d.item_flags.master_id;
            var t = '#trackers-' + master_id;

            var a = $('a.open-tracker[data-target="' + t + '"]');
            a[0].app_callback = function(){
                $(t).collapse('show');
            };
            a.trigger('click.rails');        
        }
    },

    info_update_handler: function(block, d) {
        _fpa.form_utils.format_block(block);
        if(d.update_action){
            var master_id = d.master_id;
            $.scrollTo($('#master-'+ master_id), 250);

            var t = '#trackers-' + master_id;

            var a = $('a.open-tracker[data-target="' + t + '"]');
            a[0].app_callback = function(){
                $(t).collapse('show');
            };
            a.trigger('click.rails');        
        }
    },

    player_info_result_template: function(block, data){
        _fpa.postprocessors.info_update_handler(block, data.player_info);
    },

    address_result_template: function(block, data){
        _fpa.postprocessors.info_update_handler(block, data.address);
    }, 

    player_contact_result_template: function(block, data){
        _fpa.postprocessors.info_update_handler(block, data.player_contact);
    }
    
    

};
