class ReportSearchAttrs {

  constructor() {
    this.items_hash = {}
  }

  load_items(text) {
    if (!text) return

    this.items_config = jsyaml.load(text)

    Object.entries(this.items_config).forEach(([name, hash]) => {
      this.add_item_hash(name, hash)
    })
  }

  add_item_hash(name, hash) {
    var rsa = new ReportSearchAttr()
    if (hash) rsa.load_from_config(name, hash)
    this.items_hash[name] = rsa
    return rsa
  }

  add_item(name, type, options) {
    options = options || {}


    if (!options.allow_replace) {
      if (this.items_hash[name]) throw `report search attribute definition already exists: ${name}`
    }

    var rsa = new ReportSearchAttr()
    rsa.new_item(name, type)
    this.items_hash[name] = rsa
    return rsa
  }

  get items() {
    return Object.values(this.items_hash)
  }

  get yaml() {
    var text = this.items.map(item => item.yaml).join("\n")
    return text
  }
}

class ReportSearchAttr {
  constructor() {
    this.hash = {}
    this.def_block = null
  }

  load_from_config(name, hash) {
    var first_key = Object.keys(hash)[0]
    this.new_item(name, first_key)
    Object.entries(hash[first_key]).forEach(([key, config_hash]) => {
      this[key] = config_hash
    })
  }

  load_value_hash(val) {
    if (!val) return
    return jsyaml.load(val)
  }

  load_value_list(val) {
    if (!val) return
    return val.split("\n")
  }

  new_item(name, type) {
    this.name = name
    this.type = type
    this.hash[name] = {}
    this.def_block = this.hash[name][type] = {}
  };

  set label(val) {
    if (!val) return

    this.def_block.label = val
  }

  get label() {
    return this.def_block.label
  }

  set multiple(val) {
    if (!val) return

    this.def_block.multiple = val
  }

  get multiple() {
    return this.def_block.multiple
  }

  set hidden(val) {
    if (!val) return

    this.def_block.hidden = val
  }

  get hidden() {
    return this.def_block.hidden
  }

  set filter(val) {
    if (!val) return

    if (val === 'all' || val.all == true) {
      this.all = true
      return
    }

    val = this.load_value_hash(val)
    this.item_type = val.item_type;
  }

  get filter() {
    return this.filter_def
  }

  set item_type(val) {
    if (!val) return

    this.filter_def = `item_type: ${val}`
    this.def_block.item_type = val
  }

  set all(val) {
    if (!val) return

    this.filter_def = 'all'
    this.def_block.all = val
  }

  set selections(val) {
    if (!val) return

    this.def_block.selections = val
  }

  get selections() {
    return this.def_block.selections
  }

  set conditions(val) {
    if (!val) return

    this.def_block.conditions = val
  }

  get conditions() {
    return this.def_block.conditions
  }

  set default(val) {
    if (!val) return

    if (this.def_block.multiple === 'single') this.def_block.default = val[0];
    else this.def_block.default = val
  }

  get default() {
    return this.def_block.default
  }

  // Allow the disabled flag to be set unless defaults are specified
  set disabled(val) {
    if (this.def_block.default) return

    if (val) this.def_block.disabled, false
  }

  get disabled() {
    return this.def_block.disabled
  }

  get no_disabled() {
    return !this.def_block.disabled
  }

  get yaml() {
    return jsyaml.dump(this.hash)
  }

}

