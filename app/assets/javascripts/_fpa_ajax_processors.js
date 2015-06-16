_fpa.preprocessors = {};

_fpa.postprocessors = {};

    
_fpa.postprocessors['search-results-template'] = function(block, data){

    block.find('.list-group').each(function(){
        var wmax = 0;
        var all = $(this).find('.list-group-item small');
        all.css({display: 'inline-block', whiteSpace: 'nowrap'});
        all.each(function(){
            var wnew = $(this).width();
            if(wnew > wmax)
                wmax = wnew;
        });
        if(wmax>10)
          all.css({minWidth: wmax, width: wmax, display: 'inline-block', marginRight: '1.6em'});
    });


};