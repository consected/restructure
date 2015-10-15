_fpa.reports = {
  run_autos: function(sel){  
    if(!sel) sel = '.report-auto';  
    $(sel).each(function(){
      var t = $(this);
      var id = t.attr('data-report-id');
      _fpa.ajax_working(t);
      $.ajax({url: '/reports/'+id+'.json?search_attrs=_use_defaults_'}).success(function(data){
        _fpa.ajax_done(t);
        var res;
        var sa;
        if(data && data.search_attributes){
          sa = JSON.stringify(data.search_attributes, null, '<div>  ').replace(/\{/g, '<div>  ').replace(/\}/g, '</div>').replace(/\"|\[|\]|/g, '');
        }
        if(data && data.results && data.results[0]){
          res = JSON.stringify(data.results, null, '<div>  ').replace(/\{/g, '<div>  ').replace(/\}/g, '</div>').replace(/\"|\[|\]|/g, '');

        }else{
          res = '-'
        }      
        t.find('.report-measure').html(res);
        if(sa)
        t.find('.report-search-attr').html(sa);
      });

    });
    }
};