_fpa.postprocessors_activity_logs = {
  activity_logs_player_contact_phone_type_result_template: function(block, data){

    block.collapse('show');

    _fpa.form_utils.format_block(block);
    _fpa.activity_logs.selected_parent(block, {item_id: data.item_id, rec_type: data.rec_type, item_data: data.item_data, master_id: data.master_id});

  },
  activity_log_player_contact_phone_result_template: function(block, data){
    _fpa.form_utils.format_block(block);
    var d = data;
    var d0;
    for(var e in data){
      if(data.hasOwnProperty(e)){
        d0 = data[e];
        break;
      }
    }

    if(typeof d0 === 'object' && d0.hasOwnProperty('master_id') ){
      // assume if the length is only a single item that it is really the object we are looking for
      d = d0;
    }
    $('.activity-log-list .new-block').addClass('has-records');
    _fpa.activity_logs.selected_parent(block, {item_id: d.item_id, rec_type: d.rec_type, item_data: d.item_data, master_id: d.master_id});

    var url = '/masters/'+d.master_id+'/player_contacts.js';

    _fpa.send_ajax_request(url);

    _fpa.postprocessors.info_update_handler(block, d);
  }
};

$.extend(_fpa.postprocessors, _fpa.postprocessors_activity_logs);
