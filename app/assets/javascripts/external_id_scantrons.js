$.extend(_fpa.postprocessors, { 
    scantron_result_template: function(block, data){
        var d = data;
        if(data.scantron) d = data.scantron;
        _fpa.postprocessors.info_update_handler(block, d);
    }
});