_fpa.postprocessors_report_admin = {

  setup_search_attrs: function (block) {
    _fpa.postprocessors_report_admin.setup_search_attrs_type(block);
  },

  //
  // Handle the search attribute type selection being changed,
  // to show the appropriate entry fields
  setup_search_attrs_type: function (block) {
    var ra_config_selections = $('#search_attrs_config_selections')[0].CodeMirror;
    var ra_conditions = $('#search_attrs_conditions')[0].CodeMirror;
    $('#search_attrs_type').change(function () {
      var search_attr_type = $(this).val();

      $('#search_attrs_filter').val('all');

      if (search_attr_type == 'config_selector') {
        $('.report-attr-config-selections').collapse('show');
      }
      else {
        $('.report-attr-config-selections').collapse('hide');
        if (ra_config_selections) ra_config_selections.setValue('');
      }

      if (['accuracy_score', 'general_selection', 'protocol', 'sub_process', 'protocol_event', 'item_flag_name', 'user'].indexOf(search_attr_type) >= 0) {
        $('.report-attr-conditions').collapse('show');
      }
      else {
        $('.report-attr-conditions').collapse('hide');
        if (ra_conditions) ra_conditions.setValue('');
      }


      var not_gs = (search_attr_type !== 'general_selection' ? 'hide' : 'show');
      $('.report-attr-checks').collapse(not_gs);
    });

  },

  load_items: function (block) {
    var $attel = $('#report_search_attrs')
    var rsas = new ReportSearchAttrs()
    rsas.load_items($attel.val())
    return rsas
  },

  //
  // Handle the search attribute item being selected
  setup_search_attrs_sel_item: function (block) {
    var $item_list = block.find('#search_attr_item_list').first()


    $item_list.not('.click-handler-setup').on('click', 'li', function () {
      var name = $(this).html()
      console.log(name)
      $("a.collapsed[href='#report-admin-search-attr-add-block']").click()
      var rsas = _fpa.postprocessors_report_admin.load_items(block)
      var rsa = rsas.items_hash[name]

      $('#search_attr_insert_name').html(":" + name);

      block.find("[data-attr-el]").each(function () {
        var $this = $(this)
        var el = $this.attr('data-attr-el')
        var val = rsa[el]
        var cm = $this[0].CodeMirror
        if (!val) null
        else if (val.join) val = val.join("\n")
        else if (typeof val === 'object') val = jsyaml.dump(val)
        if (cm) {
          val = val || ''
          cm.setValue(val)
          cm.refresh()
        }
        $this.val(val).change()
      })
      $.scrollTo('#search_attr_definer');

    }).addClass('click-handler-setup')

  },

  //
  // Handle the search attribute Add button being clicked,
  // processing the entry fields and formulating the appropriate YAML config
  setup_search_attrs_add: function (block) {
    $('#search_attrs_add').click(function (ev) {
      ev.preventDefault();

      var $attel = $('#report_search_attrs');
      var ra_config_selections = $('#search_attrs_config_selections')[0].CodeMirror;
      var ra_conditions = $('#search_attrs_conditions')[0].CodeMirror;
      var name = $('#search_attrs_name').val();
      var type = $('#search_attrs_type').val();

      if (!name || !type) {
        $.scrollTo('#search_attr_definer');
        $('#search_attrs_name').fadeOut().fadeIn();
        return;
      }

      name = name.underscore();
      var filter = $('#search_attrs_filter').val();
      var no_disabled = $('#search_no_disabled').is(':checked');
      var hidden_field = $('#search_hidden_field').is(':checked');
      var multi = $('#search_attrs_multi').val();
      var label = $('#search_attrs_label').val();
      var defval = $('#search_attrs_default').val();
      var selections_yaml = ra_config_selections && ra_config_selections.getValue();
      var conditions_yaml = ra_conditions && ra_conditions.getValue();

      $('#search_attr_instruction').removeClass('hidden');
      $('#search_attr_insert_name').html(":" + name);

      var rsas = _fpa.postprocessors_report_admin.load_items(block)
      // Set up the YAML
      var rsa = rsas.add_item(name, type, { allow_replace: true })
      rsa.label = label
      rsa.multiple = multi
      rsa.hidden = hidden_field
      rsa.selections = rsa.load_value_hash(selections_yaml)
      rsa.conditions = rsa.load_value_hash(conditions_yaml)
      rsa.filter = filter
      rsa.default = rsa.load_value_list(defval)
      rsa.disabled = no_disabled

      // Update the YAML editor 
      var attel = $attel[0];
      attel.CodeMirror.save();
      var v = rsas.yaml
      $attel.val(v);
      attel.CodeMirror.setValue($attel.val());
      attel.CodeMirror.refresh();

      _fpa.postprocessors_report_admin.setup_search_attr_list(block);
      $("a[href='#report-admin-search-attr-add-block']").click()

    });
  },

  setup_search_attr_list: function (block) {
    var $item_list = block.find('#search_attr_item_list');
    var rsas = _fpa.postprocessors_report_admin.load_items(block)
    $item_list.html('');
    Object.values(rsas.items).forEach((item) => {
      var li = `<li>${item.name}</li>`
      $item_list.append(li)
    });

  },

  handle_admin_report_config: function (block) {

    _fpa.form_utils.setup_textarea_editor(block)

    $('.report-attr-checks').collapse('hide');
    $('#search_no_disabled').val('1').attr('checked', true);

    // Make sure the YAML field loads
    $('#search_attr_definer_config').on('shown.bs.collapse', function () {
      $('#search_attr_definer_config .code-editor')[0].CodeMirror.refresh()
    })

    // Prevent Enter submitting full report form
    $('#search_attr_definer_form').on("keydown", ":input:not(textarea)", function (event) {
      return event.key != "Enter";
    });

    // Clean form on opening
    $('a[href="#report-admin-search-attr-add-block"]').on('click', function () {
      $('#search_attr_definer_form').find(':input').val(null)
    })

    _fpa.postprocessors_report_admin.setup_search_attrs_type(block);
    _fpa.postprocessors_report_admin.setup_search_attrs_add(block);
    _fpa.postprocessors_report_admin.setup_search_attr_list(block);
    _fpa.postprocessors_report_admin.setup_search_attrs_sel_item(block);
  }
};
$.extend(_fpa.postprocessors, _fpa.postprocessors_report_admin);
