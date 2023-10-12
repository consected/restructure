/*
  Use a named formatter to format some text
  For example:
    {{format_with options.formatter_var some_text}}

  Where options.formatter_var might have a value like 'format_10_digit_external_id'
*/
Handlebars.registerHelper('format_with', function (formatter, text) {
  var fs = formatter.split(' ');
  var ffn = null;
  if (fs[1]) {
    ffn = fs.shift();
    var arg0 = fs.join(' ').replace(/"/g, '');
    var arg1 = text;
  }
  else {
    ffn = fs[0];
    var arg0 = text;
  }
  var d = Handlebars.helpers[ffn](arg0, arg1);
  return new Handlebars.SafeString(d);
});

Handlebars.registerHelper('format_sage_id', function (text) {
  var d = text.substring(0, 3) + ' ' + text.substring(3, 6) + ' ' + text.substring(6, 10);
  return new Handlebars.SafeString(d);
});


Handlebars.registerHelper('uppercase', function (text) {
  return new Handlebars.SafeString(text.toUpperCase());
});


Handlebars.registerHelper('pattern_mask', function (pattern, text) {
  var h = $('<span class="dynamic-span-mask">' + text + '</span>');
  var m = _fpa.masker.mask_from_pattern(pattern);
  h.mask(m.mask, { translation: m.translation, reverse: m.reverse });
  var d = h.html();
  return new Handlebars.SafeString(d.toUpperCase());
});

Handlebars.registerHelper('format_10_digit_external_id', function (text) {
  text = "" + text; // force text type
  var d = text.substring(0, 3) + ' ' + text.substring(3, 6) + ' ' + text.substring(6, 10);
  return new Handlebars.SafeString(d);
});
