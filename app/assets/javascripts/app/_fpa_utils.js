_fpa.utils = {};

// Jump to the linked item, based on the target ID
// If necessary expand the block containing this item by uncollapsing and showing it
// Finally scroll it onto the viewport if necessary
// Returns the block that was linked if successful
_fpa.utils.jump_to_linked_item = function (target, offset, options) {

  if (offset == null) offset = -50;
  if (options == null) options = {};

  $('.item-highlight, .linked-item-highlight').removeClass('item-highlight linked-item-highlight');

  var isj = target instanceof jQuery;
  // Ensure the target is valid
  if (!isj && (!target || target.length < 2)) return;

  var h = $(target);
  if (!h || h.length == 0) {
    var tparts = target.split('-');
    var l = tparts.length;
    var dii = tparts[l - 1];
    var dm = tparts[l - 2];
    if (!dii || !dm) return;
    var dic = target.replace('#', '').replace('-' + dm + '-' + dii, '').replace(/-/g, '_');

    h = $('[data-item-class="' + dic + '"][data-sub-id="' + dii + '"]');
  }

  if (!h || h.length == 0)
    return;

  h = h.first();

  if (target != '#body-top' && !options.no_highlight) {
    h.addClass('item-highlight linked-item-highlight');
  }

  if (!h.is(':visible')) {
    // Open up the block containing this item
    h.parents('.collapse').collapse('show');
    if (h.hasClass('collapse')) {
      $('[data-toggle="collapse"][data-target="' + target + '"]:visible').first().click()
    }
    else {
      _fpa.form_utils.format_block(h);
    }

  }

  var scroll_attempts = 0;
  var jump_scroll = function () {
    // Scroll if necessary
    if (!_fpa.utils.inViewport(h, true)) {
      // If prevent_jump is set, and it is an id hash, and it doesn't match this target then just quit
      var prevent_jump_loc = $(_fpa.state.prevent_jump);
      if (_fpa.state.prevent_jump && _fpa.state.prevent_jump[0] == '#' && prevent_jump_loc.length > 0 && prevent_jump_loc.attr('id') != h.attr('id')) {
        return;
      }
      _fpa.utils.scrollTo(h, 200, offset);
    }

    if ($('.ajax-running').length > 0) {
      scroll_attempts++;
      if (scroll_attempts < 7) {
        window.setTimeout(function () {
          jump_scroll();
        }, 500);
      }
    }
  }


  jump_scroll();

  return h;
};

_fpa.utils.inViewport = function (el, topHalf) {
  topHalf = topHalf ? 2 : 1;
  var rect = el.get(0).getBoundingClientRect();
  return (rect.top >= 0 && rect.top <= $(window).height() / topHalf);
};

_fpa.utils.scrollTo = function (el, height, offset, container) {
  container = container || $;
  container.scrollTo(el, height, { offset: offset });
};

_fpa.utils.pluralize = function (str) {
  if (!str) return;
  orig_str = str;
  str = str.replace(/ss$/, 'sses');
  str = str.replace(/ey$/, 'ies');
  str = str.replace(/ay$/, 'ays');
  if (orig_str == str) str = str.replace(/y$/, 'ies');
  if (orig_str == str) str = str + 's';
  return str;
}

_fpa.utils.singularize = function (str) {
  if (!str) return;
  orig_str = str;
  str = str.replace(/ies$/, 'y');
  str = str.replace(/ays$/, 'ay');
  str = str.replace(/sses$/, 'ss');
  if (orig_str == str) str = str.replace(/s$/, '');
  return str;
}

_fpa.utils.titleize = function (str) {
  if (!str) return;
  str = str.replace(/_/g, ' ')
  str = str.toLowerCase().split(' ');
  for (var i = 0; i < str.length; i++) {
    str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
  }
  return str.join(' ');
}

_fpa.utils.make_readable_notes_expandable = function (block, max_height, click_callback) {
  if (!max_height) max_height = 40;

  block.not('.attached-expandable').each(function () {
    if ($(this).height() > max_height) {
      var this_expandable = $(this);
      var exp_target = $(this).find('.list-group-item-heading');
      var exp_full_block = false;
      if (exp_target.length == 0) {
        exp_full_block = true;
        exp_target = $(this);
      }

      exp_target.click(function () {
        // don't do it if there is a selection
        if (window.getSelection().toString()) return;
        _fpa.form_utils.toggle_expandable(this_expandable);
        if (click_callback)
          click_callback(block, this_expandable);
      }).addClass('expandable-target').attr('title', 'click to expand / shrink');
      this_expandable.addClass('expandable');
    } else {
      $(this).addClass('not-expandable');
    };
  }).addClass('attached-expandable');

  if ($('.attached-expandable').length > 0) {
    $('.expand-all-expandables').not('.attached-click').on('click', function () {
      $('.attached-expandable').not('.expanded').click();
    }).addClass('attached-click').show();
    $('.shrink-all-expandables').not('.attached-click').on('click', function () {
      $('.attached-expandable.expanded').click();
    }).addClass('attached-click').show();
  }
  else {
    $('.expand-all-expandables').not('.attached-click').hide();
    $('.shrink-all-expandables').not('.attached-click').hide()
  }
};

