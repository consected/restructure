_fpa.resize_labels = function(block, data){
    block.find('.list-group').each(function(){
        var wmax = 0;
        var all = $(this).find('.list-group-item').not('.is-heading, .is-combo').find('small, label');
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


_fpa.preprocessors = {};

_fpa.postprocessors = {};

_fpa.preprocessors.default = function(block, data){
    
};
_fpa.postprocessors.default = function(block, data){
  _fpa.form_utils.setup_chosen(block);  
  
  block.find('input, select').each(function(){ 
      if($(this).val() != '') 
          $(this).addClass('has-value'); 
      else 
          $(this).removeClass('has-value'); 
  });
  
  _fpa.resize_labels(block, data);
  _fpa.form_utils.filtered_selector();
  
  block.find('.tablesorter').tablesorter( {dateFormat: 'us', headers: {0: {sorter: false}, 8: {sorter: false}}}); 

    
};    
_fpa.postprocessors['search-results-template'] = function(block, data){

   
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