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
      });

    });
    }
};