_fpa.utils.show_modal_results = function () {
  var h = '<div id="modal_results_block" class=""></div>';

  _fpa.show_modal(h, "", true);
}
// Get the data-some-attr="" name value pairs from a jQuery element, removing data- and
// underscoring for easy data.some_attr access
_fpa.utils.get_data_attribs = function (block) {

  var attrs = {};
  var el = block.get(0);
  for (var att, i = 0, atts = el.attributes, n = atts.length; i < n; i++) {
    att = atts[i];
    var name = att.nodeName.replace('data-', '').underscore();
    attrs[name] = att.value;
  }
  return attrs;
};

_fpa.utils.capitalize = function (str) {
  var res = '';
  if (str != null && str.replace) {
    var email_address_test = /.+@.+\..+/;
    var email_address = email_address_test.test(str);
    if (!email_address)
      res = str.replace(/\w\S*/g, function (txt) { return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase(); });
    else
      res = str;
  } else {
    res = str;
  }
  return res;
};

_fpa.utils.nl2br = function (text) {
  text = Handlebars.Utils.escapeExpression(text);
  var nl2br = (text + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + '<br>' + '$2');
  return new Handlebars.SafeString(nl2br);
};

_fpa.utils.remove_tags = function (text) {
  var stre = (text + '').replace(/(\<[a-zA-Z0-9\s-=_"']+\/?\>)/g, '');
  return new Handlebars.SafeString(stre);
};



String.prototype.capitalize = function () {
  return _fpa.utils.capitalize(this);
};

String.prototype.underscore = function () {
  return this.toLowerCase().replace(/( |-)/g, '_');
};

String.prototype.ns_underscore = function () {
  return this.toLowerCase().replace(/::/g, '__').replace(/( |\/|-)/g, '_')
};

String.prototype.ns_hyphenate = function () {
  return this.toLowerCase().replace(/::/g, '--').replace(/( |\/|_)/g, '-');
};

String.prototype.hyphenate = function () {
  return this.replace(/_/g, '-');
};

String.prototype.id_hyphenate = function () {
  return this.replace(/[^a-zA-Z0-9\-]/g, '-').toLowerCase();
};


String.prototype.pathify = function () {
  return this.replace(/__/g, '/');
};

String.prototype.pluralize = function () {
  return _fpa.utils.pluralize(this);
};

String.prototype.singularize = function () {
  return _fpa.utils.singularize(this);
};


String.prototype.titleize = function () {
  return _fpa.utils.titleize(this);
};



_fpa.utils.is_blank = function (i) {
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
_fpa.utils.ISOdatetoTimestamp = function (stre) {

  if (stre == null) return null;

  if (typeof stre == 'number') return stre;
  stre = stre.trim();
  if ((stre.indexOf('t') >= 0 && stre.indexOf('z') >= 0) ||
    (stre.indexOf('T') >= 0 && stre.indexOf('Z') >= 0) ||
    (stre.indexOf('t') >= 0 && stre.indexOf('+') >= 0) ||
    (stre.indexOf('T') >= 0 && stre.indexOf('+') >= 0)) {
    var ds = new Date(Date.parse(stre));
    if (!ds) return stre;
    var res = ds.getTime().toFixed(0);
    return res;
  } else {
    return stre;
  }
};

// Typically returns mm/dd/yyyy

_fpa.utils.YMDtoLocale = function (stre) {
  stre = stre.trim();
  // Take special care to avoid issues with timezones and daylight savings time quirks
  if ((stre.indexOf('t') >= 0 && stre.indexOf('z') >= 0) || (stre.indexOf('T') >= 0 && stre.indexOf('Z') >= 0) || stre.length > 15) {
    // startTime = new Date(Date.parse(stre));
    // startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
    // var d = startTime.asLocale();
    var d = _fpa.utils.isoDateStringToLocale(stre);
  } else {
    // This locale string only includes the date
    // var d = new Date(stre).asLocale();
    var d = _fpa.utils.isoDateStringToLocale(stre);
  }
  if (d == 'Invalid Date') d = stre;

  return d;
};


// Typically returns mm/dd/yyyy hh:mm:ss a/pm
_fpa.utils.YMDtimeToLocale = function (stre) {
  stre = stre.trim();
  // Take special care to avoid issues with timezones and daylight savings time quirks
  if ((stre.indexOf('t') >= 0 && stre.indexOf('z') >= 0) || (stre.indexOf('T') >= 0 && stre.indexOf('Z') >= 0) || stre.length > 15) {
    // startTime = new Date(Date.parse(stre));
    // startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
    // var d = startTime.asLocale();
    var d = _fpa.utils.isoDateTimeStringToLocale(stre);
  }
  else if (stre.indexOf(':') == 2) {
    return stre;
  }
  else {
    // This locale string only includes the date
    // var d = new Date(stre).asLocale();
    var d = _fpa.utils.isoDateTimeStringToLocale(stre);
  }
  if (d == 'Invalid Date') d = stre;

  return d;
};

_fpa.utils.parseLocaleDate = function (stre) {
  stre = stre.trim();
  if (stre == '') return '';
  var str = stre.substring(6, 10) + '-' + stre.substring(0, 2) + '-' + stre.substring(3, 5) + 'T00:00:00Z';
  return new Date(str);

};

// Get locale string, only including the date and not the time portion
Date.prototype.asLocale = function () {
  return _fpa.utils.isoDateStringToLocale(this.toISOString());
  // Don't trust browser locale handling
  //return this.toLocaleDateString(undefined, {timeZone: "UTC"});

};

// Take yyyy-mm-dd... and make it mm/dd/yyyy
// TODO: conform to _fpa.user_prefs.date_format
_fpa.utils.isoDateStringToLocale = function (stre) {
  stre = stre.trim();
  if (stre == '') return '';
  return stre.substring(5, 7) + '/' + stre.substring(8, 10) + '/' + stre.substring(0, 4);

};

// Take yyyy-mm-dd hh24:min:ss... and make it mm/dd/yyyy hh24:min:ss
// TODO: conform to _fpa.user_prefs.date_format
_fpa.utils.isoDateTimeStringToLocale = function (stre) {
  stre = stre.trim();
  if (stre == '') return '';

  return stre.substring(5, 7) + '/' + stre.substring(8, 10) + '/' + stre.substring(0, 4) + ' ' +
    stre.substring(11, 19)
    ;

};


Date.prototype.asYMD = function () {

  var now = this;

  var day = ("0" + now.getUTCDate()).slice(-2);
  var month = ("0" + (now.getUTCMonth() + 1)).slice(-2);

  var today = now.getUTCFullYear() + "-" + (month) + "-" + (day);

  return today;
};

// Translate an obj from a loc in the translation files, such as 'field_labels'
// Returns the original obj if not found
_fpa.utils.translate = function (obj, loc) {

  if (_fpa.locale_t && _fpa.locale_t[loc]) {
    var t = _fpa.locale_t.field_names[obj];
    if (t) {
      obj = t;
      return obj;
    }
  }
  return obj;
};

_fpa.utils.pretty_print = function (stre, options_hash) {
  if (stre === null || stre === '') return "";
  var startTime;
  var asTimestamp;
  if (stre && stre.length >= 8) {
    if (!stre.match(/^\d\d\d\d-\d\d-\d\d.*/)) {
    } else if ((stre.indexOf('t') >= 0 && stre.indexOf('z') >= 0) || (stre.indexOf('T') >= 0 && stre.indexOf('Z') >= 0)) {
      startTime = new Date(Date.parse(stre));
      asTimestamp = true;
    }
    else {
      startTime = new Date(Date.parse(stre + 'T00:00:00Z'));
      asTimestamp = false;
    }
  }
  if (typeof startTime === 'undefined' || !startTime || startTime == 'Invalid Date') {
    if (options_hash.return_string) {

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
      if (stre !== null && !(stre instanceof String) && !(stre instanceof Number) && (typeof stre == 'object')) {
        if (Object.keys(stre).length > 0) {

          return stre;
        }
        else {
          return null;
        }
      }

      if (options_hash.capitalize) {
        if (!stre || stre.length < 30) {
          //stre = Handlebars.Utils.escapeExpression(stre);
          stre = _fpa.utils.capitalize(stre);
          if (options_hash.remove_tags) stre = _fpa.utils.remove_tags(stre);
          return stre;
        } else {
          stre = _fpa.utils.nl2br(stre);
          if (options_hash.remove_tags) stre = _fpa.utils.remove_tags(stre);
          return stre;
        }
      }
      else {
        stre = _fpa.utils.nl2br(stre);
        if (options_hash.remove_tags) stre = _fpa.utils.remove_tags(stre);
        return stre;
      }
    } else {
      return null;
    }
  }
  if (asTimestamp) {
    startTime = new Date(startTime.getTime() + (startTime.getTimezoneOffset() * 60000));
    return startTime.toLocaleDateString();
  } else {
    return new Date(stre).toLocaleDateString(undefined, { timeZone: "UTC" });
  }
  return stre;
};

_fpa.utils.calc_field = function (field_name_sym, form_object_item_type_us) {

  var cwdef = _fpa.calculate_with[field_name_sym];

  var target_field = $('[data-attr-name="' + field_name_sym + '"][data-object-name="' + form_object_item_type_us + '"]');

  if (cwdef.sum) {

    for (var i in cwdef.sum) {
      var dfi = cwdef.sum[i];
      $('[data-attr-name="' + dfi + '"][data-object-name="' + form_object_item_type_us + '"]').on('change click keyup', function () {
        var s = 0;
        for (var j in cwdef.sum) {
          var dfj = cwdef.sum[j];
          var val = $('[data-attr-name="' + dfj + '"][data-object-name="' + form_object_item_type_us + '"]').val();
          if (val != null && val != '') {
            val = parseInt(val);
            s += val;
          }
        }
        target_field.val(s);
        target_field.change();
      });

    }

  }

};
