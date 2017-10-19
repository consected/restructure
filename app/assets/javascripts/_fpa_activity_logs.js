_fpa.activity_logs = {

  // when the sub list parent item (e.g. a phone number) is selected style appropriately
  selected_parent: (block, attrs) => {
    var items = document.querySelectorAll('.activity-log-sub-list .sub-list-item .list-group');
    for(var item, i = 0; item = items[i]; i++){
      var el = item.parentNode;
      if(item.getAttribute('data-item-id') == attrs.item_id){
        el.classList.add('item-highlight');
        el.classList.add('selected-item');
        el.classList.remove('linked-item-highlight');
      }
      else{
        el.classList.remove('item-highlight');
        el.classList.remove('selected-item');
        el.classList.remove('linked-item-highlight');
      }
    }

    $('#activity-logs-master-'+attrs.master_id+'- [data-item-id]').removeClass('item-highlight selected-item');
    $('#activity-logs-master-'+attrs.master_id+'- [data-item-id="'+attrs.item_id+'"]').addClass('item-highlight selected-item');


    $('.activity-log-list .new-block.has-records').addClass('hidden');

  },
  unselect_all: (block, master_id) => {
    _fpa.activity_logs.selected_parent(block, { master_id: master_id })
  },

  show_main_block: (block, data) => {

    if(block.not('.collapsing') && block.not('.in')) block.collapse('show');

    _fpa.form_utils.format_block(block);
    _fpa.activity_logs.selected_parent(block, {item_id: data.item_id, rec_type: data.rec_type, item_data: data.item_data, master_id: data.master_id});


  },

  show_log_block: (block, data) => {
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
