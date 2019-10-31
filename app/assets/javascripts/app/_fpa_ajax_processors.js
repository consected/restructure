/* Pre and Post processors for Ajax requests */
/* */
_fpa.preprocessors = {

    before_all: function(block){

        _fpa.masters.get_results_block().removeClass('search-status-abort search-status-error search-status-done');

        _fpa.form_utils.on_form_submit(block);

        // Mark the block a form was within, to make scrolling more reliable
        if(block.is('form')) {
          var b = block.parents('.common-template-item, .new-block').not('.no-processed-scroll');
          if(b.hasClass('new-block'))
            b = b.parent();
          $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here');
          b.addClass('postprocessed-scroll-here');
        }

        block.parent().find('[data-preprocessor="embedded_report"]').not('er-attached').on('ajax:success', function() {
          $(this).addClass('refresh-item-on-modal-close');
        }).addClass('er-attached');
    },

    default: function(block, data, has_preprocessor){

    }
};

_fpa.postprocessors = {
    default: function(block, data, has_postprocessor){
        _fpa.processor_handlers.form_setup($('form'));

        _fpa.masters.get_results_block().addClass('search-status-done');

        if (!$('body').hasClass('fixed-overlay')) {

          if($('body').hasClass('user_page') && $('body').hasClass('show') && $('#master_results_block #results-accordion, .no-table-results').length == 0) {
            $('body').addClass('table-results');
            $('html').css({overflow: 'hidden'});
            _fpa.reports.window_scrolling();
          }
          else {
            $('body').removeClass('table-results');
            $('html').css({overflow: 'auto'});
            _fpa.reports.reset_window_scrolling();

          }
        }


        // Allow easy default processing where not already performed by the postprocessor
        if(!has_postprocessor){
            _fpa.form_utils.format_block(block);
        }

        $('.format-block-on-expand').not('.attached-expander-format').on('shown.bs.collapse', function(){

            _fpa.form_utils.format_block($(this));
        }).addClass('attached-expander-format');

        if(block.hasClass('new-block') && !block.is(':visible')) {
          block.show();
          window.setTimeout(function() {
            _fpa.form_utils.format_block(block);
          }, 200);
        }

        // Add handler for "select or add" model reference field
        block.find('.select-ref-to-record').not('.attached-handler').change(function () {
          var val = $(this).val();
          var selform = $(this).parents('form').first();
          var lg = selform.siblings().not('.new_select_reference').first();
          if (!val || val == '') {
            selform.find('.submit-action-container').addClass('hidden');
            lg.slideDown('fast');
          }
          else {
            selform.find('.submit-action-container').removeClass('hidden');
            lg.slideUp('fast');
          }
        }).addClass('attached-handler');


        var item_key;
        for (item_key in data) {
          if(data.hasOwnProperty(item_key) && item_key != '_control')
            break;
        }

        var di = data[item_key];
        if(di && (di._created || di._updated)) {
          var drf = di.referenced_from;
          if(drf && drf.length > 0) {
            for(var i in drf){
              if(drf.hasOwnProperty(i) && drf[i].from_record_type_us)
                _fpa.send_ajax_request("/masters/" + drf[i].from_record_master_id + "/" + drf[i].from_record_type_us.replace('__','/') + "s/" + drf[i].from_record_id);
            }
          }
        }

        // Handle conditional form fields
        if(data.form_data) {
          var form_data = data.form_data;
          var form_els = block.find('[data-attr-name][data-object-name]');
          form_els.on('change click keyup', function() {
            var e = $(this);
            var obj_name = e.attr('data-object-name');
            var a_name = e.attr('data-attr-name');

            if (e.attr('type') == 'checkbox') {
              form_data[obj_name][a_name] = e.is(':checked');
            }
            else {
              form_data[obj_name][a_name] = e.val();
            }

            _fpa.show_if.methods.show_items(block, form_data[obj_name]);
          });
          for(var fe in form_data) {
            if(form_data.hasOwnProperty(fe)) {
              _fpa.show_if.methods.show_items(block, form_data[fe]);
            }
          }
        }
        else if(di) {
          if(di.length) {
            for(var i = 0; i < di.length; i++) {
              if(di[i] && di[i].item_type) {
                var dii = di[i];
                var fit = dii.item_type;
                if(dii.option_type && dii.option_type != 'default') fit += '_' + dii.option_type;
                var sub_block = block.find('.common-template-item[data-sub-item="'+fit+'"][data-sub-id="'+dii.id+'"]')
                _fpa.show_if.methods.show_items(sub_block, dii);
              }
            }
          }
          else {
            _fpa.show_if.methods.show_items(block, di);
          }
        }

        // Scroll to block a form was within, rather than some random location that may have been triggered by another ajax event
        var h = $('.postprocessed-scroll-here');
        if(h.length > 0) {
          // Scroll if necessary
          h.removeClass('postprocessed-scroll-here');

          var rect = h.get(0).getBoundingClientRect();
          var not_visible = !(rect.top >= 0 && rect.top <= $(window).height()/2);
          if(not_visible) {
            window.setTimeout(function() {
              if(!h.hasClass('prevent-scroll'))
                _fpa.utils.scrollTo(h, 200, -50);
            }, 300);
          }

        }

        // Allow an auto click to be made on elements in the newly loaded block
        block.find('.on-postprocess-click').not('.auto-clicked, .ajax-running').addClass('auto-clicked').each(function(){
          var el = $(this);
          window.setTimeout(function(){
            el.click();
          });
        });

    },

    modal_pi_search_results_template: function(block, data){

        window.setTimeout(function(){
            _fpa.form_utils.format_block(block);

            _fpa.masters.switch_id_on_click(block);

            _fpa.form_utils.on_open_click(block);

        }, 30);

        $('a.modal-expander').click(function(ev){
            ev.preventDefault();
            var id = $(this).attr('href');


            $(id).on('shown.bs.collapse', function(){

                _fpa.form_utils.format_block($(this));

                _fpa.utils.scrollTo($(this), 200, -50);

                $(this).off('shown.bs.collapse');
            });

        }).addClass('attached-me-click');
    },
    search_action_template: function(block, data){

      // If we show a list of IDs rather than actual search results then collapse the forms to avoid confusion.
      // We don't just click though, since that hides flash messages too fast
      if(data.search_action == 'MSID') {
        var dtte = $('.advanced-form-selections [data-toggle="collapse"]').not('.collapsed, .prevent-list-collapse');

        var dtt = dtte.attr('data-target');
        if(dtt && dtt != '') {
            var dt = $(dtt);
            dt.collapse();
        }
      }
    },

    // On load of a specific master record when a list item is expanded
    master_main_template: function(block, data) {
      _fpa.form_utils.format_block(block);

      _fpa.postprocessors.show_external_links(block, data);

      _fpa.postprocessors.tracker_notes_handler(block);
      _fpa.postprocessors.tracker_item_link_hander(block);

      // _fpa.postprocessors.tracker_events_handler(block);

      _fpa.postprocessors.extras_panel_handler(block);
      block.addClass('loaded-master-main');

    },

    // On load of the full list of master records
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
            // _fpa.postprocessors.tracker_events_handler(block);
            _fpa.postprocessors.extras_panel_handler(block);
        }

        // Capture the master data into state for later use around the application
        // The layout of data is modelled partially on that provided by MessageTemplate.setup_data
        // allowing caption-before to function in 'show' mode
        if(data.masters && data.masters.length > 0) {
          _fpa.state.masters = _fpa.state.masters || {}
          data.masters.forEach(function(master) {
            if(master && master.id) {
              _fpa.state.masters[master.id] = Object.assign({}, master);
              if (_fpa.state.masters[master.id].player_infos) {
                _fpa.state.masters[master.id].player_info = _fpa.state.masters[master.id].player_infos[0];
                _fpa.state.masters[master.id].item = _fpa.state.masters[master.id].embedded_item;
              }
            }
          });

        }

        $('a.master-expander').click(function(ev){
            ev.preventDefault();
            var id = $(this).attr('data-target');
            $(id).on('shown.bs.collapse', function(){

                $('.selected-result').removeClass('selected-result');

                $('#'+$(this).attr('aria-labelledby')).addClass('selected-result');
                _fpa.form_utils.format_block($(this));

                _fpa.postprocessors.show_external_links($(this), data);

                _fpa.postprocessors.tracker_notes_handler($(this));
                _fpa.postprocessors.tracker_item_link_hander($(this));

                // _fpa.postprocessors.tracker_events_handler($(this));

                _fpa.postprocessors.extras_panel_handler($(this));

                _fpa.utils.scrollTo($(this), 200, -50);

                $(this).off('shown.bs.collapse');
            });

        }).addClass('attached-me-click');

        var msid_list = $("#msid_list").html();
        var master_id_list = $("#master_id_list").html();

        if(master_id_list && master_id_list.replace(/ /g, '').length > 1){
            document.title = 'FPHS results';
            window.history.pushState({"html": "/masters/search?utf8=✓&nav_q_id="+master_id_list, "pageTitle": document.title}, "", "/masters/search?utf8=✓&nav_q_id="+master_id_list);
        }
        else if(msid_list && msid_list.replace(/ /g, '').length > 1){
            document.title = 'FPHS results';
            window.history.pushState({"html": "/masters/search?utf8=✓&nav_q="+msid_list, "pageTitle": document.title}, "", "/masters/search?utf8=✓&nav_q="+msid_list);
        }
        else {
          document.title = 'FPHS results';
          window.history.pushState({"html": "/masters/search", "pageTitle": document.title}, "", "/masters/search");
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
      _fpa.form_utils.on_open_click(block);
    },




    item_flags_result_template: function(block, d) {
        _fpa.form_utils.format_block(block);
        if(d.item_flags.update_action){
            var master_id = d.item_flags.master_id;
            var t = '#trackers-' + master_id;

            var a = $('a.open-tracker[data-target="' + t + '"]');
            if(a && a[0]) {
              a[0].app_callback = function(){
                $(t).collapse('show');
              };
            }
            a.trigger('click.rails');
        }
    },

    info_update_handler: function(block, d, no_scroll) {
        _fpa.form_utils.format_block(block);
        if(d.update_action){
            var master_id = d.master_id;

            // automatically open the trackers planel
            var t = '#trackers-' + master_id;

            window.setTimeout(function(){
              var a = $('a.open-tracker[data-target="' + t + '"]');
              if(a && a[0]) {
                a[0].app_callback = function(){
                  $(t).collapse('show');
                };
                a.trigger('click.rails');
              }
            }, 10);

            _fpa.form_utils.on_open_click($('#master-'+ master_id + '-main-container'), 500);
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

    },



    flash_template: function(block, data){
         _fpa.timed_flash_fadeout();
    },

    after_error: function(block, status, error){
        if(status=='abort'){
            _fpa.masters.get_results_block().html('<h3  class="text-center"><span class="glyphicon glyphicon-pause search-canceled" data-toggle="popover" data-trigger="click hover" data-content="search paused while new entries are added"></span></h3>').addClass('search-status-abort');
            $('.search-canceled').popover();
        }else{
            var e = '';
            if(status) e = status;
            _fpa.masters.get_results_block().addClass('search-status-error');
            _fpa.processor_handlers.form_setup(block);

        }
    }
};

_fpa.processor_handlers = {
    form_setup: function(block) {
      _fpa.form_utils.setup_datepickers(block);
      _fpa.form_utils.mask_inputs(block);
    },

    label_changes: function(block){

      block.find('.address-state_name small').each(function(){ $(this).html('state'); });
      block.find('.address-country_name small').each(function(){ $(this).html('country'); });
      block.find('.address-source_name small').each(function(){ $(this).html('source'); });
      block.find('.player-info-source_name small').each(function(){ $(this).html('source'); });


    }
};
