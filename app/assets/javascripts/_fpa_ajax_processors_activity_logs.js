_fpa.activity_logs.generate_postprocessors = (item_type_name) => {

  _fpa.postprocessors_activity_logs = {};

    _fpa.postprocessors_activity_logs['activity_log__' + item_type_name + '_main_result_template'] = function(block, data){
      _fpa.activity_logs.show_main_block(block, data);
    },
    _fpa.postprocessors_activity_logs['activity_log__' + item_type_name + '_result_template'] = function(block, data){
      _fpa.activity_logs.show_log_block(block, data);
    },
    _fpa.postprocessors_activity_logs['activity_log__' + item_type_name + '_blank_log_result_template'] = function(block, data){
      _fpa.activity_logs.show_log_block(block, data);
    }

  $.extend(_fpa.postprocessors, _fpa.postprocessors_activity_logs);

}
