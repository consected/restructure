_fpa.postprocessors_activity_logs = {
  activity_logs_player_contact_result_template: function(block, data){
    var master_id = data.activity_logs.master_id;
    $('#activity-logs-generic-' + master_id).addClass('in');
  }
};

$.extend(_fpa.postprocessors, _fpa.postprocessors_activity_logs);
