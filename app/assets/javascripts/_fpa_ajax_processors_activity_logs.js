_fpa.activity_logs.generate_postprocessors = function (item_type_name)  {

  _fpa.postprocessors_activity_logs = {};

  var item_type_name_plural = '';
  var l = item_type_name.length;
  if(item_type_name[l - 1] == 'y'){
    item_type_name_plural = item_type_name[0, l-2] + 'ies';
  }
  else {
    item_type_name_plural = item_type_name + 's';
  }

    _fpa.postprocessors_activity_logs['activity_log__' + item_type_name_plural + '_main_result_template'] = function(block, data){
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
