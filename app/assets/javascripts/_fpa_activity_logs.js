_fpa.activity_logs = {
  
  // when the sub list parent item (e.g. a phone number) is selected style appropriately
  selected_parent: (block, attrs) => {    
    var items = document.querySelectorAll('.activity-log-sub-list .sub-list-item .list-group');
    for(var item, i = 0; item = items[i]; i++){
      var el = item.parentNode;
      if(item.getAttribute('data-item-id') == attrs.item_id){        
        el.classList.add('item-highlight');
        el.classList.add('selected-item');
      }
      else{
        el.classList.remove('item-highlight');
        el.classList.remove('selected-item');
      }
    }
    
    $('#activity-logs-master-'+attrs.master_id+'- [data-item-id]').removeClass('item-highlight selected-item');
    $('#activity-logs-master-'+attrs.master_id+'- [data-item-id="'+attrs.item_id+'"]').addClass('item-highlight selected-item');
    
    var b = $('.activity-log-actions-holder');
    
    // reset the add new item button to use the correct parent item
    _fpa.view_template(b, 'activity_logs_phone_actions-partial', attrs);  
    
  }
  
};