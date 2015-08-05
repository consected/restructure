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
            _fpa.postprocessors.tracker_item_link_hander(block);
        }
        
        $('a.master-expander').click(function(ev){
            ev.preventDefault();
            var id = $(this).attr('href');
            
            $(id).on('shown.bs.collapse', function(){
                _fpa.form_utils.format_block($(this));
                _fpa.postprocessors.tracker_notes_handler($(this));
                _fpa.postprocessors.tracker_item_link_hander($(this));
                $.scrollTo($(this), 200, {offset:-50} );

                $(this).off('shown.bs.collapse');
            });
            
            
        });
        
        var msid_list = $("#msid_list").html();
        var master_id_list = $("#master_id_list").html();
        
        if(msid_list && msid_list.replace(/ /g, '').length > 1){
            document.title = 'FHPS results';
            window.history.pushState({"html": "/masters/search?utf8=✓&nav_q="+msid_list, "pageTitle": document.title}, "", "/masters/search?utf8=✓&nav_q="+msid_list);
        }
        else if(master_id_list && master_id_list.replace(/ /g, '').length > 1){
            document.title = 'FHPS results';
            window.history.pushState({"html": "/masters/search?utf8=✓&nav_q_id="+master_id_list, "pageTitle": document.title}, "", "/masters/search?utf8=✓&nav_q_id="+master_id_list);
        }                
   
    },
    
    tracker_notes_handler: function(block){
        $('td.tracker-notes .cell-holder, td.tracker-history-notes .cell-holder').not('attached-expandable').each(function(){
            if($(this).height() > 40){
                $(this).click(function(){
                    _fpa.form_utils.toggle_expandable($(this));
                }).addClass('expandable').attr('title', 'click to expand / shrink');
            }else{
                $(this).addClass('not-expandable');
            };
        }).addClass('attached-expandable');
        
    },
    
    tracker_item_link_hander: function(block){
        block.find('a.tracker-link-to-item').not('.link-attached').click(function(){
            var href = $(this).attr('href');
            if(!href) return;
            $(href).addClass('item-highlight');
        }).addClass('link-attached');  
    },
    
    tracker_histories_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);
    },
    
    tracker_chron_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);
    },
    
    tracker_tree_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);
    },
    

    tracker_result_template: function(block, data){
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);
        if(data.tracker && data.tracker._created){
            var t = $('#tracker-count-'+data.tracker.master_id);
            var v = parseInt(t.html());
            if(v != null) v++;
            t.html(v);
        }
    },
    
    tracker_edit_form: function(block, data){
  
        // Handle auto date entry in the tracker edit form
        _fpa.form_utils.format_block(block);

        var update_date_fields = function(field, force){
            var el = block.find('#tracker_event_date');
            if(!_fpa.utils.is_blank(field.val())){
                el.parents('div').first().show();                
                var v = (new Date()).asYMD();
                if(force) {
                    el.val(v);
                    $('#tracker_notes').val('');
                }
            }else{
                el.parents('div').first().hide();
                el.val(null);
            }
        };

        block.find('#tracker_protocol_event_id').change(function(){
            update_date_fields($(this), true);
        }).each(function(){
            update_date_fields($(this));
        });
        
        block.find('#tracker_protocol_id').change(function(){
            block.find('#tracker_sub_process_id').focus().click();
        });
        block.find('#tracker_sub_process_id').change(function(){
            block.find('#tracker_protocol_event_id').focus().click();
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
        var d = data;
        if(data.player_info) d = data.player_info;
        _fpa.postprocessors.info_update_handler(block, d);
    },

    address_result_template: function(block, data){
        var d = data;
        if(data.address) d = data.address;
        _fpa.postprocessors.info_update_handler(block, d);
    }, 

    player_contact_result_template: function(block, data){
        var d = data;
        if(data.player_contact) d = data.player_contact;
        _fpa.postprocessors.info_update_handler(block, d);
    },
    address_edit_form: function(block, data){
        _fpa.form_utils.format_block(block);  
        
        var check_zip = function(){
         
            $('#address_zip').mask("00000-9999", {'translation': {0: {pattern: /\d/}, 0: {pattern: /\d/, optional: true}}});
        };
          
        check_zip();
        
        var handle_country = function(val){
         
            if(!val || val === 'US' || val === ''){
                block.find('.list-group-item.address-region').slideUp();
                block.find('.list-group-item.address-postal-code').slideUp();
                block.find('.list-group-item.address-zip').slideDown();
                block.find('.list-group-item.address-state').slideDown();
            }else{
                block.find('.list-group-item.address-region').slideDown();
                block.find('.list-group-item.address-postal-code').slideDown();
                block.find('.list-group-item.address-zip').slideUp();
                block.find('.list-group-item.address-state').slideUp();
            }
                
        };
        
        block.find('#address_country').change(function(){
            handle_country($(this).val());
        });
        
        handle_country($('#address_country').val());
    },
    
    player_contact_edit_form: function(block,data){
        _fpa.form_utils.format_block(block);  
        var check_phone = function(rec_type){
          if(rec_type.val()==='phone')
            $('#player_contact_data').mask("(000)000-0000 nn", {'translation': {0: {pattern: /\d/}, n: {pattern: /.*/, recursive: true, optional: true}}});
          else
            $('#player_contact_data').unmask();
        };

        var e = $('#player_contact_rec_type').change(function(){
          check_phone($(this));
        });

        check_phone(e);
    },
    
    admin_edit_form: function(block, data){
        $.scrollTo(block, 200, {offset:-50});
        _fpa.form_utils.format_block(block);
        block.find('#admin-edit-cancel').click(function(ev){
            ev.preventDefault();
            block.html('');
        });
    }

};
