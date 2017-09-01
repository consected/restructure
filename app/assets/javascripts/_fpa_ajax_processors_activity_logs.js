_fpa.postprocessors_activity_logs = {
  activity_logs_player_contact_phone_type_result_template: function(block, data){
    _fpa.form_utils.format_block(block);            
    var master_id = data.master_id;
    $('#activity-logs-' + master_id).addClass('in');
    _fpa.activity_logs.selected_parent(block, {item_id: data.item_id, rec_type: data.rec_type, item_data: data.item_data});
  },
  activity_logs_player_contact_email_type_result_template: function(block, data){
    _fpa.form_utils.format_block(block);            
    var master_id = data.activity_logs.master_id;
    $('#activity-logs-' + master_id).addClass('in');
  },
  activity_logs_generic_result_template: function(block, data){
    _fpa.form_utils.format_block(block);            
    var master_id = data.activity_logs.master_id;
    $('#activity-logs-' + master_id).addClass('in');
  }
};

$.extend(_fpa.postprocessors, _fpa.postprocessors_activity_logs);
