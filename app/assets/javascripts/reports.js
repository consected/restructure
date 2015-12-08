_fpa.loaded.reports = function(){
    
    _fpa.postprocessors.reports_form($('.report-criteria'));
    
};

_fpa.reports = {
    
    results_subsearch: function(block){
        block.find('td[data-col-type]').not('.attached_report_search').each(function(){
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
        
        
    }
    
    
};
