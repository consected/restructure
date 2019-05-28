_fpa.postprocessors_admin = {
    admin_edit_form: function(block, data){
        var _admin = this;
        _fpa.utils.scrollTo(block, 200, -50);

        $('tr.new-record').before($('tr.admin-list-item').first());

        $('.saved-row').removeClass('saved-row');
        _fpa.form_utils.format_block(block);
        block.find('#admin-edit-cancel').click(function(ev){
            ev.preventDefault();
            block.html('');
        });

        if(block.find('.admin-edit-form.admin-report').length === 1){
            _admin.handle_admin_report_config(block);
        };

        window.setTimeout(function() {
          var el = $('.admin-edit-form textarea');
          el.click();
        }, 300);


        // For the selection of resource types / names in user access control form
        var res_type_change = function($el) {
          var val = $el.val();
          $('#admin_user_access_control_resource_name optgroup[label], #admin_user_access_control_access optgroup[label]').hide();
          $('#admin_user_access_control_resource_name optgroup[label="'+val+'"], #admin_user_access_control_access optgroup[label="'+val+'"]').show();
          if(val == 'activity_log_type') {
            var url = new URL(window.location.href);

            var p = url.searchParams.get('filter[resource_name]')
            var opts = $('#admin_user_access_control_resource_name optgroup[label="'+val+'"] option');
            opts.show();
            if(p) {
              ps = p.replace('__%', '');
              if(ps != p) {
                opts.each(function() {
                  var h = $(this).val();
                  if(h.indexOf(ps) < 0) {
                    $(this).hide();
                  }
                });
              }
            }
          }
        };
        res_type_change($('#admin_user_access_control_resource_type'));
        block.on('change', '#admin_user_access_control_resource_type', function() {
          res_type_change($(this));
        });

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
              console.log('got:'+ ls[last])
              $(this).attr('label', ls[last]);
              $(this).attr('data-group-num', ls[first]);
            }

          }).hide();
          $(filter_sel + ' optgroup[data-group-num="'+val+'"]').show();

        }).addClass('filters-select-attached');

        block.find('#admin_user_role_role_name').not('.added-user-role-typeahead').each(function () {
          var el = $(this);
          _fpa.set_definition('user_roles', function(){
              _fpa.form_utils.setup_typeahead(el, 'user_roles', "user_roles", 50);
          });
        }).addClass('added-user-role-typeahead');


        block.find('.code-editor').not('.code-editor-formatted').each(function () {
            var code_el = $(this).get(0);
            var lint;
            var mode = $(this).attr('data-code-editor-type');
            if(!mode) mode = 'yaml';
            // if(mode == 'yaml') {
            //   lint = true;
            //   mode = 'text/x-yaml';
            // }

            var cm = CodeMirror.fromTextArea(code_el, {
              lineNumbers: true,
              mode: mode,
              foldGutter: true,
              lint: lint,
              gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
            });
            var cme = cm.getWrapperElement();
            cme.style.width = '100%';
            cme.style.height = '100%';
            code_el.CodeMirror = cm;
            cm.refresh();
        }).addClass('code-editor-formatted');

        block.find('.extra-help-info').not('.code-extra-help-info-formatted').each(function () {

            var code_el = $(this).get(0);
            var mode = $(this).attr('data-code-editor-type');
            if(!mode) mode = 'yaml';

            var cm = CodeMirror.fromTextArea(code_el, {
              lineNumbers: true,
              mode: mode,
              readOnly: true,
              foldGutter: true,
              gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
            });

            var cme = cm.getWrapperElement();
            cme.style.width = '100%';
            cme.style.height = '100%';
            cme.style.backgroundColor = 'rgba(255,255,255, 0.2)';
            code_el.CodeMirror = cm;
            cm.refresh();

        }).addClass('code-extra-help-info-formatted');
    },

    admin_result: function(block, data) {
      $('#admin-edit-').html('');
      var b = $('.attached-tablesorter').trigger("update"); ;
      // _fpa.form_utils.format_block($('.tablesorter').parent());
      $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');

      window.setTimeout(function() {
        _fpa.utils.scrollTo(block, 200, -50);
      }, 100);
      window.setTimeout(function() {
        $('prevent-scroll').removeClass('prevent-scroll');
      }, 1000);
    },

    handle_admin_report_config: function(block){

        $('#search_attrs_filter').val('all').attr('disabled', true);
        $('#search_no_disabled').val('1').attr('checked', true).attr('disabled', true);

        $('#search_attr_instruction').hide();
          $('#search_attrs_type').change(function(){
            $('#search_attrs_filter').val('all');

            var d = ($(this).val()!=='general_selection');
            $('#search_attrs_filter').attr('disabled', d);
            $('#search_no_disabled').attr('disabled', d);
          });
          $('#search_attrs_add').click(function(ev){
            ev.preventDefault();
            var n = $('#search_attrs_name').val();
            n = n.underscore();
            var t = $('#search_attrs_type').val();
            var f = $('#search_attrs_filter').val();
            var nd = $('#search_no_disabled').is(':checked');
            var hf = $('#search_hidden_field').is(':checked');
            var m = $('#search_attrs_multi').val();
            var l = $('#search_attrs_label').val();
            var d = $('#search_attrs_default').val();
            var s = $('#search_attrs_config_selections').val();
            var c = $('#search_attrs_conditions').val();
            $('#search_attr_ex').html(":"+n);
            $('#search_attr_instruction').show();



            var add = n + ': ';
            {
                add += '\n  '+ t + ': ';
                if(f === 'all'){
                    add += '\n    all: true';
                }else{
                    add += "\n    " + f;
                }
                if(m)
                    add += "\n    multiple: " + m;
                if(l)
                    add += "\n    label: " + l;

                if(d){
                    if(m === 'single'){
                        d = d.trim();
                    }else{
                        var ds = d.split('\n');
                        d = '';
                        for(var id in ds){
                            d += '\n      - ' + ds[id];
                        }
                    }

                    add += "\n    default: " + d;
                }
                else {
                  if(nd)
                      add += "\n    disabled: false";
                }


                if(hf)
                    add += "\n    hidden: true";

                if(s) {
                  add += "\n    selections: ";
                  var ds = s.split('\n');
                  for(var id in ds){
                      add += '\n      ' + ds[id];
                  }
                }
                if(c) {
                  add += "\n    conditions: ";
                  var ds = c.split('\n');
                  for(var id in ds){
                      add += '\n      ' + ds[id];
                  }
                }


            }
            var $attel = $('#report_search_attrs');
            var attel = $attel[0];


            attel.CodeMirror.save();
            var v = $attel.val();
            $attel.val(v+ "\n\n" + add);
            attel.CodeMirror.setValue($attel.val());
            attel.CodeMirror.refresh();

          });
    }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_admin);
