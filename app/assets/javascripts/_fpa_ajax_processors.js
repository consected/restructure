
_fpa.preprocessors = {};

_fpa.postprocessors = {};

_fpa.preprocessors.default = function(block, data, has_preprocessor){
    
};
_fpa.postprocessors.default = function(block, data, has_postprocessor){
    
    // Allow easy default processing where not already performed by the postprocessor
    if(!has_postprocessor){
        _fpa.form_utils.format_block(block);
    }
    
};    
_fpa.postprocessors['search-results-template'] = function(block, data){
    // Ensure we format the viewed item on expanding it 
   
    if(data.masters && data.masters.length < 5)
        _fpa.form_utils.format_block(block);
    
    $('a.master-expander').click(function(){
        var id = $(this).attr('href');
        _fpa.form_utils.format_block($(id));
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