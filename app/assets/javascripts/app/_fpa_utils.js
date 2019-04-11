_fpa.utils = {};

// Jump to the linked item, based on the target ID
// If necessary expand the block containing this item by uncollapsing and showing it
// Finally scroll it onto the viewport if necessary
// Returns the block that was linked if successful
_fpa.utils.jump_to_linked_item = function(target, offset, options) {

  var block = h;
  if(offset == null) offset = -50;
  if(options == null) options = {};

  $('.item-highlight, .linked-item-highlight').removeClass('item-highlight linked-item-highlight');

  var isj = target instanceof jQuery;
  // Ensure the target is valid
  if(!isj && (!target || target.length < 2)) return;

  var h = $(target);
  if(!h || h.length == 0)
    return;

  h = h.first();

  if(target != '#body-top' && !options.no_highlight) {
    h.addClass('item-highlight linked-item-highlight');
  }

  if(!h.is(':visible')){
      // Open up the block containing this item
      h.parents('.collapse').collapse('show');
      if(h.hasClass('collapse')) {
        $('[data-toggle="collapse"][data-target="'+target+'"]:visible').first().click()
      }

  }
  // Scroll if necessary
  if(!_fpa.utils.inViewport(h, true))
      _fpa.utils.scrollTo(h, 200, offset);

  return block;
};

_fpa.utils.inViewport = function(el, topHalf) {
  topHalf  = topHalf ? 2 : 1;
  var rect = el.get(0).getBoundingClientRect();
  return (rect.top >= 0 && rect.top <= $(window).height()/topHalf);
};

_fpa.utils.scrollTo = function(el, height, offset) {
  $.scrollTo(el, height, {offset: offset});
};

_fpa.utils.pluralize = function(str) {
  if(str[str.length - 1] == 'y')
    str = str.slice(0,-1) + 'ies';
  else
    str = str + 's';
  return str;
}

_fpa.utils.make_readable_notes_expandable = function(block, max_height, click_callback) {
  if(!max_height) max_height = 40;

  block.not('.attached-expandable').each(function(){
      if($(this).height() > max_height){
          $(this).click(function(){
            // don't do it if there is a selection
            if(window.getSelection().toString()) return;
            _fpa.form_utils.toggle_expandable($(this));
            if(click_callback)
              click_callback(block, $(this));
          }).addClass('expandable').attr('title', 'click to expand / shrink');
      }else{
          $(this).addClass('not-expandable');
      };
  }).addClass('attached-expandable');
};

_fpa.utils.show_modal_results = function(){
  var h = '<div id="modal_results_block" class=""></div>';

  _fpa.show_modal(h, "", true);
}
// Get the data-some-attr="" name value pairs from a jQuery element, removing data- and
// underscoring for easy data.some_attr access
_fpa.utils.get_data_attribs = function(block){

  var attrs = {};
  var el = block.get(0);
  for (var att, i = 0, atts = el.attributes, n = atts.length; i < n; i++){
      att = atts[i];
      var name = att.nodeName.replace('data-', '').underscore();
      attrs[name] = att.value;
  }
  return attrs;
};

_fpa.utils.capitalize = function(str) {
    var res = '';
    if(str != null && str.replace){
        var email_address_test = /.+@.+\..+/;
        var email_address = email_address_test.test(str);
        if(!email_address)
            res = str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
        else
            res = str;
    }else{
        res =  str;
    }
    return res;
};

_fpa.utils.nl2br = function(text){
    text = Handlebars.Utils.escapeExpression(text);
    var nl2br = (text + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + '<br>' + '$2');
    return new Handlebars.SafeString(nl2br);
};

String.prototype.capitalize = function(){
    return _fpa.utils.capitalize(this);
};

String.prototype.underscore = function(){
    return this.replace(/[^a-zA-z0-9]/g,'_');
};

String.prototype.hyphenate = function(){
    return this.replace(/_/g,'-');
};


String.prototype.pathify = function(){
    return this.replace(/__/g, '/');
};

_fpa.utils.is_blank = function(i){
  return (i === null || i === '');
};


_fpa.utils.html_entity_map = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': '&quot;',
    "'": '&#39;'
};

_fpa.utils.escape_html = function (string) {
    return String(string).replace(/[&<>"']/g, function (s) {
      return _fpa.html_entity_map[s];
    });
};


// This always returns the original if the date is not processable
_fpa.utils.ISOdatetoTimestamp = function(stre){

  if(stre == null) return null;

  if(typeof stre == 'number') return stre;

  if( (stre.indexOf('t')>=0 && stre.indexOf('z')>=0) ||
      (stre.indexOf('T')>=0 && stre.indexOf('Z')>=0) ||
      (stre.indexOf('t')>=0 && stre.indexOf('+')>=0) ||
      (stre.indexOf('T')>=0 && stre.indexOf('+')>=0)) {
    var ds = new Date(Date.parse(stre));
    if(!ds) return stre;
    var res = ds.getTime().toFixed(0);
    return res;
  } else {
    return stre;
  }
};

