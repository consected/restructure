_fpa.postprocessors_trackers = {
    tracker_opener: function (block) {
        var t = block.find('.open-tracker.collapsed');
        if (t.length === 1) {
            if (t.find('.tracker-count').html() !== '0')
                t.trigger('click');
        }
    },
    // Show modal dialogs under certain conditions
    // If an event milestone contains 'always-notify-user'
    //   then when it appears in the
    tracker_events_handler: function (block, data) {
        window.setTimeout(function () {

            var always_notify = [];
            var done_sp = [];
            var desc = '';
            var title;
            var master = data.master;
            if (!master && data.masters.length === 1) master = data.masters[0];

            if (!master) return;

            var tns = master.tracker_notifications;
            for (var k in tns) {
                if (!tns.hasOwnProperty(k)) continue;

                var p = tns[k];
                if (!p || !p.event_milestone) continue;
                if (done_sp.indexOf(p.sub_process_id) >= 0) continue;

                if (p.event_milestone.indexOf('override-alert') >= 0) {
                    done_sp.push(p.sub_process_id);
                }
                else if (p.event_milestone.indexOf('always-notify-user') >= 0) {
                    if (desc) desc = desc + '<hr/>';
                    desc = desc + `<h5>${p.event_name}</h5><p>${p.event_description}</p>`
                    always_notify.push(p.id);
                    done_sp.push(p.sub_process_id);
                }
            }

            var lth = master.latest_tracker_history;
            for (var k in lth) {
                if (!lth.hasOwnProperty(k)) continue;

                var p = lth[k];
                // Only show tracker events once
                if (!p || !p.event_milestone) continue;
                if (always_notify.indexOf(p.id) >= 0) continue;
                if (done_sp.indexOf(p.sub_process_id) >= 0) continue;

                if (p.event_milestone.indexOf('override-alert') >= 0) {
                    done_sp.push(p.sub_process_id);
                }
                else if (p.event_milestone.indexOf('notify-user') >= 0) {
                    var title = `${p.protocol_name} - ${p.sub_process_name}: ${p.event_name}`;
                    desc = desc + `<h5>${title}</h5><p>${p.event_description}</p>`
                    always_notify.push(p.id);
                    done_sp.push(p.sub_process_id);
                }
            }
            if (always_notify.length > 0) {
                title = 'Tracker Event Notification'
                _fpa.show_modal(desc, title);
                return;
            }

        }, 500);
    },

    tracker_notes_handler: function (block) {
        var b = $('td.tracker-notes .cell-holder, td.tracker-history-notes .cell-holder');
        _fpa.utils.make_readable_notes_expandable(b);
    },



    tracker_item_link_hander: function (block) {

        $('.item-highlight').removeClass('item-highlight');

        block.find('a.tracker-link-to-item').not('.link-attached').click(function (ev) {
            ev.preventDefault();
            var href = $(this).attr('href');
            var found = _fpa.utils.jump_to_linked_item(href);

            if (!found) {
                var call_if_needed = $(this).attr('data-call-if-needed');
                if (call_if_needed) {
                    var cb = call_if_needed.split('.');
                    if (cb[1]) {
                        if (_fpa[cb[0]] && _fpa[cb[0]][cb[1]])
                            _fpa[cb[0]][cb[1]]($(this), block, href);
                        else
                            console.log("call_if_needed not found: " + cb);
                    }
                    else if (_fpa[cb[0]])
                        _fpa[cb[0]]($(this), block, href);
                    else
                        console.log("call_if_needed not found: " + cb);
                }
            }


        }).addClass('link-attached');

        block.find('.tracker-event_name[data-event-id], .tracker-history-event_name[data-event-id]').not('.te-desc-attached').each(function () {
            _fpa.cache.get_definition('protocol_events', function () {
                var e = $(this);
                var evid = e.attr('data-event-id');
                var pe = _fpa.cache.fetch('protocol_events');
                var p = _fpa.get_item_by('id', pe, evid);
                if (p && p.description) {
                    var title = p.name;
                    var h = '<span class="glyphicon glyphicon-info-sign tracker-event-description" data-toggle="popover" title="' + title + '" data-content="' + p.description + '"></span>';
                    var hj = $(h).appendTo(e.find('.cell-holder'));
                    hj.popover({ trigger: 'click hover' });
                }
            });
        }).addClass('te-desc-attached');

    },

    tracker_histories_result_template: function (block, data) {
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);
    },

    tracker_chron_result_template: function (block, data) {
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);

    },

    tracker_tree_result_template: function (block, data) {
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);
    },


    tracker_result_template: function (block, data) {
        _fpa.form_utils.format_block(block);
        _fpa.postprocessors.tracker_notes_handler(block);
        _fpa.postprocessors.tracker_item_link_hander(block);
        if (data.tracker && data.tracker._created) {
            var t = $('#tracker-count-' + data.tracker.master_id);
            var v = parseInt(t.html());
            if (v != null) v++;
            t.html(v);
        }

        // Refresh the completions list
        if (data.tracker) {
            var $completions = $('#trackers-' + data.tracker.master_id + '-completions');
            _fpa.view_template($completions, 'tracker_completions', data);
        }

        // if we are viewing in chronological mode when an item is added,
        //force a refresh of the list
        var chronres = $('table.tracker-chron-results');
        if (chronres.length === 1) {
            chronres.find('a[data-template="tracker-tree-result-template"]').click();
            return;
        }

        // If the new tracker item is linked to an activity log item
        // trigger a click on the link icon to refresh the activity log item and
        // scroll back to it
        if (data.tracker && (data.tracker._created || data.tracker._merged) && data.tracker.record_type && data.tracker.record_type.indexOf('ActivityLog::') == 0) {
            var newlink = $('#tracker-' + data.tracker.master_id + '-' + data.tracker.id + ' a[data-master-id="' + data.tracker.master_id + '"][data-record-id="' + data.tracker.record_id + '"]');
            newlink.click();
        }

        if (data.tracker && (data.tracker._created || data.tracker._updated)) {
            _fpa.cache.get_definition('protocol_events', function () {
                var evid = data.tracker.protocol_event_id;
                var pe = _fpa.cache.fetch('protocol_events');
                var p = _fpa.get_item_by('id', pe, evid);

                // Quick fix - disable notifications if they are happening. Otherwise they will continue to fire until next refresh.
                $('#latest-tracker-history-' + data.tracker.master_id).attr('data-lth-event-milestone', '');

                if (p) {
                    var ml = p.milestone;
                    if (ml && ml.indexOf('notify-user') >= 0) {
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

    tracker_edit_form: function (block, data) {

        // Handle auto date entry in the tracker edit form
        _fpa.form_utils.format_block(block);

        var update_date_fields = function (field, force) {
            var el = block.find('#tracker_event_date');
            //if(!_fpa.utils.is_blank(field.val())){
            el.parents('div').first().show();
            if (el.hasClass('attached-datepicker')) {
                var v = (new Date()).asLocale();
            } else {
                var v = (new Date()).asYMD();
            }
            if (force) {
                el.val(v);
                $('#tracker_notes').val('');
            }
            else {
                _fpa.form_utils.setup_datepickers(block);
            }

        };

        block.find('#tracker_protocol_event_id, #tracker_sub_process_id').change(function () {
            update_date_fields($(this), true);
        }).each(function () {
            update_date_fields($(this));
        });

        block.find('#tracker_protocol_id').change(function () {
            block.find('#tracker_sub_process_id').focus().click();
        });
        block.find('#tracker_sub_process_id').change(function () {
            block.find('#tracker_protocol_event_id').focus().click();
        });

    }
}

$.extend(_fpa.postprocessors, _fpa.postprocessors_trackers);
