_fpa.form_utils = {
    // Although it would be appropriate to make a real object out of these functions,
    // convenience calling them individually on an ad-hoc basis around the code base does
    // not make this a good choice.

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
            var res = (new Date(v)).asYMD();
            if(res){
              $(this).val(res);
            }

          }
        }).removeClass('date-is-local');
      }
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
                var lgi = self.find('.list-group-item').not('.is-heading, .is-sub-heading, .is-minor-heading, .is-full-width, .is-combo, .record-meta');
                var all = lgi.find('small, label');
                all.css({display: 'inline-block', whiteSpace: 'nowrap'});

                var block_width = lgi.first().width();

                all.each(function(){
                    var wnew = $(this).width();
                    if(wnew > wmax)
                        wmax = wnew;
                });

                if(wmax > block_width * 0.5)
                  wmax = block_width * 0.5;

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

    organize_common_templates: function(block){
        $('.common-template-item').each(function(){
            var p = $(this).parents('.common-template-list');
            if(p.hasClass('row') && !$(this).hasClass('alt-width') ){
                $(this).addClass('col-md-6');
            }
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
            var a = $(this).attr('data-target');
            var el = $(a).html('');
            if(el.hasClass('collapse'))
              el.removeClass('in');
            else
              el.addClass('hidden');
        }).addClass('attached-datatoggle-clear');

        block.find('[data-toggle~="unhide"]').not('.attached-datatoggle-uh').on('click', function(){
            var a = $(this).attr('data-target');
            $(a).removeClass('hidden');
        }).addClass('attached-datatoggle-uh');

        block.find('[data-toggle~="uncollapse"]').not('.attached-datatoggle-uncoll').on('click', function(){
            var a = $(this).attr('data-target');
            $(a).collapse('show');
        }).addClass('attached-datatoggle-uncoll');

        block.find('a.scroll-to-master').not('.attached-datatoggle-stm').on('click', function(){
            var a;
            if(block.hasClass('panel-collapse'))
                a = block;
            else
                a = block.parents('.panel-collapse').first();

            $(document).scrollTo(a, 100, {offset: -60});


        }).addClass('attached-datatoggle-stm');


        block.find('[data-toggle~="scrollto-target"]').not('.attached-datatoggle-stt').on('click', function(){
          var a = $(this).attr('data-target');
          _fpa.utils.jump_to_linked_item(a);
        }).addClass('attached-datatoggle-stt');


        block.find('[data-prevent-on-collapse="true"]').not('.attached-prevent-on-collapse').on('click', function(ev){
          if(!$(this).hasClass('collapse')){
            ev.preventDefault();
          }

        }).addClass('attached-prevent-on-collapse');


        block.find('[data-toggle~="scrollto-result"], [data-toggle~="scrollto-target"], [data-toggle~="collapse"].scroll-to-expanded, [data-toggle~="uncollapse"].always-scroll-to-expanded ').not('.attached-datatoggle-str').on('click', function(){
            if($(this).hasClass('scroll-to-expanded') && !$(this).hasClass('collapsed') || $(this).hasClass('no-scroll-on-collapse'))
              return;

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
                // Note that the timeout is set to ensure collapse sections have had time to grow to full height
                window.setTimeout(function(){
                    var rect = $(a).get(0).getBoundingClientRect();
                    var not_visible = !(rect.top >= 0 && rect.bottom < $(window).height());
                    if(not_visible)
                        $(document).scrollTo(a, 100, {offset: -50});
                }, 250);
            }

        }).addClass('attached-datatoggle-str');

        block.find('[data-toggle~="expandable"]').not('.attached-datatoggle-exp').on('click', function(){
            _fpa.form_utils.toggle_expandable($(this));
        }).addClass('attached-datatoggle-exp');

        // call a function on click - name the function 'something' or 'something.other' to call
        // _fpa.something(block, data) or _fpa.something.other(block, data)
        // data is produced by parsing the clicked element's data- attributes
        block.find('[data-on-click-call]').not('.attached-toggle_on_click_call').on('click', function(){
            _fpa.form_utils.toggle_on_click_call($(this));
        }).addClass('attached-toggle_on_click_call');


        block.find('[data-result-callback]').not('.attached-toggle_on_result_callback').on('click', function(){
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
            _fpa.form_utils.toggle_on_click_show($(this));
        }).addClass('attached-toggle_on_click_show');

        block.find('[data-toggle~="clear-content"]').not('.attached-datatoggle-cc').on('click', function(){
            var a = $(this).attr('data-target');
            _fpa.form_utils.clear_content($(a));
        }).addClass('attached-datatoggle-cc');

    },

    mask_inputs: function(block) {
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
          console.log(res);
          el.val(res);
        }
      }).addClass('is-masked');
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
          $(this).addClass('date-is-local');
        }

      });

      // finally, set up datepickers on any fields that don't already have them
      block.find('input.force-datepicker, input[type="datepicker"]').not('.attached-datepicker').each(function(){

        $(this).datepicker({
          startView: 2,
          clearBtn: true,
          autoclose: true,
          todayHighlight: true,
          format: 'm/d/yyyy'
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
        // The sort will automatically sort on numeric values only
        var s = block.attr('data-sort-desc');
        if(s){
            var descp = block.parent();
            descp.find('[data-sort-desc]').sort(function(a,b){
                return $(b).find('['+s+']').attr(s) - $(a).find('['+s+']').attr(s);
            }).prependTo(descp);
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
            _fpa.set_definition('colleges', function(){
                _fpa.form_utils.setup_typeahead('input.college-input.typeahead', 'colleges', "colleges");
            });
        }).addClass('attached-college_ta');


        block.find('[data-format-date-local="true"]').not('.formatted-date-local').each(function(){
          var text = $(this).html();
          text = text.replace(' UTC', 'Z').replace(' ', 'T');
          var ds = new Date(Date.parse(text));
          var d = ds.toLocaleString();
          $(this).html(d);
        }).addClass('formatted-date-local')
    },

    resize_children: function(block){

      window.setTimeout(function(){

        var curr_top = -1;
        var maxh = -1;
        block.find('.resize-children').each(function(){

          // run through all the candidate items
          var cs = $(this).find('ul.list-group');
          cs.each(function(){
              var el = $(this).parent();

              // attempt to resize row by row if there is overflow
              // so, if the top of this item is lower, resize the height of
              // the recent items that are marked ready to resize,
              // then reset the maxh variable to start again.
              if(el.offset().top > curr_top){
                curr_top = el.offset().top
                if(maxh>1)
                  block.find('.ready-to-resize').removeClass('ready-to-resize').css({minHeight: maxh});
                maxh = 1;
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
      }, 100);
    },

    // Run through all the general formatters for a new block to show nicely
    format_block: function(block){

        if(!block){
          console.log('format_block was provided no block.');
          block = $(document);
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
        _fpa.form_utils.resize_children(block);
        block.removeClass('formatting-block');
    }
};
