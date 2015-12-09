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
            var table_count = $('.count-only [data-col-type="result_count"]');
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
    report_edit_form: function(block, data){
        
        $.scrollTo(block, 200, {offset:-50});
        _fpa.form_utils.format_block(block);
        block.find('#report-edit-cancel').click(function(ev){
            ev.preventDefault();
            block.html('');
        });
        
        
        $('input[data-field-name="phone"], input[data-field-name="telephone"]').mask("(000)000-0000 nn", {'translation': {0: {pattern: /\d/}, n: {pattern: /.*/, recursive: true, optional: true}}});
        
        
                
    },
    
    edit_report_result: function(block, data){
        $('#report-edit-').html("");
        var row = $('#report-item-' + data.report_item.id);
        
        for(var i in data.report_item){
            if(data.report_item.hasOwnProperty(i))
                row.find('[data-col-type="'+i+'"]').first().html(data.report_item[i]);
        };
                
        //_fpa.postprocessors.reports_result(row);
    }
    
};
$.extend(_fpa.postprocessors, _fpa.postprocessors_reports);
