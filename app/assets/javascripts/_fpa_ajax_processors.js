_fpa.preprocessors = {};

_fpa.postprocessors = {};

_fpa.preprocessors.default = function(block, data){
    
};
_fpa.postprocessors.default = function(block, data){
    
  $('select[multiple]').chosen({width: '100%'});  
  
    
};    
_fpa.postprocessors['search-results-template'] = function(block, data){

    block.find('.list-group').each(function(){
        var wmax = 0;
        var all = $(this).find('.list-group-item').not('.is-heading, .is-combo').find('small');
        all.css({display: 'inline-block', whiteSpace: 'nowrap'});
        all.each(function(){
            var wnew = $(this).width();
            if(wnew > wmax)
                wmax = wnew;
        });
        if(wmax>10)
          all.css({minWidth: wmax, width: wmax}).addClass('list-small-label');
    });

   
};

_fpa.postprocessors.item_flags_edit_form = function(block, data){
  
};
_fpa.postprocessors['item-flags-result-template'] = function(block, data){
  
};
/*
_fpa.postprocessors['item-flags-result-template'] = function(block, data){
 var b = $('#item-flags-block');
 var f = data.item_flags;
 var i = f.item_type.replace('_','-') + "-" + f.master_id + '-' + f.item_id;
 $('#'+i + ' .flag-entity').popover({html: b.html(), placement: 'top', trigger: 'manual'}).popover('show');
    
};
*/