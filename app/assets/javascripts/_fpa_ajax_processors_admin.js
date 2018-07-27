_fpa.postprocessors_admin = {
    admin_edit_form: function(block, data){
        var _admin = this;
        $.scrollTo(block, 200, {offset:-50});

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
    },

    admin_result: function(block, data) {
      $('#admin-edit-').html('');
      var b = $('.attached-tablesorter').trigger("update"); ;
      // _fpa.form_utils.format_block($('.tablesorter').parent());
      $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');

      window.setTimeout(function() {
        $.scrollTo(block, 200, {offset:-50});
      }, 100);
      window.setTimeout(function() {
        $('prevent-scroll').removeClass('prevent-scroll');
      }, 1000);
    },

    handle_admin_report_config: function(block){

        $('#search_attrs_filter').val('all').attr('disabled', true);
        $('#search_attr_instruction').hide();
          $('#search_attrs_type').change(function(){
            $('#search_attrs_filter').val('all');

            var d = ($(this).val()!=='general_selection');
            $('#search_attrs_filter').attr('disabled', d);
          });
          $('#search_attrs_add').click(function(ev){
            ev.preventDefault();
            var n = $('#search_attrs_name').val();
            n = n.underscore();
            var t = $('#search_attrs_type').val();
            var f = $('#search_attrs_filter').val();
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
            var v = $('#report_search_attrs').val();
            $('#report_search_attrs').val(v+ "\n" + add);

          });
    }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_admin);