// Typically returns mm/dd/yyyy

_fpa.utils.YMDtoLocale = function(stre){

    // Take special care to avoid issues with timezones and daylight savings time quirks
    if((stre.indexOf('t')>=0 && stre.indexOf('z')>=0) || (stre.indexOf('T')>=0 && stre.indexOf('Z')>=0) || stre.length > 15){
        // startTime = new Date(Date.parse(stre));
        // startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
        // var d = startTime.asLocale();
        var d = _fpa.utils.isoDateStringToLocale(stre);
    } else {
      // This locale string only includes the date
        // var d = new Date(stre).asLocale();
        var d = _fpa.utils.isoDateStringToLocale(stre);
    }
    if(d == 'Invalid Date') d = stre;

    return d;
};

_fpa.utils.parseLocaleDate = function(stre) {
  stre = stre.trim();
  if(stre == '') return '';
  var str = stre.substring(6,10) + '-' + stre.substring(0,2) + '-' + stre.substring(3,5) + 'T00:00:00Z';
  return new Date(str);

};

// Get locale string, only including the date and not the time portion
Date.prototype.asLocale = function() {
  return _fpa.utils.isoDateStringToLocale(this.toISOString());
  // Don't trust browser locale handling
  //return this.toLocaleDateString(undefined, {timeZone: "UTC"});

};

// Take yyyy-mm-dd... and make it mm/dd/yyyy
// TODO: conform to _fpa.user_prefs.date_format
_fpa.utils.isoDateStringToLocale = function(stre) {
  stre = stre.trim();
  if(stre == '') return '';
  return stre.substring(5,7) + '/' + stre.substring(8,10) + '/' + stre.substring(0,4);

};

Date.prototype.asYMD = function(){

    var now = this;

    var day = ("0" + now.getUTCDate()).slice(-2);
    var month = ("0" + (now.getUTCMonth() + 1)).slice(-2);

    var today = now.getUTCFullYear()+"-"+(month)+"-"+(day) ;

    return today;
};

// Translate an obj from a loc in the translation files, such as 'field_labels'
// Returns the original obj if not found
_fpa.utils.translate = function(obj, loc) {

  if(_fpa.locale_t && _fpa.locale_t[loc]) {
    var t = _fpa.locale_t.field_names[obj];
    if(t) {
      obj = t;
      return obj;
    }
  }
  return obj;
};

_fpa.utils.pretty_print = function(stre, options_hash){
    if(stre === null || stre === '' ) return "";
        var startTime;
        var asTimestamp;
        if(stre && stre.length >= 8){
            if (!stre.match(/^\d\d\d\d-\d\d-\d\d.*/)){
            }else if((stre.indexOf('t')>=0 && stre.indexOf('z')>=0) || (stre.indexOf('T')>=0 && stre.indexOf('Z')>=0)){
                startTime = new Date(Date.parse(stre ));
                asTimestamp = true;
            }
            else{
                startTime = new Date(Date.parse(stre + 'T00:00:00Z'));
                asTimestamp = false;
            }
        }
        if(typeof startTime === 'undefined' || !startTime || startTime == 'Invalid Date'){
            if(options_hash.return_string){

              // This ugly condition checks for the difficult case where Handlebars decides to mangle empty numbers
              // Rather than returning null as previous, Handlebars now returns an empty object {}
              // So now, we check for:
              // is it not Null
              // is it not a String (typeof doesn't always work, since new String('abc') can return object for typeof)
              // is it not a Number
              // and does typeof suggest that this is an object (which we really want to pretty print)
              // If this appears to be an object and none of the others then
              // check if the object is not empty so we can pretty print it
              // otherwise it is empty, so return null, which is what it really should be
                if(stre !== null && !(stre instanceof String) && !(stre instanceof Number) && (typeof stre == 'object')){
                    if(Object.keys(stre).length > 0){

                      return stre;
                    }
                    else {
                      return null;
                    }
                }

                if(options_hash.capitalize){
                    if(!stre || stre.length < 30){
                        //stre = Handlebars.Utils.escapeExpression(stre);
                        return _fpa.utils.capitalize(stre);
                    }else{
                        return _fpa.utils.nl2br(stre);
                    }
                }
                else{
                    return _fpa.utils.nl2br(stre);
                }
            } else {
                return null;
            }
        }
        if(asTimestamp){
            startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
            return startTime.toLocaleDateString();
        } else {
            return new Date(stre).toLocaleDateString(undefined, {timeZone: "UTC"});
        }
        return stre;
};
