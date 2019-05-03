_fpa.form_utils = {
    // Although it would be appropriate to make a real object out of these functions,
    // convenience calling them individually on an ad-hoc basis around the code base does
    // not make this a good choice.

    set_field_errors: function(block, obj) {

      if(!obj) {
        // clear previous results
        $('.has-error').each(function() {
          $(this).find('.error-help').remove();
        }).removeClass('has-error');
        return;
      }

      var first_field;
      for(var p in obj) {
        if(obj.hasOwnProperty(p)) {
          var v = obj[p];
          var f = block.find("[data-attr-name='"+p.underscore()+"']").parent();

          // In certain cases there may be more than one matching item (such as for radio buttons)
          // If so, try to jump to the main .list-group-item container
          if(f.length > 1) {
            f = f.parents(".list-group-item").first();
          }
          if(f.length == 1) {
            if(!first_field) first_field = f;
            f.addClass('has-error');
            var fn = p.replace(/_/g, ' ');
            if(f.hasClass('showed-caption-before'))
            fn = 'Entry'

            v = fn + ' ' + v;
            var el = $('<p class="help-block error-help">'+v+'</p>');
            f.append(el);
            delete obj[p];
            obj.form = "has errors. Check the highlighted fields."

          }
        }
      }
      if(first_field)
        _fpa.utils.jump_to_linked_item(first_field, -300);
    },


    clear_content:function(block){
      block.removeClass('in');
      block.html('');

    },

    toggle_expandable: function(block){
        if(block.hasClass('expanded'))
            block.removeClass('expanded');
        else
            block.addClass('expanded');
    },

    highlight_tracker_history_item: function(block, data){
        data = _fpa.utils.get_data_attribs($(block));
        window.setTimeout(function(){
          $(data.tracker_history_item).addClass('item-highlight');
        }, 1000);
    },

    toggle_on_click_call: function(block, fn_name){
      if(!fn_name)
        fn_name = block.attr('data-on-click-call');

      var els = fn_name.split('.');

      var fn = _fpa[els[0]][els[1]];

      if(fn_name && fn){
        var attrs = _fpa.utils.get_data_attribs(block);

        fn(block, attrs);
      }
      else {
        console.log('no data-on-click-call value or function set');
      }

    },

    toggle_on_click_show: function(block){

      var strdata = block.attr('data-on-click-show');

      var items = strdata.split(',');

      var attrs = _fpa.utils.get_data_attribs(block);

      for(var item, i= 0; item = items[i]; i++){
        item = item.trim();
        var name_target = item.split('@');
        block = $(name_target[1]);

        if(block.length == 0)
          console.log("the target provided to toggle_on_click_show does not exist: " + name_target[1]);
        _fpa.view_template(block, name_target[0], attrs);
      }

    },

    on_open_click: function(block, timeout) {
      var res = block.find('.on-open-click a[data-remote="true"], .on-open-click a[data-target]').not('.auto-clicked').addClass('auto-clicked');
      res.each(function() {
        var item = $(this);

        var p = timeout;
        if(!p) {
          p = item.attr('data-open-priority');
          if(!p)
            p = 20;
          else
            p = parseInt(p);
        }

        window.setTimeout(function() {
          // console.log(item);
          item.click();
        }, p);
      });
    },

    unmask_inputs: function(block){

      var inputs = block.find("input[data-unmask='number'].is-masked");
      inputs.each(function(){
        var res = $(this).cleanVal();
        if(res){
          $(this).val(res);
        }
      }).removeClass('is-masked');
    },

    date_inputs_to_iso: function(block){

      var dates = block.find('input.date-is-local');
      if(dates.length > 0){

        dates.each(function(){
          var v = $(this).val();
          if(v || v != ''){
            var res = _fpa.utils.parseLocaleDate(v).asYMD();
            if(res){
              $(this).val(res);
            }

          }
        }).removeClass('date-is-local');
      }
    },

    data_from_form: function(block) {
      var form_els = block.find('[data-attr-name][data-object-name]');
      var form_data = {};
      var in_option = null;
      form_els.each(function() {
        var e = $(this);
        var obj_name = e.attr('data-object-name');
        var a_name = e.attr('data-attr-name');

        if(a_name == 'option_type') {
          in_option = e.val();
          if(in_option && in_option != '')
            var full_option_type = obj_name + '_' + in_option;
          else
            full_option_type = null;
        }

        if(!form_data[obj_name]) {
          form_data[obj_name] = { item_type: obj_name };
          form_data[obj_name].full_option_type = full_option_type;
        }
        if(e[0] && e[0].type == 'radio') {
          if (e.is(':checked'))
            form_data[obj_name][a_name] = e.val();
        }
        else if(e[0] && e[0].type == 'checkbox') {
          if (e.is(':checked'))
            form_data[obj_name][a_name] = true;
        }
        else {
          form_data[obj_name][a_name] = e.val();
        }
      });

      var obj_id = block.find('[data-item-id]').attr('data-item-id');
      for(var fo in form_data) {
        if(form_data.hasOwnProperty(fo))
          if(!form_data[fo].id)
            form_data[fo].id = obj_id;
      }

      return form_data;
    },

    get_general_selections: function(data) {

      if (!data) return;

      if(data.multiple_results) {
        _fpa.form_utils.get_general_selections(data[data.multiple_results]);
        return;
      }

      if(data.length) {
        for(var n = 0; n < data.length; n++) {
          _fpa.form_utils.get_general_selections(data[n]);
        }
        return;
      }

      if(!data.item_type) {

        var item_key;
        for (item_key in data) {
          if(data.hasOwnProperty(item_key) && item_key != '_control')
          break;
        }

        var di = data[item_key];
        if(!di) return;
        data = di;
      }

      if(data.embedded_item) {
        _fpa.form_utils.get_general_selections(data.embedded_item);
      }

      var post = (data.item_type ? '-item_type+' + data.item_type : '');
      post += (data.extra_log_type ? '-extra_log_type+' + data.extra_log_type : '');
      var cname = 'general_selections' + post;

      _fpa.set_definition(cname, function() {
        var pe = _fpa.cache(cname);
        data._general_selections = {};
        for(var k in data) {
          if(data.hasOwnProperty(k)) {

            if(data.model_data_type == 'activity_log') {
              var it = data.item_type + "_" + k;
            }
            else {
              var it = data.item_type + "s_" + k;
            }

            var ibh = _fpa.get_items_as_hash_by('item_type', pe, it, 'value');

            for(var ibhi in ibh) {
              break;
            }

            if(ibhi) {
              data._general_selections[k] = ibh;
            }
          }
        }
      });

    },



    // Setup the typeahead prediction for a specific text input element
    setup_typeahead: function(element, list, name, limit, options){

        if(typeof list === 'string')
          list = _fpa.cache(list);

        var items = new Bloodhound({
          datumTokenizer: Bloodhound.tokenizers.whitespace,
          queryTokenizer: Bloodhound.tokenizers.whitespace,
          local: list
        });

        var def = {
          hint: true,
          highlight: true,
          minLength: 1,
          autoselect: true
        };

        if(!options) options = {};

        for(var i in def) {
          if(def.hasOwnProperty(i)) {
            if(!(i in options)) {
              options[i] = def[i];
            }
          }
        }

        var dataset = {
          name: name,
          source: items
        };

        if(limit) {
          dataset.limit = limit;
        }



        $(element).typeahead(
          options,
          dataset
        ).on('keypress', function(ev){
            if(ev.keyCode != 13) return;
            var dnf = $(this).attr('data-next-field');
            if(dnf)
                $(dnf).focus();
            var v = $(this).val();
            if(v && v !='')$(this).addClass('has-value');
        });
    },

    // Make subtitutions in moustaches, when in view mode.
    // This function is called by a handlebars helper rather than in the postprocessor loop
    caption_before_substitutions: function(block, data) {

      block.find('.caption-before').not('.cb_subs_done').each (function () {
        var text = $(this).html();
        if(!text || text.length < 1) return;
        var res = text.match(/{{[0-9a-zA-z_\.]+}}/g);
        if(!res || res.length < 1) return;

        var new_data = {};
        if (data && data.master_id) {
          var master_id = data.master_id;
          new_data = Object.assign({}, data);
        }
        else {
          var master_id = block.parents('.master-panel').first().attr('data-master-id');
        }

        var master = _fpa.state.masters[master_id];
        if(master) {
          new_data = Object.assign(new_data, master);
        }

        res.forEach(function(el) {
          var elsplit = el.replace('{{','').replace('}}','').split('.');
          var got = null;
          if(elsplit[0])
            got = new_data[elsplit[0]];

          if(got && elsplit[1])
            got = got[elsplit[1]];

          if(got == null) got = '(?)';
          got = '<em class="all_caps">' + got + '</em>';
          text = text.replace(el, got);
        });

        $(this).html(text);

      }).addClass('cb_subs_done');
    },

    // Resize all labels in a block for nice formatting without tables or fixed widths
    resize_labels : function(block, data, force){
        if(!block) block = $(document);

        var block_list = block.find('.list-group:visible, .view-object[aria-expanded="true"]');
        if(!force) {
          block_list = block_list.not('.attached-resize-labels');
        }
        block_list.each(function(){
            // Cheap optimization to make the UI feel more responsive in large result sets
            var self = $(this);

            if(_fpa.processor_handlers && _fpa.processor_handlers.label_changes)
                _fpa.processor_handlers.label_changes(self);

            window.setTimeout(function(){
                var wmax = 0;
                // Get all the items that need resizing PLUS the caption-before each, allowing them to be excluded
                var list_items = self.find('.list-group-item.result-field-container, .list-group-item.result-notes-container, .list-group-item.edit-field-container, .list-group-item.caption-before').not('.all-fields-caption');

                var prev_caption_before = false;
                list_items.each(function() {
                  var this_caption_before = $(this).hasClass('caption-before') && !$(this).hasClass('caption-before-keep-label');
                  if(prev_caption_before && !this_caption_before) {
                    $(this).find('small, label').not('.radio-label').remove();
                  }
                  prev_caption_before = this_caption_before;
                });

                var lgi = self.find('.list-group-item.result-field-container, .list-group-item.edit-field-container').not('.is-heading, .is-sub-heading, .is-minor-heading, .is-full-width, .is-combo, .record-meta, .edit-form-header, .has-caption-before');


                var all = lgi.find('small, label').not('.radio-label');
                all.addClass('label-resizer').css({whiteSpace: 'nowrap', width: 'auto', minWidth: 'none', marginLeft: 'inherit'});

                var block_width = lgi.first().parent().width();

                all.each(function(){
                  if($(this).is(':visible')) {
                    var wnew = $(this).width();
                    if(wnew > wmax)
                      wmax = wnew;
                  }
                });

                if(wmax > block_width * 0.5)
                  wmax = block_width * 0.5;

                if(wmax>10){
                    if(lgi.parents('form').length === 0){
                        lgi.css({paddingLeft: wmax+30}).addClass('labels-resized');
                        all.css({minWidth: wmax, width: wmax, marginLeft: -wmax-14, whiteSpace: 'normal'}).addClass('list-small-label');
                    }else{
                        all.css({minWidth: wmax+6, width: wmax+6, whiteSpace: 'normal'}).addClass('list-small-label');
                    }
                }
                lgi.addClass('done-label-resize');
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

    organize_common_templates: function(block){
        block.find('.common-template-item').each(function(){
            var p = $(this).parents('.common-template-list').first();
            if(p.hasClass('row') && !$(this).hasClass('alt-width') ){
                $(this).addClass('col-md-8 col-lg-6');
            }
        });
    },

    // Provide a filtered set of options in a select field, based on the selection of
    // another field. Used exclusively for protocol / sub-process / protocol-event forms at the moment
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


    // Provide select filtering for select fields in user forms
    // Drive on optgroup, where the label is initially id/name and is split out
    // to just show the name and retain the id in an attribute
    // The select item that drives the change must have an attribute data-filters-select
    // with css selector pointing to the select element to be filtered on change
    setup_form_filtered_select: function(block) {
      block.find('select[data-filters-select]').not('.filters-select-attached').each(function() {
        var $el = $(this);
        var filter_sel = $el.attr('data-filters-select');
        $el.on('change', function () {
          var val = $el.val();
          $(filter_sel + ' optgroup[data-group-num]').hide();
          $(filter_sel + ' optgroup[data-group-num="'+val+'"]').show();
        });

        var val = $el.val();
        $(filter_sel + ' optgroup[label]').each (function () {
          if(!$(this).attr('data-group-num')) {
            var l = $(this).attr('label');
            var ls = l.split('/',2);
            var last = ls.length - 1;
            var first = 0;
            // console.log('got:'+ ls[last])
            $(this).attr('label', ls[last]);
            $(this).attr('data-group-num', ls[first]);
          }

        }).hide();
        $(filter_sel + ' optgroup[data-group-num="'+val+'"]').show();

      }).addClass('filters-select-attached');
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
                   if($(this).hasClass('no-sort')) {
                     $(this).attr('title', null);
                     $(this).attr('aria-label', null);
                     h[i] = {sorter: false};
                   }
                   i++;
               });

               //{0: {sorter: false}}
               ts.tablesorter( {dateFormat: 'yyyy-mm-dd', headers: h}).addClass('attached-tablesorter');
            });
        },100);
    },

    setup_bootstrap_items: function(block){
        if(!block) block = $(document);
        block.find('[data-toggle~="tooltip"]').not('.attached_bs').tooltip().addClass('attached_bs');
        block.find('[data-toggle~="popover"]').not('.attached_bs').popover().addClass('attached_bs');;
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
        block.find('[data-toggle~="clear"]').not('.attached-datatoggle-clear').on('click', function(){
            if($(this).attr('disabled')) return;
            var a = $(this).attr('data-target');
            var el = $(a).html('');
            if(el.hasClass('collapse'))
              el.removeClass('in');
            else
              el.addClass('hidden');
        }).addClass('attached-datatoggle-clear');

        block.find('[data-toggle~="unhide"]').not('.attached-datatoggle-uh').on('click', function(){
            if($(this).attr('disabled')) return;
            var a = $(this).attr('data-target');
            $(a).removeClass('hidden');
        }).addClass('attached-datatoggle-uh');

        block.find('[data-toggle~="uncollapse"]').not('.attached-datatoggle-uncoll').on('click', function(){
            if($(this).attr('disabled')) return;
            var a = $(this).attr('data-target');
            $(a).collapse('show');
        }).addClass('attached-datatoggle-uncoll');

        block.find('a.scroll-to-master').not('.attached-datatoggle-stm').on('click', function(){
            if($(this).attr('disabled')) return;
            var a;
            if(block.hasClass('panel-collapse'))
                a = block;
            else
                a = block.parents('.panel-collapse').first();

            _fpa.utils.scrollTo(a, 100, -60);


        }).addClass('attached-datatoggle-stm');


        block.find('[data-toggle~="scrollto-target"]').not('.attached-datatoggle-stt').on('click', function(){
          if($(this).attr('disabled')) return;
          var a = $(this).attr('data-target');
          _fpa.utils.jump_to_linked_item(a);
        }).addClass('attached-datatoggle-stt');


        block.find('[data-prevent-on-collapse="true"]').not('.attached-prevent-on-collapse').on('click', function(ev){
          if($(this).attr('disabled')) return;
          if(!$(this).hasClass('collapse')){
            ev.preventDefault();
          }

        }).addClass('attached-prevent-on-collapse');


        block.find('[data-toggle~="scrollto-result"], [data-toggle~="scrollto-target"], [data-toggle~="collapse"].scroll-to-expanded, [data-toggle~="uncollapse"].always-scroll-to-expanded ').not('.attached-datatoggle-str').on('click', function(){
            if($(this).attr('disabled')) return;
            if($(this).hasClass('scroll-to-expanded') && !$(this).hasClass('collapsed') || $(this).hasClass('no-scroll-on-collapse'))
              return;

            var a;
            var f = $(this).parents('[data-form-container]');
            if(f.length == 1) {
              a = f.attr('data-form-container');
            }
            else
              a = $(this).attr('data-target');

            if(!a || a==''){
                a = $(this).attr('data-result-target');
            }

            if(a){
                // Only jump to the target if the current top and bottom of the block are off screen. Usually we
                // attempt to do this so that users do not have to constantly scroll an edit block into view just to type
                // some data.
                // This is approximate, since forms typically make the block larger, but we are trying to avoid unnecessary
                // scrolling, to keep the page from jumping around for the user where possible.
                // Note that the timeout is set to ensure collapse sections have had time to grow to full height

                var attempt_count = 0;
                var doscroll = function(){
                  var rect = $(a).get(0);
                  if(!rect){
                    if(attempt_count > 10){
                      return;
                    }
                    attempt_count++;
                    window.setTimeout(function(){ doscroll() }, 250);
                    return;
                  }
                  rect = rect.getBoundingClientRect();

                  if(!rect.height) {
                    attempt_count++;
                    window.setTimeout(function(){ doscroll() }, 250);
                    return;
                  }

                  var not_visible = !(rect.top >= 0 && rect.bottom < $(window).height());
                  if(not_visible)
                    _fpa.utils.scrollTo(a, 200, -100);
                      // $(document).scrollTo(a, 100, {offset: -50});
                };

                window.setTimeout(function(){ doscroll() }, 250);
            }

        }).addClass('attached-datatoggle-str');

        block.find('[data-toggle~="expandable"]').not('.attached-datatoggle-exp').on('click', function(){
            if($(this).attr('disabled')) return;
            _fpa.form_utils.toggle_expandable($(this));
        }).addClass('attached-datatoggle-exp');

        // call a function on click - name the function 'something' or 'something.other' to call
        // _fpa.something(block, data) or _fpa.something.other(block, data)
        // data is produced by parsing the clicked element's data- attributes
        block.find('[data-on-click-call]').not('.attached-toggle_on_click_call').on('click', function(){
            if($(this).attr('disabled')) return;
            _fpa.form_utils.toggle_on_click_call($(this));
        }).addClass('attached-toggle_on_click_call');


        block.find('[data-result-callback]').not('.attached-toggle_on_result_callback').on('click', function(){
            if($(this).attr('disabled')) return;
            var cb = $(this).attr('data-result-callback');
            var cbc = cb.split('.');
            if(cbc[1]) {
              $(this)[0].app_callback = _fpa[cbc[0]][cbc[1]];
            }
            else {
              $(this)[0].app_callback = _fpa[cbc[0]];
            }
        }).addClass('attached-toggle_on_result_callback');


        // this will render a template or partial at some location in the dom
        // comma separate a list of template@domloc to show multiple items for a single click activity
        // data-on-click-show="phone_record-partial@#domid, another-partial@#activity-log2"
        block.find('[data-on-click-show]').not('.attached-toggle_on_click_show').on('click', function(){
            if($(this).attr('disabled')) return;
            _fpa.form_utils.toggle_on_click_show($(this));
        }).addClass('attached-toggle_on_click_show');

        block.find('[data-toggle~="clear-content"]').not('.attached-datatoggle-cc').on('click', function(){
            if($(this).attr('disabled')) return;
            var a = $(this).attr('data-target');
            _fpa.form_utils.clear_content($(a));
        }).addClass('attached-datatoggle-cc');

        block.find('[data-toggle-caret]').not('.attached-toggle_caret').on('click', function() {
          if($(this).hasClass('glyphicon-triangle-bottom')){
            var el = $(this);
            $(this).removeClass('glyphicon-triangle-bottom');
            $(this).addClass('glyphicon-triangle-top');
            var t = $(this).attr('data-target');
            var tel = t && $(t);
            window.setTimeout(function() {
              el.attr('disabled', true);
              if(tel && tel.find('.list-group-item').length) {
                _fpa.form_utils.format_block(tel.parent());
              }
            }, 10);
          }
          else {
            var el = $(this);
            $(this).addClass('glyphicon-triangle-bottom');
            $(this).removeClass('glyphicon-triangle-top');
            var t = $(this).attr('data-result-target');
            if(t) $(t).html('');
            window.setTimeout(function() {
              el.attr('disabled', false);

            }, 10);
          }
        }).addClass('attached-toggle_caret');
    },

    mask_inputs: function(block) {
      block.find('[pattern]').each(function(){
        var p = $(this).attr('pattern');
        if (!p || p == '') {
          $(this).removeAttr('pattern');
        }
      });

      block.find('[pattern]').not('.attached-datatoggle-pattern, [type="password"]').each(function(){
          var p = $(this).attr('pattern');
          var t = $(this).attr('type');
          var d = $(this).attr('data-mask');
          var m;
          if((!d || d === '') && (p && p !== '') ){
            if(t != 'text' && t != 'datepicker' && t != 'date') {
              $(this).attr('type', 'text');
              $(this).attr('data-unmask', t);
            }
            m = _fpa.masker.mask_from_pattern(p);

            $(this).attr('data-mask', m.mask);
            $(this).addClass('is-masking');
            $(this).mask(m.mask, {translation: m.translation, reverse: m.reverse});
            $(this).addClass('is-masked');
            $(this).removeClass('is-masking');
          }

      }).addClass('attached-datatoggle-pattern');


      block.find('[pattern].attached-datatoggle-pattern').not('.is-masked').each(function(){
        var el = $(this);
        var v = el.val();
        if(v && v !== '') {
          var res = el.masked(v);
          // console.log(res);
          el.val(res);
        }
      }).addClass('is-masked');


      block.find('input.time-entry').not('is-time-masked').each(function() {
        $(this).timepicker({
            timeFormat: 'h:mm p',
            interval: 15,
            minTime: '12:00am',
            maxTime: '11:59pm',
            startTime: '12:00am',
            dynamic: true,
            dropdown: true,
            scrollbar: true
        });
      });
    },

    setup_datepickers: function(block){

      // force date type fields to use the date picker by making them fall back to text
      block.find('input[type="date"]').each(function(){
        if($(this).prop('type') == 'date') {
          $(this).prop('type', 'datepicker');
          $(this).addClass('force-datepicker');
        }
        $(this).attr('type', 'datepicker');
      });

      // start by setting the date fields to show the date using the locale
      // only for the
      block.find('input[type="datepicker"]').not('.date-is-local').each(function(){
        var v = $(this).val();

        if(v && v != ''){
          var d = _fpa.utils.YMDtoLocale(v);
          $(this).val(d);
        }
        $(this).addClass('date-is-local');

      });

      // finally, set up datepickers on any fields that don't already have them
      block.find('input.force-datepicker, input[type="datepicker"]').not('.attached-datepicker').each(function(){

        $(this).datepicker({
          startView: 2,
          clearBtn: true,
          autoclose: true,
          todayHighlight: true,
          todayBtn: 'linked',
          format: _fpa.user_prefs.date_format
        });

        $(this).on('click', function(){
          $(this).datepicker('show');
        });

        $(this).on('keypress', function(){
          $(this).datepicker('hide');
        });

        $(this).mask('09\/09\/0000', {translation: _fpa.masker.translation, placeholder: "__/__/____"});
        $(this).addClass('attached-datepicker date-is-local');
      });

    },

    setup_extra_actions: function(block){

        block.find('.collapse').not('.attached-force-collapse').each(function(){
          var el = $(this);
          el.on('show.bs.collapse', function () {
            el.removeClass('hidden');
          });
          el.on('shown.bs.collapse', function () {
            el.removeClass('hidden');
            //el.css({display: 'block', height: 'auto', overflow: 'hidden'});
          });
          el.on('hide.bs.collapse', function () {

          });
        }).addClass('attached-force-collapse');


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
        // The sort will automatically sort on string, numeric or date/time values
        var sort_block = block;
        var s = sort_block.attr('data-sort-desc');
        if(!s) {
          sort_block = sort_block.children().first();
          if (sort_block.length)
            s = sort_block.attr('data-sort-desc');
        }
        if(!s) {
          sort_block = sort_block.find('[data-sub-list]');
          sort_block = sort_block.children().first();
          if (sort_block.length)
            s = sort_block.attr('data-sort-desc');
        }

        if(s){
            var descp = sort_block.parent();
            descp.find('[data-sort-desc]').sort(function(a,b){
              var bres = $(b).find('['+s+']').attr(s);
              var ares = $(a).find('['+s+']').attr(s);

              if(bres == null) bres = $(b).attr(s);
              if(ares == null) ares = $(a).attr(s);

              if(bres){
                var bboth = bres.split('--');
                if(bboth[1] == null) bboth[1] = "";
                bres = _fpa.utils.ISOdatetoTimestamp(bboth[0]) + bboth[1];
              }

              if(ares){
                var aboth = ares.split('--');
                if(aboth[1] == null) aboth[1] = "";
                ares = _fpa.utils.ISOdatetoTimestamp(aboth[0]) + aboth[1];
              }


              if(ares == null || ares == '') return -1;
              if(bres == null || bres == '') return 1;
              // Force to a number if it is equivalent to the original string
              var n = parseFloat(ares);
              if(ares == n)
                ares = n;
              n = parseFloat(bres);
              if(bres == n)
                  bres = n;

              if(bres > ares) {
                return 1;
              }
              if(bres < ares) {
                return -1;
              }
              return 0;

            }).prependTo(descp);
            // console.log('sorted!');
        }

        //block.updatePolyfill();

        block.find('input,select,checkbox,textarea').not('[type="submit"],.form-control,.ff').addClass('form-control input-sm ff');
        block.find('.typeahead').css({width: '100%'});
        block.find('form').not('.form-formatted').addClass('form-inline');


        block.find('textarea.auto-grow').not('.attached-auto-grow').each(function(){
           $(this).on('keypress, change',function(){
            $(this).get(0).style.height = "5px";
            $(this).get(0).style.height = ($(this).get(0).scrollHeight+5)+"px";
           });

        }).addClass('attached-auto-grow');

        block.find('input.college-input.typeahead').not('.attached-college_ta').each(function(){
          var el = $(this);
          _fpa.set_definition('colleges', function(){
              _fpa.form_utils.setup_typeahead(el, 'colleges', "colleges");
          });
        }).addClass('attached-college_ta');


        block.find('[data-format-date-local="true"]').not('.formatted-date-local').each(function(){
          var text = $(this).html();
          text = text.replace(' UTC', 'Z').replace(' ', 'T');
          var d = _fpa.utils.YMDtoLocale(text);
          $(this).html(d);
        }).addClass('formatted-date-local')
    },

    setup_contact_field_mask: function(block) {
      var check_rec = function(rec_type, input){

        if(typeof rec_type == 'string') {
          var val = rec_type;
          var no_rec_type = true;
        }
        else {
          var val = rec_type.val();
          input = block.find('input[data-attr-name="data"]');
        }

        if(val==='phone') {
          input.mask("(000)000-0000 nn", {'translation': {0: {pattern: /\d/}, n: {pattern: /.*/, recursive: true, optional: true}}}).attr('type', 'text');
        }
        else if(val==='email') {
          input.unmask().attr('type', 'email');
        }
        else
          input.unmask().attr('type', 'text');

        if(!no_rec_type) {
          var data_label = _fpa.utils.translate(val, 'field_labels');
          data_label = data_label ? _fpa.utils.capitalize(data_label) : 'Data'

          input.parent().find('label').not('.radio-label').html(data_label);
        }

      };

      var e = block.find('.rec_type_has_phone, .rec_type_has_email').change(function(){
        check_rec($(this));
      });

      check_rec(e);

      block.find('.is_phone').each(function(){
        check_rec('phone', $(this));
      });

      block.find('.is_email').each(function(){
        check_rec('email', $(this));
      });

    },

    setup_textarea_autogrow: function(block) {

      block.find('textarea').each(function(){
        var textarea = $(this)[0];
        var growingTextarea = new Autogrow(textarea);
        textarea.style.resize = 'none';
	      textarea.style.boxSizing = 'content-box';
        $(this).click(function() {
          if($(this).hasClass('done-auto-grow')) return;
          $(this).addClass('done-auto-grow');
          growingTextarea.autogrowFn();
        });
      });

      setTimeout(function(){
        var notes = block.find('.notes-block .list-group-item strong, .notes-block  .panel-body')
        _fpa.utils.make_readable_notes_expandable(notes, 100, _fpa.form_utils.resize_children);

      }, 10);

    },

    setup_filestore: function(block) {

      block.find('.browse-container').not('.nfs-store-setup').each(function() {

        var inblock = $(this);

        // Setup secure-view for the block
        var usv = $(this).attr('data-container-use-secure-view');
        if (!(usv == null || usv == '' || usv == 'false' || usv == 'download_files')) {
          var acts = {};
          var usvitems = usv.split(',');
          for (var k in usvitems) {
            acts[usvitems[k]] = true;
          }

          var spa = null;
          if (usvitems.indexOf('view_files_as_image') >= 0)
            spa = 'png';
          else if (usvitems.indexOf('view_files_as_html') >= 0)
            spa = 'html';

          var fn = $(this).html();

          _fpa.secure_view.setup_links($(this), 'a.browse-filename', {allow_actions: acts, set_preview_as: spa});
        }
        if (usv == null || usv == '' || usv == 'false') {
          $(this).find('a.browse-filename').on('click', function (ev) {
            ev.preventDefault();
          });
        }

        window.setTimeout(function() {
          inblock.find('.refresh-container-list').click();
          (inblock.nfs_store_uploader = _nfs_store.uploader)(inblock);
        },10);
      }).addClass('nfs-store-setup');
      // Initialize the nfs_store browser and uploader

    },

    setup_e_signature: function (block, force) {

      var els = block.find('.e-signature-container');
      if(!force) {
        els = els.not('.e-signature-setup');
      }

      els.each(function() {
        var _this = this;

        $(_this).find('.e-sign-print-frame').not('.click-ev-attached').on('click', function() {
          var i = $(_this).find('.e_signature_document_iframe')[0];
          i.contentWindow.print();
        }).addClass('click-ev-attached');

        window.setTimeout(function() {
          var c = $(_this).find('.e_signature_document');
          var html = c.val();

          var i = $(_this).find('.e_signature_document_iframe');
          i.attr('srcdoc', html);
          window.setTimeout(function () {
            var body = i[0].contentDocument.body;
            if(body)
              i.height(body.offsetHeight + 50);
            else
              i.height(500);

          }, 200);

        }, 10);
      }).addClass('e-signature-setup');
    },

    setup_error_clear: function (block) {
      block.on('change', '.has-error .form-control', function() {
        var p = $(this).parent();
        p.removeClass('has-error');
        p.find('.error-help').remove();
      });
    },

    resize_children: function(block, doNow){

      var doResize = function() {
        var curr_top = -1;
        var maxh = -1;

        var ob = block.parents('.resize-children').parent();
        if(ob.length > 0) {
          block = ob;
        }

        block.find('.resize-children').each(function(){
          $(this).find('ul.list-group').each(function(){
            if($(this).parents('ul.list-group').length == 0) {
              var cs = $(this).first();
              cs.parent().css({minHeight: '1px'});
            }
          });

          // Set the column width classes based on the content
          $(this).find('.common-template-item, .new-block').not('.resized-width, .model-reference-new-block').each(function() {
            var me = $(this);
            var dc = $(this).parents('.dynamic-container');
            if(dc.length > 0)
              me = dc;

            var has_dialog = (me.find('.in-form-dialog').length > 0);
            var has_e_sign = (me.find('#e_signature_document').length > 0);
            var cap_items = me.find('.list-group-item.caption-before, .list-group-item.dialog-before');
            if(!has_e_sign && cap_items.length == 0) return;
            var visible_cap = cap_items.filter(':visible');
            if(visible_cap && visible_cap.length > 0) {
              var cap_height = visible_cap.last().position().top + visible_cap.last().outerHeight() - visible_cap.first().position().top
            }
            else {
              cap_height = 0;
            }

            if(cap_height > 800 || has_dialog || has_e_sign) {
              var c = _fpa.layout.item_blocks.regular;
              var max_h = 0;
              cap_items.each(function() {
                var curr_h = $(this).height();
                if(curr_h > max_h) max_h = curr_h;
              });
              if(max_h > 60 || has_dialog || has_e_sign) {
                if(has_e_sign) {
                  c = _fpa.layout.item_blocks.e_signature;
                }
                else {
                  c = _fpa.layout.item_blocks.wide;
                }
                me.first().removeClass(_fpa.layout.item_blocks.regular);
                me.addClass(c).addClass('resized-width');
                _fpa.form_utils.resize_labels(me, null, true);
              }
              else {
                if(me.hasClass('new-block')) {
                  me.first().removeClass(_fpa.layout.item_blocks.wide);
                  me.first().removeClass(_fpa.layout.item_blocks.e_signature);
                  me.addClass(_fpa.layout.item_blocks.regular);
                }
              }
            }

          });

        });

        block.find('.resize-children').each(function(){

          // run through all the candidate items
          var cs = $(this).find('ul.list-group');
          cs.each(function(){
              if($(this).parents('ul.list-group').length > 0)
                return;
              var el = $(this).parent();

              // attempt to resize row by row if there is overflow
              // so, if the top of this item is lower, resize the height of
              // the recent items that are marked ready to resize,
              // then reset the maxh variable to start again.
              if(el.offset().top > curr_top){
                if(maxh>1)
                  var inc = 0;
                  // to resize the items go through each
                  // add a small increment to each item, to ensure that subpixel issues
                  // don't lead to errors
                  block.find('.ready-to-resize').each(function() {
                    $(this).removeClass('ready-to-resize').css({minHeight: maxh + inc});
                    inc++;
                  });
                maxh = 1;
                curr_top = el.offset().top;
              }

              // get the height of this item and see if it is larger
              // also set a class ready-to-resize that keeps this group of items
              // together when resizing just a row
              var h = el.addClass('ready-to-resize').height();
              if(h>maxh) maxh = h;
          });
          // finally, handle the remaining items
          if(maxh>1)
            block.find('.ready-to-resize').removeClass('ready-to-resize').css({minHeight: maxh});
        });
      };

      if(doNow) {
        doResize();
      }
      else {
        window.setTimeout(function(){
          doResize();
        }, 100);
      }
    },

    // Run through all the general formatters for a new block to show nicely
    format_block: function(block){

        if(!block){
          console.log('format_block was provided no block.');
          block = $(document);
        }

        // If the block has a class list-group we have gone one level too deep.
        // Go up to the parent to allow all the following formatters to work
        if(block.hasClass('list-group')) {
          block = block.parent();
        }

        // add an indicator (mostly for testing) that lengthy formatting is happening
        block.addClass('formatting-block');

        _fpa.form_utils.setup_chosen(block);
        _fpa.form_utils.setup_has_value_inputs(block);
        _fpa.form_utils.organize_common_templates(block);
        _fpa.form_utils.resize_labels(block);
        _fpa.form_utils.filtered_selector(block);
        _fpa.form_utils.setup_tablesorter(block);
        _fpa.form_utils.setup_bootstrap_items(block);
        _fpa.form_utils.setup_data_toggles(block);
        _fpa.form_utils.setup_extra_actions(block);
        _fpa.form_utils.setup_datepickers(block);
        _fpa.form_utils.mask_inputs(block);
        _fpa.form_utils.setup_textarea_autogrow(block);
        _fpa.form_utils.setup_contact_field_mask(block);
        _fpa.form_utils.setup_filestore(block);
        _fpa.form_utils.setup_e_signature(block);
        // Not currently used or tested.
        // _fpa.form_utils.setup_form_filtered_select(block);

        _fpa.form_utils.setup_error_clear(block);
        _fpa.form_utils.resize_children(block);
        block.removeClass('formatting-block');
    }
};
