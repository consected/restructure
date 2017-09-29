_fpa.postprocessors_trackers = {
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

    open_activity_log_player_contact_phone: function(link, block, href){
      var master_id = link.attr('data-master-id');
      _fpa.send_ajax_request('/masters/'+master_id+'/activity_log/player_contact_phones', {
          try_app_callback: function(){
            // handling the success of the ajax call, but since we are relying on a subscription to get fired that this has no control over,
            // just put in a delay to allow the templates time to render.
            // this will probably be sufficient in most cases.
            window.setTimeout(function(){_fpa.utils.jump_to_linked_item(href);}, 1000)
          }
      });

    },

    tracker_item_link_hander: function(block){

        $('.item-highlight').removeClass('item-highlight');

        block.find('a.tracker-link-to-item').not('.link-attached').click(function(ev){
          ev.preventDefault();
          var href = $(this).attr('href');
          var found = _fpa.utils.jump_to_linked_item(href);

          if(!found) {
            var call_if_needed = $(this).attr('data-call-if-needed');
            if(call_if_needed) {
                var cb = call_if_needed.split('.');
                if(cb[1])
                  _fpa[cb[0]][cb[1]]($(this), block, href);
                else
                  _fpa[cb[0]]($(this), block, href);
            }
          }


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
                var v = (new Date()).asLocale();

                if(force) {
                    el.val(v);
                    $('#tracker_notes').val('');
                }
                else{
                    _fpa.form_utils.setup_datepickers(block);
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

    }
}

$.extend(_fpa.postprocessors, _fpa.postprocessors_trackers);
