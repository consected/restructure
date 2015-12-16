$.extend(_fpa.postprocessors, {
  test_thing_result_template: function(block, data){
        var d = data;
        if(data.test_thing) d = data.test_thing;
        _fpa.postprocessors.info_update_handler(block, d);
  }
});