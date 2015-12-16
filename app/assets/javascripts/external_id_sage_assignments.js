$.extend(_fpa.postprocessors, { 
    sage_assignment_result_template: function(block, data){
        var d = data;
        if(data.sage_assignment) d = data.sage_assignment;
        _fpa.postprocessors.info_update_handler(block, d);
    }
});


Handlebars.registerHelper('format_sage_id', function(text) {
    var d = text.substring(0,3) + ' ' + text.substring(3,6) + ' ' + text.substring(6,10)
    return new Handlebars.SafeString(d);
});