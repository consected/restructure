
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
        
        $(id).on('shown.bs.collapse', function(){
            $.scrollTo($(this), 200, {offset:-50} );
            $(this).off('shown.bs.collapse');
        });
    });
   
};

_fpa.postprocessors.tracker_edit_form = function(block, data){
  
  // Handle auto date entry in the tracker edit form
  _fpa.form_utils.format_block(block);
  
  block.find('#tracker_outcome, #tracker_event').change(function(){
      var el = block.find('#'+$(this).prop('id')+'_date');
      if(!_fpa.utils.is_blank($(this).val())){
          
          var v = (new Date()).asYMD();
          el.val(v);
      }else{
          el.val(null);
      }
          
      
  });
  
};
