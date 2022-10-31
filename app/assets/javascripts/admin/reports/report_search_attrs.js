// Represent the report search attributes (criteria fields) definitions
// from the admin UI.
// This handles the generation of a usable data structure for the front end
// which parsing and dumping the expected configuration required by the backend.
//
// The configuration is persisted as a YAML representation, which is parsed
// and represented by the Rails OptionConfigs::SearchAttributesConfig class
// which enforces the underlying configuration.
//
// Javascript _fpa.postprocessors_report_admin uses the ReportSearchAttr(s)
// classes defined here, during admin UI handling, to pass actual config forms
// to, for handling persistence and editing.

class ReportSearchAttrs {
  constructor() {
    this.items_hash = {};
  }

  load_items(text) {
    if (!text) return;

    try {
      this.items_config = jsyaml.load(text);
    } catch (err) {
      window.setTimeout(() => {
        _fpa.flash_notice(
          'Error in search attributes configuration YAML. View the attribute configuration to correct it. ' +
          err.message,
          'warning'
        );
      }, 1000);
    }

    if (!this.items_config) return;

    Object.entries(this.items_config).forEach(([name, hash]) => {
      this.add_item_hash(name, hash);
    });
  }

  add_item_hash(name, hash) {
    var rsa = new ReportSearchAttr();
    if (hash) rsa.load_from_config(name, hash);
    this.items_hash[name] = rsa;
    return rsa;
  }

  add_item(name, type, options) {
    options = options || {};

    if (!options.allow_replace) {
      if (this.items_hash[name]) throw `report search attribute definition already exists: ${name}`;
    }

    var rsa = new ReportSearchAttr();
    rsa.new_item(name, type);
    this.items_hash[name] = rsa;
    return rsa;
  }

  get items() {
    return Object.values(this.items_hash);
  }

  get yaml() {
    var text = this.items.map((item) => item.yaml).join('\n');
    return text;
  }
}

class ReportSearchAttr {
  constructor() {
    this.hash = {};
    this.def_block = null;
  }

  load_from_config(name, hash) {
    var first_key = Object.keys(hash)[0];
    this.new_item(name, first_key);
    Object.entries(hash[first_key]).forEach(([key, config_hash]) => {
      this[key] = config_hash;
    });
  }

  load_value_hash(val) {
    if (!val) return;
    try {
      var res = jsyaml.load(val);
    } catch (err) {
      window.setTimeout(() => {
        _fpa.flash_notice(
          'Error in search attributes configuration value YAML. View the configuration fields to correct it. ' +
          err.message,
          'warning'
        );
      }, 1000);
      throw err;
    }

    return res;
  }

  load_value_list(val) {
    if (!val) return;
    return val.split('\n');
  }

  new_item(name, type) {
    this.name = name;
    this.type = type;
    this.hash[name] = {};
    this.def_block = this.hash[name][type] = {};
  }

  set label(val) {
    if (!val) return;

    this.def_block.label = val;
  }

  get label() {
    return this.def_block.label;
  }

  set resource_name(val) {
    if (!val) return;

    this.def_block.resource_name = val;
  }

  get resource_name() {
    return this.def_block.resource_name;
  }

  set multiple(val) {
    if (!val) return;

    this.def_block.multiple = val;
  }

  get multiple() {
    return this.def_block.multiple;
  }

  set hidden(val) {
    if (!val) return;

    this.def_block.hidden = val;
  }

  get hidden() {
    return this.def_block.hidden;
  }

  set filter(val) {
    if (!val) return;

    if (val === 'all' || val.all == true) {
      this.all = true;
      return;
    }

    val = this.load_value_hash(val);
    this.item_type = val.item_type;
  }

  get filter() {
    return this.filter_def;
  }

  set item_type(val) {
    if (!val) return;

    this.filter_def = `item_type: ${val}`;
    this.def_block.item_type = val;
  }

  set all(val) {
    if (!val) return;

    this.filter_def = 'all';
    this.def_block.all = val;
  }

  set selections(val) {
    if (!val) return;

    this.def_block.selections = val;
  }

  get selections() {
    return this.def_block.selections;
  }

  set defined_selector(val) {
    if (!val) return;

    this.def_block.defined_selector = val;
  }

  get defined_selector() {
    return this.def_block.defined_selector;
  }

  set conditions(val) {
    if (!val) return;

    this.def_block.conditions = val;
  }

  get conditions() {
    return this.def_block.conditions;
  }

  set default(val) {
    if (!val) return;

    if (this.def_block.multiple === 'single') this.def_block.default = val[0];
    else this.def_block.default = val;
  }

  get default() {
    return this.def_block.default;
  }

  // Allow the disabled flag to be set unless defaults are specified
  set disabled(val) {
    if (this.def_block.default) return;

    if (val) this.def_block.disabled, false;
  }

  get disabled() {
    return this.def_block.disabled;
  }

  get no_disabled() {
    return !this.def_block.disabled;
  }

  get filter_selector() {
    return this.def_block.filter_selector;
  }

  set filter_selector(val) {
    if (!val) return;

    this.def_block.filter_selector = val;
  }

  get yaml() {
    return jsyaml.dump(this.hash);
  }
}
