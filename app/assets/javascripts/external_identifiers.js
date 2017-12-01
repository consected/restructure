Handlebars.registerHelper('format_sage_id', function(text) {
  var d = text.substring(0,3) + ' ' + text.substring(3,6) + ' ' + text.substring(6,10);
  return new Handlebars.SafeString(d);
});

Handlebars.registerHelper('pattern_mask', function(pattern, text) {
  var h = $('<span class="dynamic-span-mask">'+text+'</span>');
  var m = _fpa.masker.mask_from_pattern(pattern);
  h.mask(m.mask, {translation: m.translation, reverse: m.reverse});
  var d = h.html();
  return new Handlebars.SafeString(d);
});
