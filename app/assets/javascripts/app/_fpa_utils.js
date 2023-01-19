_fpa.utils = {
  DateTime: luxon.DateTime,
};

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
    var dic = target
      .replace('#', '')
      .replace('-' + dm + '-' + dii, '')
      .replace(/-/g, '_');

    h = $('[data-item-class="' + dic + '"][data-sub-id="' + dii + '"]');
  }

  if (!h || h.length == 0) return;

  h = h.first();

  if (target != '#body-top' && !options.no_highlight) {
    h.addClass('item-highlight linked-item-highlight');
  }

  if (!h.is(':visible')) {
    // Open up the block containing this item
    h.parents('.collapse').collapse('show');
    if (h.hasClass('collapse')) {
      $('[data-toggle="collapse"][data-target="' + target + '"]:visible')
        .first()
        .click();
    } else {
      _fpa.form_utils.format_block(h);
    }
  }

  var scroll_attempts = 0;
  var jump_scroll = function () {
    // Scroll if necessary
    if (!_fpa.utils.inViewport(h, true)) {
      // If prevent_jump is set, and it is an id hash, and it doesn't match this target then just quit
      var prevent_jump_loc = $(_fpa.state.prevent_jump);
      if (
        _fpa.state.prevent_jump &&
        _fpa.state.prevent_jump[0] == '#' &&
        prevent_jump_loc.length > 0 &&
        prevent_jump_loc.attr('id') != h.attr('id')
      ) {
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
  };

  jump_scroll();

  return h;
};

_fpa.utils.inViewport = function (el, topHalf) {
  topHalf = topHalf ? 2 : 1;
  var rect = el.get(0).getBoundingClientRect();
  return rect.top >= 0 && rect.top <= $(window).height() / topHalf;
};

// Scroll the container to a position (in pixels), x-y position {left:250, top:"50px"}
// or to a jQuery element $("#element")
// See: https://github.com/flesler/jquery.scrollTo for more info
// pos_or_el: position or element to scroll to
// settings: duration in ms, or other settings, such as { axis: 'y' }
// offset: offset to apply, especially if using an element to scroll to, a number or { left: 0, top: 300 }
// container: the element to scroll
_fpa.utils.scrollTo = function (pos_or_el, settings, offset, container) {
  container = container || $;
  container.scrollTo(pos_or_el, settings, { offset: offset });
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
};

_fpa.utils.singularize = function (str) {
  if (!str) return;
  orig_str = str;
  str = str.replace(/ies$/, 'y');
  str = str.replace(/ays$/, 'ay');
  str = str.replace(/sses$/, 'ss');
  if (orig_str == str) str = str.replace(/s$/, '');
  return str;
};

_fpa.utils.titleize = function (str) {
  if (!str) return;
  str = str.replace(/_/g, ' ');
  str = str.toLowerCase().split(' ');
  for (var i = 0; i < str.length; i++) {
    str[i] = str[i].charAt(0).toUpperCase() + str[i].slice(1);
  }
  return str.join(' ');
};

_fpa.utils.make_readable_notes_expandable = function (block, max_height, click_callback) {
  if (!max_height) max_height = 40;

  block
    .not('.attached-expandable')
    .each(function () {
      if ($(this).height() > max_height) {
        var this_expandable = $(this);
        var exp_target = $(this).find('.list-group-item-heading');
        var exp_full_block = false;
        if (exp_target.length == 0) {
          exp_full_block = true;
          exp_target = $(this);
        }

        exp_target
          .click(function () {
            // don't do it if there is a selection
            if (window.getSelection().toString()) return;
            _fpa.form_utils.toggle_expandable(this_expandable);
            if (click_callback) click_callback(block, this_expandable);
          })
          .addClass('expandable-target')
          .attr('title', 'click to expand / shrink');
        this_expandable.addClass('expandable');
      } else {
        $(this).addClass('not-expandable');
      }
    })
    .addClass('attached-expandable');

  if ($('.attached-expandable').length > 0) {
    $('.expand-all-expandables')
      .not('.attached-click')
      .on('click', function () {
        $('.attached-expandable').not('.expanded').click();
      })
      .addClass('attached-click')
      .show();
    $('.shrink-all-expandables')
      .not('.attached-click')
      .on('click', function () {
        $('.attached-expandable.expanded').click();
      })
      .addClass('attached-click')
      .show();
  } else {
    $('.expand-all-expandables').not('.attached-click').hide();
    $('.shrink-all-expandables').not('.attached-click').hide();
  }
};

_fpa.utils.show_modal_results = function () {
  var h = '<div id="modal_results_block" class=""></div>';

  _fpa.show_modal(h, '', true);
};
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
      res = str.replace(/\w\S*/g, function (txt) {
        return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
      });
    else res = str;
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
  return this.toLowerCase()
    .replace(/::/g, '__')
    .replace(/( |\/|-)/g, '_');
};

