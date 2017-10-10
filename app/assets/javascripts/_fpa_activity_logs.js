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
  }

};
