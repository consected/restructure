// Tracker history panel filtering (issue #1074).
//
// Adds client-side filter behavior for the tracker history chronological
// panel. Supports multi-select filters for protocol, sub process (status)
// and protocol event (method), a date range, plus a free-text notes filter.
// Also handles initial preselection driven by regex patterns supplied in
// `data.initial_filter_regex` and a literal initial notes value supplied in
// `data.initial_filter_notes` from the controller.
//
// Filters are combined with AND across groups and OR within each group.
// Notes matching is case-insensitive substring matching.
//
// To avoid fighting with `_fpa.form_utils.setup_chosen` (which initializes
// chosen.js on multi-selects during `format_block`), the multi-select option
// lists are populated BEFORE `format_block` runs, and event handlers are
// attached AFTER format_block via event delegation on the table itself so
// they survive chosen's DOM rearrangements.

_fpa.tracker_history_filter = (function () {
  var FILTER_KEYS = ['protocols', 'sub_processes', 'protocol_events'];

  // Map filter group key -> data attribute name on each row
  var ROW_ATTR_FOR_KEY = {
    protocols: 'data-protocol-name',
    sub_processes: 'data-sub-process-name',
    protocol_events: 'data-event-name'
  };

  // Default name of the system-generated protocol used for record-update
  // tracker entries (Classification::Protocol::RecordUpdatesProtocolName).
  // Sub-processes and protocol events under this protocol clutter the filter
  // dropdowns, so we omit them from the option lists. The authoritative value
  // is supplied by the controller as `data.record_updates_protocol_name`;
  // this constant is only a fallback if the payload is missing the key.
  var DEFAULT_RECORD_UPDATES_PROTOCOL_NAME = 'Updates';

  function safe_regex(pattern) {
    try {
      return new RegExp(pattern);
    } catch (e) {
      if (window.console && console.warn) {
        console.warn('tracker history initial filters: invalid regex ' +
          JSON.stringify(pattern) + ' - ' + e.message);
      }
      return null;
    }
  }

  function unique_values($rows, attr) {
    var seen = {};
    var values = [];
    $rows.each(function () {
      var v = $(this).attr(attr);
      if (v && !seen[v]) {
        seen[v] = true;
        values.push(v);
      }
    });
    values.sort(function (a, b) { return a.localeCompare(b); });
    return values;
  }

  function populate_select($select, values, preselected) {
    $select.empty();
    var selectedSet = {};
    (preselected || []).forEach(function (v) { selectedSet[v] = true; });
    values.forEach(function (v) {
      var $opt = $('<option>').attr('value', v).text(v);
      if (selectedSet[v]) $opt.attr('selected', 'selected');
      $select.append($opt);
    });
  }

  function compute_initial_selection(values, pattern) {
    var rx = safe_regex(pattern);
    if (!rx) return [];
    return values.filter(function (v) { return rx.test(v); });
  }

  // Parse a date/timestamp string and return YYYY-MM-DD (or null if unparseable).
  // Accepts ISO-style strings as well as the user's locale date format
  // (e.g. dd/mm/yyyy or mm/dd/yyyy), which the framework's
  // `setup_datepickers` writes back into the input.
  function date_part(value) {
    if (!value) return null;
    var s = String(value).trim();
    if (!s) return null;
    var m = s.match(/^(\d{4}-\d{2}-\d{2})/);
    if (m) return m[1];
    // Use the framework helper that respects user date format preference.
    if (_fpa.form_utils && _fpa.form_utils.locale_date_to_iso) {
      try {
        var iso = _fpa.form_utils.locale_date_to_iso(s);
        if (iso && /^\d{4}-\d{2}-\d{2}/.test(iso)) return iso.substr(0, 10);
      } catch (e) {
        // fall through to fallback parser below
      }
    }
    var d = new Date(s);
    if (isNaN(d.getTime())) return null;
    var pad = function (n) { return n < 10 ? '0' + n : '' + n; };
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
  }

  function apply_filters($container) {
    var $rows = $container.find('tbody.tracker-history-rows tr.tracker-history-row');
    var selections = {};
    FILTER_KEYS.forEach(function (key) {
      var $sel = $container.find('select.tracker-history-filter[data-filter-key="' + key + '"]');
      var v = $sel.val();
      selections[key] = v && v.length ? v : null;
    });
    var notesText = ($container.find('input.tracker-history-filter-notes').val() || '')
      .toLowerCase();
    var dateFrom = ($container.find('input.tracker-history-filter-date-from').val() || '');
    var dateTo = ($container.find('input.tracker-history-filter-date-to').val() || '');
    // The framework's setup_datepickers reformats the underlying input value
    // to the user's locale (e.g. "02/01/2025"); normalize back to YYYY-MM-DD
    // so we can compare against the row's `data-event-date` attribute.
    dateFrom = date_part(dateFrom) || '';
    dateTo = date_part(dateTo) || '';

    $rows.each(function () {
      var $row = $(this);
      var visible = true;

      for (var i = 0; i < FILTER_KEYS.length && visible; i++) {
        var key = FILTER_KEYS[i];
        var sel = selections[key];
        if (!sel) continue;
        var rowVal = $row.attr(ROW_ATTR_FOR_KEY[key]) || '';
        if (sel.indexOf(rowVal) === -1) visible = false;
      }

      if (visible && notesText) {
        var notes = ($row.attr('data-notes') || '').toLowerCase();
        if (notes.indexOf(notesText) === -1) visible = false;
      }

      if (visible && (dateFrom || dateTo)) {
        var rowDate = date_part($row.attr('data-event-date'));
        if (!rowDate) {
          visible = false;
        } else {
          if (dateFrom && rowDate < dateFrom) visible = false;
          if (visible && dateTo && rowDate > dateTo) visible = false;
        }
      }

      $row.toggleClass('tracker-history-row--filtered-out', !visible);
      if (visible) {
        $row.show();
      } else {
        $row.hide();
      }
    });
  }

  function debounce(fn, wait) {
    var timer = null;
    return function () {
      var ctx = this;
      var args = arguments;
      clearTimeout(timer);
      timer = setTimeout(function () { fn.apply(ctx, args); }, wait);
    };
  }

  // Populate options and initial values BEFORE chosen.js attaches via
  // `_fpa.form_utils.setup_chosen` during `format_block`.
  function populate(block, data) {
    var $containers = (block && block.find)
      ? block.find('.tracker-chron-results-wrap')
      : $('.tracker-chron-results-wrap');
    if (!$containers.length) return;

    var initialRegex = (data && data.initial_filter_regex) || {};
    var initialNotes = (data && data.initial_filter_notes) || '';
    var initialDateFrom = (data && data.initial_filter_date_from) || '';
    var initialDateTo = (data && data.initial_filter_date_to) || '';
    var recordUpdatesProtocolName =
      (data && data.record_updates_protocol_name) || DEFAULT_RECORD_UPDATES_PROTOCOL_NAME;

    $containers.each(function () {
      var $container = $(this);
      var $rows = $container.find('tbody.tracker-history-rows tr.tracker-history-row');

      FILTER_KEYS.forEach(function (key) {
        var $sel = $container.find('select.tracker-history-filter[data-filter-key="' + key + '"]');
        if (!$sel.length) return;
        // For the protocol_events list, omit events that belong to the
        // record-updates protocol since they only clutter the dropdown.
        var $sourceRows = (key === 'protocol_events')
          ? $rows.not('[data-protocol-name="' + recordUpdatesProtocolName + '"]')
          : $rows;
        var values = unique_values($sourceRows, ROW_ATTR_FOR_KEY[key]);
        var pattern = initialRegex[key];
        var preselected = pattern ? compute_initial_selection(values, pattern) : [];
        populate_select($sel, values, preselected);
      });

      $container.find('input.tracker-history-filter-notes').val(initialNotes);
      $container.find('input.tracker-history-filter-date-from').val(initialDateFrom);
      $container.find('input.tracker-history-filter-date-to').val(initialDateTo);
    });
  }

  // Attach delegated event handlers after format_block has set up chosen.
  function attach(block) {
    var $containers = (block && block.find)
      ? block.find('.tracker-chron-results-wrap')
      : $('.tracker-chron-results-wrap');
    if (!$containers.length) return;

    $containers.each(function () {
      var $container = $(this);
      if ($container.data('thfAttached')) {
        apply_filters($container);
        return;
      }
      $container.data('thfAttached', true);

      $container.on('change.thf', 'select.tracker-history-filter', function () {
        apply_filters($container);
      });

      var debouncedApply = debounce(function () { apply_filters($container); }, 500);
      $container.on('input.thf', 'input.tracker-history-filter-notes', function () {
        debouncedApply();
      });
      $container.on('keydown.thf', 'input.tracker-history-filter-notes', function (ev) {
        if (ev.which === 13) {
          ev.preventDefault();
          apply_filters($container);
        }
      });

      $container.on('change.thf input.thf changeDate.thf blur.thf', 'input.tracker-history-filter-date-from, input.tracker-history-filter-date-to', function () {
        apply_filters($container);
      });

      $container.on('click.thf', 'a.tracker-history-filters__clear', function (ev) {
        ev.preventDefault();
        ev.stopPropagation();
        $container.find('select.tracker-history-filter')
          .val(null)
          .trigger('chosen:updated')
          .trigger('change');
        $container.find('input.tracker-history-filter-notes').val('');
        $container.find('input.tracker-history-filter-date-from').val('');
        $container.find('input.tracker-history-filter-date-to').val('');
        apply_filters($container);
        return false;
      });

      apply_filters($container);
    });

    // After format_block has scheduled chosen() via setTimeout, trigger
    // chosen:updated so chosen rebuilds its result list from the options
    // we populated. This handles ordering races where chosen attaches
    // before reading the populated <option> elements.
    setTimeout(function () {
      $containers.each(function () {
        $(this).find('select.tracker-history-filter').trigger('chosen:updated');
      });
    }, 50);
  }

  return {
    populate: populate,
    attach: attach,
    apply_filters: apply_filters,
    _safe_regex: safe_regex,
    _compute_initial_selection: compute_initial_selection,
    _date_part: date_part
  };
})();
