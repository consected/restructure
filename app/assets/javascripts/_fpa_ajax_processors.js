/* Pre and Post processors for Ajax requests */
/* */
_fpa.preprocessors = {

    before_all: function(block){
                
        $('#master_results_block').removeClass('search-status-abort search-status-error search-status-done');
                
        
    },
    
    default: function(block, data, has_preprocessor){
            
    }
};

_fpa.postprocessors = {
    default: function(block, data, has_postprocessor){
           
           
        $('#master_results_block').addClass('search-status-done');  
        
        // Allow easy default processing where not already performed by the postprocessor
        if(!has_postprocessor){
            _fpa.form_utils.format_block(block);            
        }
        
        $('.format-block-on-expand').not('.attached-expander-format').on('shown.bs.collapse', function(){
                        
            _fpa.form_utils.format_block($(this));                
        }).addClass('attached-expander-format');
    
    },    
   
    
    search_results_template: function(block, data){
        // Ensure we format the viewed item on expanding it 

        if(data.masters && data.masters.length < 5){
            
            _fpa.form_utils.format_block(block);
            _fpa.postprocessors.show_external_links(block, data);
            _fpa.postprocessors.tracker_notes_handler(block);            
            _fpa.postprocessors.tracker_item_link_hander(block);                        
        }

        if(data.masters && data.masters.length === 1){                        
            _fpa.postprocessors.tracker_events_handler(block);   
            _fpa.postprocessors.extras_panel_handler(block);
        }

        
        $('a.master-expander').click(function(ev){
            ev.preventDefault();
            var id = $(this).attr('href');
            
            $(id).on('shown.bs.collapse', function(){
                
                _fpa.form_utils.format_block($(this));                
                
                _fpa.postprocessors.show_external_links($(this), data);
                
                _fpa.postprocessors.tracker_notes_handler($(this));
                _fpa.postprocessors.tracker_item_link_hander($(this));
                
                _fpa.postprocessors.tracker_events_handler($(this));                
                
                _fpa.postprocessors.extras_panel_handler($(this));
                
                $.scrollTo($(this), 200, {offset:-50} );                
                
                $(this).off('shown.bs.collapse');
            });
                        
        }).addClass('attached-me-click');
        
        var msid_list = $("#msid_list").html();
        var master_id_list = $("#master_id_list").html();
        
        if(msid_list && msid_list.replace(/ /g, '').length > 1){
            document.title = 'FPHS results';
            window.history.pushState({"html": "/masters/search?utf8=✓&nav_q="+msid_list, "pageTitle": document.title}, "", "/masters/search?utf8=✓&nav_q="+msid_list);
        }
        else if(master_id_list && master_id_list.replace(/ /g, '').length > 1){
            document.title = 'FPHS results';
            window.history.pushState({"html": "/masters/search?utf8=✓&nav_q_id="+master_id_list, "pageTitle": document.title}, "", "/masters/search?utf8=✓&nav_q_id="+master_id_list);
        }                
   
   
    },
    
    show_external_links: function(block, data){
        block.find('.external-links').each(function(){
            var id = $(this).attr('data-master-id');
            var master;
            if(data.player_info)
                master = {player_infos: [data.player_info]};
            else
                master = _fpa.get_item_by('id', data.masters, id);
            if(master){
                var pi = master.player_infos[0];
                var html = _fpa.templates['external-links-template'](pi);
                $(this).html(html);
            }
            
        });
        
    },
    
    extras_panel_handler: function(block){
        block.find('.on-open-click a[data-remote="true"]').not('.auto-clicked').click().addClass('auto-clicked');        
    },
    
    tracker_opener: function(block){
        var t = block.find('.open-tracker.collapsed');
        if(t.length === 1){
            if(t.find('.tracker-count').html() !== '0')
              t.trigger('click');
        }
    },
    tracker_events_handler: function(block){
        // Open the tracker if it is currently not open
        _fpa.postprocessors.tracker_opener(block);
        // Show modal dialogs under certain conditions
        window.setTimeout(function(){
            
            _fpa.set_definition('protocol_events', function(){                                                
                var pe = _fpa.cache('protocol_events');
                var always_notify = true;
                block.find('.tracker-event_name[data-event-id]').each(function(){
                    var e = $(this);
                    var evid = e.attr('data-event-id');

                    var p = _fpa.get_item_by('id', pe, evid);
                    if(always_notify && p && p.milestone){
                        if(p.milestone.indexOf('always-notify-user') >= 0){
                            _fpa.show_modal(p.description, p.name);
                            always_notify = false;
                        }

                    }
                });


                block.find('.latest-tracker-history').each(function(){            
                    var t = $(this);
                    var ml = t.attr('data-lth-event-milestone');
                    if(ml && ml.indexOf('notify-user')>=0){
                        var ev = t.attr('data-lth-event');
                        var evid = t.attr('data-lth-event-id');


                        var p = _fpa.get_item_by('id', pe, evid);

                        if(p && always_notify){
                            var prot = t.attr('data-lth-protocol');
                            var proc = t.attr('data-lth-process');
                            var title = prot + ' - ' + proc + ': ' + ev;
                            _fpa.show_modal(p.description, title);
                        }                
                    }
                });                                
            });
        }, 500);
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
        
        $('.item-highlight').removeClass('item-highlight');
        
        block.find('a.tracker-link-to-item').not('.link-attached').click(function(ev){
            ev.preventDefault();
            var href = $(this).attr('href');
            $('.item-highlight').removeClass('item-highlight');
            if(!href) return;                        
            var h = $(href).addClass('item-highlight');
            
            if(!h.is(':visible')){
                // Open up the block containing this item
                h.parents('.collapse').first().collapse('show');
                
            }
            
            // Scroll if necessary
            var rect = h.get(0).getBoundingClientRect(); 
            var not_visible = !(rect.top >= 0 && rect.top <= $(window).height()/2);
            if(not_visible)                    
                $.scrollTo(h, 200, {offset: -50});
            
        }).addClass('link-attached');  
        
        block.find('.tracker-event_name[data-event-id], .tracker-history-event_name[data-event-id]').not('.te-desc-attached').each(function(){
            _fpa.set_definition('protocol_events', function(){
                var e = $(this);
                var evid = e.attr('data-event-id');
                var pe = _fpa.cache('protocol_events');                
                var p = _fpa.get_item_by('id', pe, evid);
                if(p && p.description){
                    var title = p.name;
                    var h = '<span class="glyphicon glyphicon-info-sign tracker-event-description" data-toggle="popover" title="'+title+'" data-content="'+p.description+'"></span>';
                    var hj = $(h).appendTo(e.find('.cell-holder'));
                    hj.popover({trigger: 'click hover'});
                }
            });
        }).addClass('te-desc-attached');
        
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
        if(data.tracker && (data.tracker._created || data.tracker._updated)){
            _fpa.set_definition('protocol_events', function(){
                var evid = data.tracker.protocol_event_id;
                var pe = _fpa.cache('protocol_events');                
                var p = _fpa.get_item_by('id', pe, evid);

                // Quick fix - disable notifications if they are happening. Otherwise they will continue to fire until next refresh.
                $('#latest-tracker-history-'+data.tracker.master_id).attr('data-lth-event-milestone','');

                if(p){
                    var ml = p.milestone;
                    if(ml && ml.indexOf('notify-user')>=0){
                        var prot = data.tracker.protocol_name;
                        var proc = data.tracker.sub_process_name;
                        var ev = p.name;
                        var title = prot + ' - ' + proc + ': ' + ev;
                        _fpa.show_modal(p.description, title);
                    }
                }
            });
        }
        
    },
    
    tracker_edit_form: function(block, data){
  
        // Handle auto date entry in the tracker edit form
        _fpa.form_utils.format_block(block);

        var update_date_fields = function(field, force){
            var el = block.find('#tracker_event_date');
            //if(!_fpa.utils.is_blank(field.val())){
                el.parents('div').first().show();                
                var v = (new Date()).asYMD();
                if(force) {
                    el.val(v);
                    $('#tracker_notes').val('');
                }
        };

        block.find('#tracker_protocol_event_id, #tracker_sub_process_id').change(function(){
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
            
            $('#master-'+ master_id + '-player-infos').find('.on-open-click a[data-remote="true"]').click();
        }
    },

    player_info_result_template: function(block, data){
        var d = data;
        if(data.player_info) d = data.player_info;
        _fpa.postprocessors.info_update_handler(block, d);
        _fpa.postprocessors.show_external_links(block.parents('.panel').first(), data);
    },

    address_result_template: function(block, data){
        var d = data;
        if(data.address) d = data.address;
        _fpa.postprocessors.info_update_handler(block, d);
    }, 
    
    scantron_result_template: function(block, data){
        var d = data;
        if(data.scantron) d = data.scantron;
        _fpa.postprocessors.info_update_handler(block, d);
    },
    sage_assignment_result_template: function(block, data){
        var d = data;
        if(data.sage_assignment) d = data.sage_assignment;
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
                block.find('#address_region').val('');
                block.find('#address_postal_code').val('');
            }else{
                block.find('.list-group-item.address-region').slideDown();
                block.find('.list-group-item.address-postal-code').slideDown();
                block.find('.list-group-item.address-zip').slideUp();
                block.find('.list-group-item.address-state').slideUp();
                block.find('#address_zip').val('');
                block.find('#address_state').val('');
            }
                
        };
        
        block.find('#address_country').change(function(){
            handle_country($(this).val());
        });
        
        window.setTimeout(function(){
            handle_country($('#address_country').val());
        },10);
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
    
    reports_form: function(block, data){
        _fpa.form_utils.format_block(block);            
        $('#master_results_block').html('');
        

        _fpa.masters.handle_search_form(block.find('form'));
        
        
        block.find('a.btn[data-attribute]').click(function(ev){
          ev.preventDefault();
          var da = $(this).attr('data-attribute');
          
          var v = $('#search_attrs_'+da);
          var newval = v.val();
          if(newval.length > 0) newval += "\n";
          var from_f = $('#multiple_attrs_'+da);
          newval += from_f.val();
          v.val(newval);
          from_f.val('');
          v.change();
          from_f.change();
        });
        
    },
    
    reports_result: function(block, data){
        // Update the search form results count bar manually
        var c = $('.result-count').html();
        
        data.count = {count: c, show_count: c};
        var h = _fpa.templates['search-count-template'](data);
        $('.search_count_reports').html(h); 
    },

    
    flash_template: function(block, data){
         _fpa.timed_flash_fadeout();      
    },
    
    after_error: function(block, status, error){
        if(status=='abort'){
            $('#master_results_block').html('<h3  class="text-center"><span class="glyphicon glyphicon-pause search-canceled" data-toggle="popover" data-trigger="click hover" data-content="search paused while new entries are added"></span></h3>').addClass('search-status-abort');
            $('.search-canceled').popover();
        }else{
            var e = '';
            if(status) e = status;
            $('#master_results_block').addClass('search-status-error');
        }
    }
};

_fpa.processor_handlers = {
    label_changes: function(block){        
        
            block.find('.address-state_name small').each(function(){ $(this).html('state'); });
            block.find('.address-country_name small').each(function(){ $(this).html('country'); });
            block.find('.address-source_name small').each(function(){ $(this).html('source'); });
            block.find('.player-info-source_name small').each(function(){ $(this).html('source'); });
            
        
    }
};