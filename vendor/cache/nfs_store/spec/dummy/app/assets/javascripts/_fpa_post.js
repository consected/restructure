_fpa.postprocessors = {
  default: function(block, data, has_postprocessor){
  },
  after_error: function(block, status, error){
    if(status=='abort'){
      $('#master_results_block').html('<h3  class="text-center"><span class="glyphicon glyphicon-pause search-canceled" data-toggle="popover" data-trigger="click hover" data-content="search paused while new entries are added"></span></h3>').addClass('search-status-abort');
      $('.search-canceled').popover();
    }else{
      var e = '';
      if(status) e = status;
      $('#master_results_block').addClass('search-status-error');
      _fpa.processor_handlers.form_setup(block);

    }
  }
}

_fpa.preprocessors = {

    before_all: function(block){

    },

    default: function(block, data, has_preprocessor){

    },

    nfs_store_browse_list_results: function(block) {
      var p = block.parents('.container-block').first();
      p.fs_browser = _nfs_store.fs_browser;
      setTimeout(function() { p.fs_browser(p) }, 100);
    }
};
