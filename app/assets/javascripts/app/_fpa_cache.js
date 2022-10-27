
_fpa.cache_class = class {

  constructor(options) {
    options = options || {};
    this.cache_debug = options.cache_debug;

    this.requested_cache_items = [];
    this.requests_in_progress = {};
    this.overflow_local_storage = {};

  }

  fetch(name) {
    const cname = this.cache_name(name);
    let res = localStorage.getItem(cname) || this.overflow_local_storage[cname];
    if (typeof res === 'undefined' || res == null) {
      res = null
    }
    else {
      res = JSON.parse(res);
    }
    this.log(`Got ${cname} from cache: ${!!res}`)
    return res;
  };


  store(name, val) {
    const key = this.cache_name(name);
    const basename = `${name}--`;

    // Force removal of previous versions of the cached item.
    // This must be done synchronously, otherwise the item downloaded in a moment is also removed
    for (let i in localStorage) {
      if (localStorage.hasOwnProperty(i)) {
        if (i.indexOf(basename) === 0) {
          localStorage.removeItem(i);
          this.log(`removed cache item: ${i}`);
        }
      }
    };


    const val_json = JSON.stringify(val);
    const val_length = val_json.length;
    if (val_length > 100000) {
      this.log(`Failed to set the cache for ${key} with value length ${val_length}.`)
      this.overflow_local_storage[key] = val_json;
    }
    else {
      try {
        localStorage.setItem(key, val_json);
      } catch (err) {
        console.log(`Failed to set the cache for ${key} with value length ${val_length}. Exception: ${err.message}`)
        this.overflow_local_storage[key] = val_json
      }
    }

    this.log(`storing cache item: ${key}`);

  };


  clean() {
    if (!_fpa.version)
      return;

    for (let i in localStorage) {
      if (localStorage.hasOwnProperty(i)) {
        if (i.indexOf(_fpa.version) < 0 && (i.indexOf('general_selections-') == 0 || i.indexOf('multiple-defs-') == 0)) {
          localStorage.removeItem(i);
          this.log(`cleaned old cache item: ${i}`);
        }
      }
    }
  }

  // Get a single definition
  get_definition(name, callback) {
    try {
      if (this.request_in_progress(this.get_definition.bind(this), name, name, callback)) return;

      const res = this.fetch(name);
      if (!res)
        this.request_definition(name, callback);
      else {
        this.request_complete(name);
        if (callback) callback();
      }
    }
    catch (e) {
      console.log(`Failed to get_definition ${name}. Exception: ${e.message}`)
      this.request_definition(name, callback);
    }
  };

  // Cache multiple definitions in a single request
  get_definitions(names, callback) {
    const _this = this;
    const get_names = this.array_new_items(names, this.requested_cache_items);
    this.array_add_items(get_names, this.requested_cache_items);

    const str_names = get_names.join(",");

    try {
      if (this.request_in_progress(this.get_definitions.bind(this), str_names, get_names, callback)) return;

      // Cache an item named with all the names to act as an indicator for whether this has been done already
      const res = this.fetch(this.cache_name_defs(str_names));
      if (!res) {
        this.request_definitions(get_names, str_names, callback);
      }
      else {
        this.request_complete(str_names);
        if (callback) callback();
      }
    }
    catch (e) {
      console.log(`Failed to get_definitions ${names}. Exception: ${e.message}`)
      this.request_definitions(get_names, str_names, callback);
    }

  };

  cache_name(name) {
    if (typeof (name) !== 'string') {
      throw (`cache_name has name that is not a string: ${name}`);
    }

    return `${name}--${_fpa.version}`;
  };

  request_definition(name, callback) {
    const _this = this;
    this.log(`Getting definition: ${name}`);

    $.ajax(`/definitions/${name}`, {
      success: function (data) {
        _this.store(name, data);
        if (callback) callback();
        _this.request_complete(name);
      },
      error: function () {
        _this.request_complete(name);
      }
    });

  };


  request_definitions(names, str_names, callback) {
    const _this = this;
    this.log(`Getting definitions: ${str_names}`);

    $.ajax('/definitions', {
      method: 'post',
      data: {
        names: str_names
      },
      success: function (data) {

        for (let i in names) {
          const name = names[i];
          const res = data[name];
          _this.store(name, res);

          if (callback) callback();
        }

        _this.store(_this.cache_name_defs(str_names), 'true');
        _this.request_complete(str_names);
      },
      error: function () {
        _this.request_complete(str_names);
      }
    });

  };

  request_in_progress(fn, req_name, names, callback) {
    const in_prog_at = this.requests_in_progress[req_name];
    const curr_ts = new Date;
    // If we have marked the definition request as being in progress elsewhere,
    // and it was less than 5s ago, then we'll wait for the request to complete before trying
    // to get it again
    if (in_prog_at) {
      const ev_ago = curr_ts - in_prog_at;
      if (ev_ago < 5000) {
        // Requested item is already in progress. Wait for a bit to see if it comes back.
        window.setTimeout(function () {
          fn(names, callback);
        }, 1000);
        this.log(`cache request in progress: ${req_name} - ${ev_ago}ms`)

        return true;
      }
      else {
        this.log(`cache request timeout: ${req_name} - ${ev_ago}ms`)
      }
    }

    // Set the marker to show the definition request is in progress
    this.log(`no cache request in progress: ${req_name} - ${in_prog_at}`)
    this.requests_in_progress[req_name] = curr_ts;
  }

  cache_name_defs(str_names) {
    return "multiple-defs-" + str_names;
  }

  request_complete(name) {
    this.requests_in_progress[name] = null;
  }

  log(msg) {
    if (this.cache_debug) console.log(msg);
  }

  // Returns array of items in_array that are not_in array
  array_new_items(in_array, not_in) {
    let result = [];
    for (let i = 0; i < in_array.length; i++) {
      if (not_in.indexOf(in_array[i]) === -1) {
        result.push(in_array[i]);
      }
    }
    return result;
  }

  // Add all items from_array to_array
  array_add_items(from_array, to_array) {
    for (let i = 0; i < from_array.length; i++) {
      to_array.push(from_array[i]);
    }
  }
}

// Set up the cache
_fpa.cache = new _fpa.cache_class({ cache_debug: false })