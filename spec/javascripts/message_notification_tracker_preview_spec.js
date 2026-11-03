//= require app/_fpa.js
//= require app/_fpa_ajax_processors_trackers.js

// Verifies tracker notification links load their preview through the shared modal.
describe('message notification tracker preview', function () {
  it('fetches the preview and opens the existing modal', function () {
    var url = '/masters/12/message_notifications/34';
    var response = '<section class="message-notification-preview">Preview</section>';
    var request = $.Deferred();
    var $link = $('<a href="' + url + '"></a>');

    spyOn($, 'get').and.returnValue(request.promise());
    spyOn(_fpa, 'show_modal');

    _fpa.postprocessors_trackers.open_message_notification($link, $('<div></div>'), url);
    request.resolve(response);

    expect($.get).toHaveBeenCalledWith(url);
    expect(_fpa.show_modal).toHaveBeenCalledWith(response, 'Message notification preview', 'lg');
  });
});