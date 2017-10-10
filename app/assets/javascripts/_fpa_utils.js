_fpa.utils = {};

// Jump to the linked item, based on the target ID
// If necessary expand the block containing this item by uncollapsing and showing it
// Finally scroll it onto the viewport if necessary
// Returns the block that was linked if successful
_fpa.utils.jump_to_linked_item = function(target) {

  var block = h;

  $('.item-highlight, .linked-item-highlight').removeClass('item-highlight linked-item-highlight');
  if(!target) return;
  var h = $(target).addClass('item-highlight linked-item-highlight');
  if(!h || h.length == 0)
    return;

  if(!h.is(':visible')){
      // Open up the block containing this item
      h.parents('.collapse').collapse('show');

  }
  // Scroll if necessary
  var rect = h.get(0).getBoundingClientRect();
  var not_visible = !(rect.top >= 0 && rect.top <= $(window).height()/2);
  if(not_visible)
      $.scrollTo(h, 200, {offset: -50});

  return block;
};

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


// Typically returns m/d/yyyy
_fpa.utils.YMDtoLocale = function(stre){

    // Take special care to avoid issues with timezones and daylight savings time quirks
    if((stre.indexOf('t')>=0 && stre.indexOf('z')>=0) || (stre.indexOf('T')>=0 && stre.indexOf('Z')>=0)){
        startTime = new Date(Date.parse(stre));
        startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
        var d = startTime.toLocaleDateString();
    } else {
        var d = new Date(stre).toLocaleDateString(undefined, {timeZone: "UTC"});
    }
    return d;
};

Date.prototype.asLocale = function(){
    return this.toLocaleDateString(undefined, {timeZone: "UTC"});
};

Date.prototype.asYMD = function(){

    var now = this;

    var day = ("0" + now.getDate()).slice(-2);
    var month = ("0" + (now.getMonth() + 1)).slice(-2);

    var today = now.getFullYear()+"-"+(month)+"-"+(day) ;

    return today;
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
                      return JSON.stringify(stre, null, '<div>  ');
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