String.prototype.ns_hyphenate = function () {
  return this.toLowerCase()
    .replace(/::/g, '--')
    .replace(/( |\/|_)/g, '-');
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
  return i === null || i === '';
};

_fpa.utils.html_entity_map = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
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
  if (
    (stre.indexOf('t') >= 0 && stre.indexOf('z') >= 0) ||
    (stre.indexOf('T') >= 0 && stre.indexOf('Z') >= 0) ||
    (stre.indexOf('t') >= 0 && stre.indexOf('+') >= 0) ||
    (stre.indexOf('T') >= 0 && stre.indexOf('+') >= 0)
  ) {
    const dt = _fpa.utils.DateTime.fromISO(stre);
    if (dt.isValid) return dt.valueOf();
    else return stre;
  } else {
    return stre;
  }
};

// Typically returns mm/dd/yyyy or Invalid DateTime
_fpa.utils.YMDtoLocale = function (stre) {
  stre = stre.trim();
  let d = _fpa.utils.isoDateStringToLocale(stre);
  if (d === 'Invalid DateTime') d = stre;

  return d;
};

// Typically returns mm/dd/yyyy hh:mm:ss a/pm
_fpa.utils.YMDtimeToLocale = function (stre) {
  stre = stre.trim();
  let d;

  // Take special care to avoid issues with timezones and daylight savings time quirks
  if (
    (stre.indexOf('t') >= 0 && stre.indexOf('z') >= 0) ||
    (stre.indexOf('T') >= 0 && stre.indexOf('Z') >= 0) ||
    stre.length > 15
  ) {
    d = _fpa.utils.isoDateTimeStringToLocale(stre);
  } else if (stre.indexOf(':') === 2) {
    // stre is Time: 00:00:00 with colon on 2nd position (0-based).
    return stre;
  } else {
    // This locale string only includes the date
    // var d = new Date(stre).asLocale();
    d = _fpa.utils.isoDateTimeStringToLocale(stre);
  }
  if (d === 'Invalid DateTime') d = stre;

  return d;
};

// Returns a JS object.
_fpa.utils.parseLocaleDate = function (stre) {
  const format = UserPreferences.date_format();
  const isoDate = _fpa.utils.DateTime.fromFormat(stre, format).toISO();
  return new Date(isoDate);
};

// Take yyyy-mm-dd... and make it mm/dd/yyyy
_fpa.utils.isoDateStringToLocale = function (stre) {
  if (_fpa.utils.is_blank(stre)) return stre;
  const format = UserPreferences.date_format();
  return _fpa.utils.DateTime.fromISO(stre).toFormat(format);
};

// Take yyyy-mm-dd hh24:min:ss... and make it mm/dd/yyyy hh24:min:ss or dd/mm/yyyy hh24:min:ss
_fpa.utils.isoDateTimeStringToLocale = function (stre) {
  stre = stre.trim();
  if (_fpa.utils.is_blank(stre)) return stre;
  const format = UserPreferences.date_time_format();
  return _fpa.utils.DateTime.fromSQL(stre, { zone: UserPreferences.timezone() }).toFormat(format);
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
  if (stre === null || stre === '') return '';
  let startTime;
  let asTimestamp;
  if (stre && stre.length >= 8) {
    if (stre.match(/^\d\d\d\d-\d\d-\d\d(?:t|T)\d\d:\d\d:\d\d(?:\.\d+)?/)) {
      startTime = _fpa.utils.DateTime.fromISO(stre);
      asTimestamp = !stre.match(/(?:t|T)00:00:00(?:\.0+)?(?:z|Z)/);
    } else if (stre.match(/^\d\d\d\d-\d\d-\d\d.*/)) {
      startTime = _fpa.utils.DateTime.fromSQL(stre);
      asTimestamp = !stre.match(/^\d\d\d\d-\d\d-\d\d 00:00:00(?:\.0+)?/);
    }
  }
  if (typeof startTime === 'undefined' || !(startTime && startTime.isValid)) {
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
      if (stre !== null && !(stre instanceof String) && !(stre instanceof Number) && typeof stre == 'object') {
        if (Object.keys(stre).length > 0) {
          return stre;
        } else {
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
      } else {
        stre = _fpa.utils.nl2br(stre);
        if (options_hash.remove_tags) stre = _fpa.utils.remove_tags(stre);
        return stre;
      }
    } else {
      return null;
    }
  }
  const format = UserPreferences.date_format();
  if (asTimestamp) {
    const timezone = UserPreferences.timezone();
    return startTime.setZone(timezone).toFormat(format);
  } else {
    return startTime.toUTC().toFormat(format);
  }
};

