/* Pre and Post processors for Ajax requests */
/* */
_fpa.preprocessors = {

    before_all: function(block){

        $('#master_results_block').removeClass('search-status-abort search-status-error search-status-done');

        _fpa.form_utils.date_inputs_to_iso(block);

        _fpa.form_utils.unmask_inputs(block);
    },

    default: function(block, data, has_preprocessor){

    }
};

_fpa.postprocessors = {
    default: function(block, data, has_postprocessor){

        _fpa.form_utils.setup_datepickers($('form'));
        _fpa.form_utils.mask_inputs($('form'));

        $('#master_results_block').addClass('search-status-done');

        // Allow easy default processing where not already performed by the postprocessor
        if(!has_postprocessor){
            _fpa.form_utils.format_block(block);
        }

        $('.format-block-on-expand').not('.attached-expander-format').on('shown.bs.collapse', function(){

            _fpa.form_utils.format_block($(this));
        }).addClass('attached-expander-format');

    },

    modal_pi_search_results_template: function(block, data){

        window.setTimeout(function(){
            _fpa.form_utils.format_block(block);

            _fpa.masters.switch_id_on_click(block);
        }, 30);

        $('a.modal-expander').click(function(ev){
            ev.preventDefault();
            var id = $(this).attr('href');

            $(id).on('shown.bs.collapse', function(){

                _fpa.form_utils.format_block($(this));

                $.scrollTo($(this), 200, {offset:-50} );

                $(this).off('shown.bs.collapse');
            });

        }).addClass('attached-me-click');
    },
    search_results_template: function(block, data){
        // Ensure we format the viewed item on expanding it
        _fpa.masters.switch_id_on_click(block);
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

                $('.selected-result').removeClass('selected-result');

                $('#'+$(this).attr('aria-labelledby')).addClass('selected-result');
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

    info_update_handler: function(block, d, no_scroll) {
        _fpa.form_utils.format_block(block);
        if(d.update_action){
            var master_id = d.master_id;

            // previously this was in here to handle scolling to updated data
            // this now has a strange effect given that there are a lot of other
            // panels showing in a master, before the player infos.
            // Don't force this scroll to the top anymore
            // if(!no_scroll)
            //   $.scrollTo($('#master-'+ master_id), 250);

            // automatically open the trackers planel
            var t = '#trackers-' + master_id;

            window.setTimeout(function(){
              var a = $('a.open-tracker[data-target="' + t + '"]');
              a[0].app_callback = function(){
                  $(t).collapse('show');
              };
              a.trigger('click.rails');
            }, 10);
            // After a short delay, trigger the background loading of items for this master
            window.setTimeout(function(){
              $('#master-'+ master_id + '-player-infos').find('.on-open-click a[data-remote="true"]').click();
            }, 500);
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
                block.find('.list-group-item.address-postal_code').slideUp();
                block.find('.list-group-item.address-zip').slideDown();
                block.find('.list-group-item.address-state').slideDown();
                block.find('#address_region').val('');
                block.find('#address_postal_code').val('');
            }else{
                block.find('.list-group-item.address-region').slideDown();
                block.find('.list-group-item.address-postal_code').slideDown();
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
            _fpa.form_utils.setup_datepickers(block);
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
