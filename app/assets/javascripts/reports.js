_fpa.loaded.reports = function(){

    _fpa.postprocessors.reports_form($('.report-criteria'));
    $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');

    if($('body').hasClass('user_page')) {
      _fpa.reports.window_scrolling();      
    }


    // If this an editable data form, automatically submit it if there are no criteria fields to enter
    if($('#editable_data').length == 1 && $('.report-criteria-fields').length >= 1)
        $('input[type="submit"][value="table"]').click();
};

_fpa.reports = {

    window_scrolling: function(){
      $('html').css({overflow: 'hidden'}).on('wheel', function(){
        _fpa.reports.report_position_buttons('go-to-results');
        _fpa.reports.reset_window_scrolling();
      });
    },
    reset_window_scrolling: function(){
      $('html').off('wheel');
    },
    report_position_buttons: function (to_loc) {
      var sb = $('.show-results-btn');
      sb.not('.has-rsf-clicks').click(function(e) {
        e.preventDefault();
        _fpa.reports.report_position_buttons('go-to-results');
      }).addClass('has-rsf-clicks');
      var rf = $('.back-to-search-form-btn');
      rf.not('.has-rsf-clicks').click(function(e) {
        e.preventDefault();
        _fpa.reports.report_position_buttons('go-to-form');
      }).addClass('has-rsf-clicks');

      if(to_loc == 'go-to-results') {
        sb.hide();
        rf.show();
        _fpa.reports.reset_window_scrolling();
        $.scrollTo('#report-results-block', 200);
      }
      else if(to_loc == 'go-to-form'){
        sb.show();
        rf.hide();
        _fpa.reports.window_scrolling();
        $.scrollTo('#body-top', 200);
      }
      // window.location.hash = '';
    },
    results_subsearch: function(block){
        block.find('td[data-col-type^="search_reports_"]').not('.attached_report_search').each(function(){
            var dct = $(this).attr('data-col-type');
            if(!$(this).hasClass('attached_report_search') && dct.match(/search_reports_[0-9]+_.+/)){
                var dct_parts = dct.split('_', 4);

                var dct_field = dct_parts[3];
                var dct_report = dct_parts[2];
                var dct_search = $(this).html();

                var url = "/reports/"+dct_report+".json?&search_attrs["+ dct_field+"]="+dct_search+"&commit=search";

                var new_l = $('<a href="'+url+'" data-remote="true" data-result-target="#modal_results_block" data-result-target-force="true" data-template="modal-pi-search-results-template" title="click to search">'+$(this).html()+'</a>');

                $(this).html(new_l);
                $(this).addClass('attached_report_search')
                new_l.click(function(){
                    var h = '<div id="modal_results_block" class=""></div>';

                    _fpa.show_modal(h, "Search results for " + dct_search, true);

                });



            }
        });


    },
    run_autos: function(sel){
        if(!sel) sel = '.report-auto';
        $(sel).each(function(){
          var t = $(this);
          var id = t.attr('data-report-id');
          _fpa.ajax_working(t);
          $.ajax({
            url: '/reports/'+id+'.json?search_attrs=_use_defaults_',
            success: function(data){
              _fpa.ajax_done(t);
              var res;
              var sa;
              if(data && data.search_attributes){
                sa = "";

                for(var i in data.search_attributes){
                    if(data.search_attributes.hasOwnProperty(i) && i!=='ids_filter_previous'){
                        var d = data.search_attributes[i];
                        sa += '<div class="report-search-attr"><span class="attr-label">'+i+'</span><span class="attr-val">' + _fpa.utils.pretty_print(d, {return_string: true}) + '</span></div>';
                    }
                }

                //sa = JSON.stringify(data.search_attributes, null, '<div>  ').replace(/\{/g, '<div>  ').replace(/\}/g, '</div>').replace(/\"|\[|\]|/g, '').replace(/_/g ,' ');
              }
              if(data && data.results && data.results[0]){
                res = JSON.stringify(data.results, null, '  ').replace(/\{/g, '<div>  ').replace(/\},?/g, '</div>').replace(/\"|\[|\]|/g, '');

              }else{
                res = '-';
              }
              t.find('.report-measure').html(res);
              if(sa)
              t.find('.report-search-attr').html(sa);
          }
        });

      });
    }


};