_fpa.utils.calc_field = function (field_name_sym, form_object_item_type_us) {
  var cwdef = _fpa.calculate_with[field_name_sym];

  var target_field = $(
    '[data-attr-name="' + field_name_sym + '"][data-object-name="' + form_object_item_type_us + '"]'
  );

  if (cwdef.sum) {
    for (var i in cwdef.sum) {
      var dfi = cwdef.sum[i];
      $('[data-attr-name="' + dfi + '"][data-object-name="' + form_object_item_type_us + '"]').on(
        'change click keyup',
        function () {
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
        }
      );
    }
  }
};

// Convert HTML to markdown.
// Cleanup the HTML, removing all attributes on every element
// Remove common elements that we don't want in the output
// Ensure every table cell is also converted to pure markdown without HTML
// Keep all links inline
// Pass the html as {html: '<markup>...'} so it can be updated
// The function returns the text markdown
_fpa.utils.html_to_markdown = function (obj) {
  var $html = $('<div>' + obj.html + '</div>');

  $html.find('style').remove();

  $html
    .find('*')
    .not(
      'div, p, h1, h2, h3, h4, i, b, strong, em, u, li, ol, ul, table, tr, td, thead, th, tbody, code, pre, img, a, br, sup, sub'
    )
    .contents()
    .unwrap()
    .wrap('');

  $html.find('*').each(function () {
    // Remove unnecessary newlines
    var newtxt = $(this).html().replace(/\n/g, ' ');
    $(this).html(newtxt);
  });

  $html.find('*').each(function () {
    var attributes = $.map(this.attributes, function (item) {
      return item.name;
    });

    var not_attr = null;
    var $el = $(this);
    var el = $el[0];
    if (el.tagName == 'A') not_attr = ['href', 'title'];
    else if (el.tagName == 'IMG') not_attr = ['src', 'title'];

    // now use jQuery to remove the attributes
    $.each(attributes, function (i, item) {
      if (!not_attr || not_attr.indexOf(item.toLowerCase()) < 0) $el.removeAttr(item);
    });
  });

  $html.find('i,b,em,strong').each(function () {
    const $a = $(this);

    $a.html($a.html().trim()).after($('<span> </span>'));
  });

  $html.find('a').each(function () {
    const $a = $(this);

    const href = $a.attr('href');
    $a.attr('href', href.replace(window.location.origin, ''));
  });

  $html.find('img').each(function () {
    const $img = $(this);

    const src = $img.attr('src');
    $img.attr('src', src.replace(window.location.origin, ''));
  });

  // Add a header to each table if necessary
  $html
    .find('table')
    .each(function () {
      var table = $(this);
      if (table.find('thead').length === 0) {
        var first_row = table.find('tr').first();
        var headers = first_row.find('td');
        var thead_html = $('<thead><tr></tr></thead>');
        var thead_tr = thead_html.find('tr');
        headers.each(function () {
          var th = '<th>' + $(this).html() + '</th>';
          thead_tr.append(th);
        });

        first_row.remove();
        table.prepend(thead_html);
      }
    })
    .addClass('table');

  $html.find('td,th').each(function () {
    $(this).find('p, h1, h2, h3, h4').contents().unwrap().append('<br/>');
  });

  obj.html = $html.html();

  var txt = domador(obj.html, { inline: true, pad_ol_li: 3 });

  // Clean the text to remove
  // any number of hash or asterisk symbols followed by
  // one or more spaces
  // txt = txt.replace(/\]\(/g, ']\\(');
  txt = txt.replace(/(^|\n)(#|\*)+ *\n/g, '');

  return txt;
};

// Beep - but no more than once every 10 seconds to avoid multiple tabs making a racket
_fpa.utils.beep = function () {
  const no_more_than = 10;
  const time_now = (new Date().getTime()) / 1000;

  if ($('body.page-transition').length) return;

  var tlr = window.localStorage.getItem('beep_last_reset');
  if (!tlr)
    tlr = 0;
  else
    tlr = parseInt(tlr);
  const time_diff = time_now - tlr;
  if (time_diff < no_more_than) return;

  window.localStorage.setItem('beep_last_reset', String(time_now));
  const snd = new Audio("data:audio/wav;base64,//uQRAAAAWMSLwUIYAAsYkXgoQwAEaYLWfkWgAI0wWs/ItAAAGDgYtAgAyN+QWaAAihwMWm4G8QQRDiMcCBcH3Cc+CDv/7xA4Tvh9Rz/y8QADBwMWgQAZG/ILNAARQ4GLTcDeIIIhxGOBAuD7hOfBB3/94gcJ3w+o5/5eIAIAAAVwWgQAVQ2ORaIQwEMAJiDg95G4nQL7mQVWI6GwRcfsZAcsKkJvxgxEjzFUgfHoSQ9Qq7KNwqHwuB13MA4a1q/DmBrHgPcmjiGoh//EwC5nGPEmS4RcfkVKOhJf+WOgoxJclFz3kgn//dBA+ya1GhurNn8zb//9NNutNuhz31f////9vt///z+IdAEAAAK4LQIAKobHItEIYCGAExBwe8jcToF9zIKrEdDYIuP2MgOWFSE34wYiR5iqQPj0JIeoVdlG4VD4XA67mAcNa1fhzA1jwHuTRxDUQ//iYBczjHiTJcIuPyKlHQkv/LHQUYkuSi57yQT//uggfZNajQ3Vmz+Zt//+mm3Wm3Q576v////+32///5/EOgAAADVghQAAAAA//uQZAUAB1WI0PZugAAAAAoQwAAAEk3nRd2qAAAAACiDgAAAAAAABCqEEQRLCgwpBGMlJkIz8jKhGvj4k6jzRnqasNKIeoh5gI7BJaC1A1AoNBjJgbyApVS4IDlZgDU5WUAxEKDNmmALHzZp0Fkz1FMTmGFl1FMEyodIavcCAUHDWrKAIA4aa2oCgILEBupZgHvAhEBcZ6joQBxS76AgccrFlczBvKLC0QI2cBoCFvfTDAo7eoOQInqDPBtvrDEZBNYN5xwNwxQRfw8ZQ5wQVLvO8OYU+mHvFLlDh05Mdg7BT6YrRPpCBznMB2r//xKJjyyOh+cImr2/4doscwD6neZjuZR4AgAABYAAAABy1xcdQtxYBYYZdifkUDgzzXaXn98Z0oi9ILU5mBjFANmRwlVJ3/6jYDAmxaiDG3/6xjQQCCKkRb/6kg/wW+kSJ5//rLobkLSiKmqP/0ikJuDaSaSf/6JiLYLEYnW/+kXg1WRVJL/9EmQ1YZIsv/6Qzwy5qk7/+tEU0nkls3/zIUMPKNX/6yZLf+kFgAfgGyLFAUwY//uQZAUABcd5UiNPVXAAAApAAAAAE0VZQKw9ISAAACgAAAAAVQIygIElVrFkBS+Jhi+EAuu+lKAkYUEIsmEAEoMeDmCETMvfSHTGkF5RWH7kz/ESHWPAq/kcCRhqBtMdokPdM7vil7RG98A2sc7zO6ZvTdM7pmOUAZTnJW+NXxqmd41dqJ6mLTXxrPpnV8avaIf5SvL7pndPvPpndJR9Kuu8fePvuiuhorgWjp7Mf/PRjxcFCPDkW31srioCExivv9lcwKEaHsf/7ow2Fl1T/9RkXgEhYElAoCLFtMArxwivDJJ+bR1HTKJdlEoTELCIqgEwVGSQ+hIm0NbK8WXcTEI0UPoa2NbG4y2K00JEWbZavJXkYaqo9CRHS55FcZTjKEk3NKoCYUnSQ0rWxrZbFKbKIhOKPZe1cJKzZSaQrIyULHDZmV5K4xySsDRKWOruanGtjLJXFEmwaIbDLX0hIPBUQPVFVkQkDoUNfSoDgQGKPekoxeGzA4DUvnn4bxzcZrtJyipKfPNy5w+9lnXwgqsiyHNeSVpemw4bWb9psYeq//uQZBoABQt4yMVxYAIAAAkQoAAAHvYpL5m6AAgAACXDAAAAD59jblTirQe9upFsmZbpMudy7Lz1X1DYsxOOSWpfPqNX2WqktK0DMvuGwlbNj44TleLPQ+Gsfb+GOWOKJoIrWb3cIMeeON6lz2umTqMXV8Mj30yWPpjoSa9ujK8SyeJP5y5mOW1D6hvLepeveEAEDo0mgCRClOEgANv3B9a6fikgUSu/DmAMATrGx7nng5p5iimPNZsfQLYB2sDLIkzRKZOHGAaUyDcpFBSLG9MCQALgAIgQs2YunOszLSAyQYPVC2YdGGeHD2dTdJk1pAHGAWDjnkcLKFymS3RQZTInzySoBwMG0QueC3gMsCEYxUqlrcxK6k1LQQcsmyYeQPdC2YfuGPASCBkcVMQQqpVJshui1tkXQJQV0OXGAZMXSOEEBRirXbVRQW7ugq7IM7rPWSZyDlM3IuNEkxzCOJ0ny2ThNkyRai1b6ev//3dzNGzNb//4uAvHT5sURcZCFcuKLhOFs8mLAAEAt4UWAAIABAAAAAB4qbHo0tIjVkUU//uQZAwABfSFz3ZqQAAAAAngwAAAE1HjMp2qAAAAACZDgAAAD5UkTE1UgZEUExqYynN1qZvqIOREEFmBcJQkwdxiFtw0qEOkGYfRDifBui9MQg4QAHAqWtAWHoCxu1Yf4VfWLPIM2mHDFsbQEVGwyqQoQcwnfHeIkNt9YnkiaS1oizycqJrx4KOQjahZxWbcZgztj2c49nKmkId44S71j0c8eV9yDK6uPRzx5X18eDvjvQ6yKo9ZSS6l//8elePK/Lf//IInrOF/FvDoADYAGBMGb7FtErm5MXMlmPAJQVgWta7Zx2go+8xJ0UiCb8LHHdftWyLJE0QIAIsI+UbXu67dZMjmgDGCGl1H+vpF4NSDckSIkk7Vd+sxEhBQMRU8j/12UIRhzSaUdQ+rQU5kGeFxm+hb1oh6pWWmv3uvmReDl0UnvtapVaIzo1jZbf/pD6ElLqSX+rUmOQNpJFa/r+sa4e/pBlAABoAAAAA3CUgShLdGIxsY7AUABPRrgCABdDuQ5GC7DqPQCgbbJUAoRSUj+NIEig0YfyWUho1VBBBA//uQZB4ABZx5zfMakeAAAAmwAAAAF5F3P0w9GtAAACfAAAAAwLhMDmAYWMgVEG1U0FIGCBgXBXAtfMH10000EEEEEECUBYln03TTTdNBDZopopYvrTTdNa325mImNg3TTPV9q3pmY0xoO6bv3r00y+IDGid/9aaaZTGMuj9mpu9Mpio1dXrr5HERTZSmqU36A3CumzN/9Robv/Xx4v9ijkSRSNLQhAWumap82WRSBUqXStV/YcS+XVLnSS+WLDroqArFkMEsAS+eWmrUzrO0oEmE40RlMZ5+ODIkAyKAGUwZ3mVKmcamcJnMW26MRPgUw6j+LkhyHGVGYjSUUKNpuJUQoOIAyDvEyG8S5yfK6dhZc0Tx1KI/gviKL6qvvFs1+bWtaz58uUNnryq6kt5RzOCkPWlVqVX2a/EEBUdU1KrXLf40GoiiFXK///qpoiDXrOgqDR38JB0bw7SoL+ZB9o1RCkQjQ2CBYZKd/+VJxZRRZlqSkKiws0WFxUyCwsKiMy7hUVFhIaCrNQsKkTIsLivwKKigsj8XYlwt/WKi2N4d//uQRCSAAjURNIHpMZBGYiaQPSYyAAABLAAAAAAAACWAAAAApUF/Mg+0aohSIRobBAsMlO//Kk4soosy1JSFRYWaLC4qZBYWFRGZdwqKiwkNBVmoWFSJkWFxX4FFRQWR+LsS4W/rFRb/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////VEFHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAU291bmRib3kuZGUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMjAwNGh0dHA6Ly93d3cuc291bmRib3kuZGUAAAAAAAAAACU=");
  snd.play();
}