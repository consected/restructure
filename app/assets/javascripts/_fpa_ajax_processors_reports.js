_fpa.preprocessors_reports = {
  report_edit_form: function(block){

    $('.report-item-edit').find('.report-edit-cancel').click();

  }

};

_fpa.postprocessors_reports = {

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

        block.find('form').not('.attached-complete-listener').on('ajax:complete',function(){
            $('#search_attrs__filter_previous_').attr('checked', false);
            $('#filter_on_block').html('');
        }).addClass('attached-complete-listener');

        var cb = $('#search_attrs__filter_previous_').not('.attached-click-listener');

        if(cb.length === 1 && cb.is(':checked')){
            window.setTimeout(function(){
                $('a#get_filter_previous').click();
            }, 100);
        }

        cb.on('change',function(){
            if(!$('#search_attrs__filter_previous_').is(':checked')){
               $('#filter_on_block').html('');
            }else{
                window.setTimeout(function(){
                    $('a#get_filter_previous').click();
                }, 100);
            }
            return false;
        }).addClass('attached-click-listener');

    },

    reports_result: function(block, data){

        if(data){
            // Update the search form results count bar manually
            var c = $('.result-count').html();
            var table_count = $('.count-only [data-col-type="result_count"]').not('.report-el-was-from-new');
            var h;
            if(table_count.length === 1){
                c = table_count.html();
            }
            data.count = {count: c, show_count: c};
            var h = _fpa.templates['search-count-template'](data);
            $('.search_count_reports').html(h);
        }


        window.setTimeout(function(){
          $('table').addClass('table tablesorter');
          var tables = {trackers:
                  {protocols: 'protocol_id', sub_processes: 'sub_process_id', protocol_events: 'protocol_event_id', users: 'user_id'},
              tracker_history:
                  {protocols: 'protocol_id', sub_processes: 'sub_process_id', protocol_events: 'protocol_event_id', users: 'user_id'},
              masters:
                  {accuracy_scores: 'rank'},
              player_infos:
                  {accuracy_scores: 'rank', users: 'user_id'},
              player_contacts:
                  {'general_selections-item_type+player_contacts_rank': 'rank', users: 'user_id'},
              addresses:
                  {'general_selections-item_type+addresses_rank': 'rank', users: 'user_id'}
          };

          for(var t in tables){
            if(tables.hasOwnProperty(t)){
              var table = tables[t];
              $('td a.edit-entity').click(function(){
                  $('.item-selected').removeClass('item-selected');
                  $(this).parents('tr').first().addClass('item-selected');
              });
              $('td[data-col-type="master_id"]').on('click', function(){
                window.open('/masters/'+$(this).html(), "msid");
                $('.item-selected').removeClass('item-selected');
                $(this).addClass('item-selected');
              }).addClass('hover-link');

              $('td[data-col-type="msid"]').on('click', function(){
                window.open('/masters/'+$(this).html()+'?type=msid', "msid");
                $('.item-selected').removeClass('item-selected');
                $(this).addClass('item-selected');
              }).addClass('hover-link');

              if($('td[data-col-table="'+t+'"]').length > 0 ){
                for(var i in table){

                  if(tables.hasOwnProperty(t)){

                    col_types = tables[t];
                    var idname = col_types[i];
                    console.log("Getting " + i + " for " + idname + ' in ' + t);
                    _fpa.set_definition(i, function(){
                      var pe = _fpa.cache(i);
                      var cells = $('td[data-col-table="'+t+'"][data-col-type="'+idname+'"]');
                      cells.each(function(){
                        var cell = $(this);
                        var d = cell.html();
                        var p = _fpa.get_item_by('value', pe, d);

                        if(!p || p.value == null){
                          p = _fpa.get_item_by('id', pe, d);
                        }
                        if(p) cell.append(' <em>'+p.name+'</em>');
                      });
                    });
                  }
                }
              }
              _fpa.reports.results_subsearch(block);
            }
          }

          _fpa.form_utils.setup_tablesorter($('#report-results-block'));

        }, 50);

    },

    // Edit and New forms need some additional help, since we are attempting to push a form into a table row, which
    // is not valid HTML markup. Instead, we need to make use of the 'form' attribute on input, select and textarea elements,
    // which point the entry back to a form block that sits outside of the table.
    report_edit_form: function(block, data){


        var form = block.find('form');
        var form_id = form.attr('id');
        var row = block.find('tr');
        var item_id = form.attr('data-object-id');

        // if there is an item_id then we are editing a current row.
        // otherwise we are adding a new item
        if(item_id) {
          var orig_row = $('tr#report-item-' + item_id);
        }
        else {
          var orig_row = $('tr#report-item-new');
        }
        orig_row.after(row);
        orig_row.hide();

        // There are typically some hidden fields in the form that need to be moved in with the table fields
        var hidden = block.find('input');
        row.find('.report-edit-btn-cell').append(hidden);

        // Add the form attribute to the fields, pointing to the id of the form
        row.find('input, select, textarea, button').each(function(){
          $(this).attr('form', form_id);
        });

        // Format the block to ensure dates and masked fields, etc work as expected
        _fpa.form_utils.format_block(row);

        $.scrollTo(row, 200, {offset:-50});
        // Setup the cancel button
        row.find('#report-edit-cancel').click(function(ev){
            ev.preventDefault();
            orig_row.show();
            row.remove();
            block.html('');
        });
    },

    edit_report_result: function(block, data){
        $('#report-edit-').html("");
        var id = data.report_item.id;
        var row = $('#report-item-' + id);

        // if we got a row, then we are simply replacing the data of an existing row based on an edit
        // otherwise we were adding a new item, and a row does not exist yet.
        if(row.length == 0) {
          var row = $('#report-item-new');
          row = row.after(row.clone());
          var newid = data.report_item['id'];
          row.attr('id', 'report-item-' + newid);
          var a = row.find('a.edit-entity');
          var href = a.attr('href');
          a.attr('href', href.replace('new', newid));
          row.find('.report-new-item-btn').remove();
          id = '';
        }

        for(var i in data.report_item){
            if(data.report_item.hasOwnProperty(i))
                row.find('[data-col-type="'+i+'"]').first().html(data.report_item[i]);
        };

        row.show();

        $('tr#report-item-edit-' + id).remove();
        $('tr#report-item-new').show();

    }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_reports);
$.extend(_fpa.preprocessors, _fpa.preprocessors_reports);
