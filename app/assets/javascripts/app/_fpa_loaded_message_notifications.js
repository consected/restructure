_fpa.loaded.message_notifications = function () {

  console.debug('loaded message notifcations')
  var data = $('#list_item_ids').html();
  var list_item_ids = JSON.parse(data);

  for (var i in list_item_ids) {
    var c = $(`#message-content-${list_item_ids[i]}`);
    if (c.length === 0) {
      console.log(`No content found for #message-content-${list_item_ids[i]}`);
      return;
    }
    var html = c.html();
    if (!html) {
      console.log(`No html found for #message-content-${list_item_ids[i]}`);
      return;
    }
    var mif = $(`#message-iframe-${list_item_ids[i]}`);
    mif.attr('srcdoc', html).addClass('if-mn-status-complete');
  }

};
