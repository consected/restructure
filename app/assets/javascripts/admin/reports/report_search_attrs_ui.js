// Handle templates for the report admin page.
// Relies on ReportSearchAttr(s) classes for
// report criteria field configuration parsing and dumping to YAML.

class ReportSearchAttrsUi {
  constructor(block) {
    this.block = block;
  }

  static setup_search_attrs(block) {
    var rsau = new ReportSearchAttrsUi(block);
    rsau.setup_search_attr_form();
    rsau.setup_search_attrs_type();
    rsau.setup_search_attrs_add();
    rsau.setup_search_attr_list();
    rsau.setup_search_attrs_sel_item();
  }

  get ra_config_selections() {
    var $sacs = $('#search_attrs_config_selections')[0];
    return $sacs && $sacs.CodeMirror;
  }

  get ra_conditions() {
    var $sac = $('#search_attrs_conditions')[0];
    return $sac && $sac.CodeMirror;
  }

  // Load the current YAML configuration into a usable representation
  load_items() {
    var $attel = $('#report_search_attrs');
    var rsas = new ReportSearchAttrs();
    rsas.load_items($attel.val());
    return rsas;
  }

  // Handle the search attribute type selection being changed,
  // to show the appropriate entry fields
  setup_search_attrs_type() {
    var _this = this;

    $('#search_attrs_type').change(function () {
      var search_attr_type = $(this).val();

      $('#search_attrs_filter').val('all');

      if (search_attr_type == 'config_selector') {
        $('.report-attr-config-selections').collapse('show');
        $('.report-attr-select-from-model').collapse('hide');
        $('.report-attr-defined-selector').collapse('hide');
        $('.config-selector-help.for-config_selector').collapse('show');
        $('.config-selector-help.for-select_from_model').collapse('hide');
        if (_this.ra_resource_name) _this.ra_resource_name.val('');
      } else if (search_attr_type == 'select_from_model') {
        $('.report-attr-config-selections').collapse('show');
        $('.report-attr-select-from-model').collapse('show');
        $('.report-attr-defined-selector').collapse('hide');
        $('.config-selector-help.for-config_selector').collapse('hide');
        $('.config-selector-help.for-select_from_model').collapse('show');
      } else if (search_attr_type == 'defined_selector') {
        $('.report-attr-config-selections').collapse('hide');
        $('.report-attr-defined-selector').collapse('show');
        $('.report-attr-select-from-model').collapse('hide');
        $('.config-selector-help.for-config_selector').collapse('hide');
        $('.config-selector-help.for-select_from_model').collapse('show');
      } else {
        $('.report-attr-config-selections').collapse('hide');
        $('.report-attr-select-from-model').collapse('hide');
        $('.report-attr-defined-selector').collapse('hide');
        $('.config-selector-help.for-config_selector').collapse('hide');
        $('.config-selector-help.for-select_from_model').collapse('hide');
        if (_this.ra_config_selections) _this.ra_config_selections.setValue('');
        if (_this.ra_resource_name) _this.ra_resource_name.val('');
      }

      if (
        [
          'accuracy_score',
          'general_selection',
          'protocol',
          'sub_process',
          'protocol_event',
          'item_flag_name',
          'user',
        ].indexOf(search_attr_type) >= 0
      ) {
        $('.report-attr-conditions').collapse('show');
      } else {
        $('.report-attr-conditions').collapse('hide');
        if (_this.ra_conditions) _this.ra_conditions.setValue('');
      }

      var not_gs = search_attr_type !== 'general_selection' ? 'hide' : 'show';
      $('.report-attr-checks').collapse(not_gs);
    });
  }

  //
  // Handle the search attribute item being selected in the list
  setup_search_attrs_sel_item() {
    var $item_list = this.block.find('#search_attr_item_list').first();
    var _this = this;

    $item_list
      .not('.click-handler-setup')
      .on('click', 'li', function () {
        var name = $(this).html();
        console.log(name);
        $("a.collapsed[href='#report-admin-search-attr-add-block']").click();
        var rsas = _this.load_items();
        var rsa = rsas.items_hash[name];

        $('#search_attr_insert_name').html(':' + name);

        _this.block.find('[data-attr-el]').each(function () {
          var $this = $(this);
          var el = $this.attr('data-attr-el');
          var val = rsa[el];
          var cm = $this[0].CodeMirror;
          if (!val) null;
          else if (val.join) val = val.join('\n');
          else if (typeof val === 'object') val = jsyaml.dump(val);
          if (cm) {
            val = val || '';
            cm.setValue(val);
            cm.refresh();
          }
          $this.val(val).change();
        });
        $.scrollTo('#search_attr_definer');
      })
      .addClass('click-handler-setup');
  }

  //
  // Handle the search attribute Add button being clicked,
  // processing the entry fields and formulating the appropriate YAML config using
  // the class ReportSearchAttrs
  setup_search_attrs_add() {
    var _this = this;

    $('#search_attrs_add').click(function (ev) {
      ev.preventDefault();

      var $attel = $('#report_search_attrs');
      var name = $('#search_attrs_name').val();
      var type = $('#search_attrs_type').val();

      if (!name || !type) {
        $.scrollTo('#search_attr_definer');
        $('#search_attrs_name').fadeOut().fadeIn();
        return;
      }

      name = name.underscore();
      var filter = $('#search_attrs_filter').val();
      var defined_selector = $('#search_attrs_defined_selector').val();
      var no_disabled = $('#search_no_disabled').is(':checked');
      var hidden_field = $('#search_hidden_field').is(':checked');
      var multi = $('#search_attrs_multi').val();
      var label = $('#search_attrs_label').val();
      var defval = $('#search_attrs_default').val();
      var resource_name = $('#search_attrs_resource_name').val();
      var selections_yaml = _this.ra_config_selections && _this.ra_config_selections.getValue();
      var conditions_yaml = _this.ra_conditions && _this.ra_conditions.getValue();
      var filter_selector = $('#search_filter_selector').val();

      $('#search_attr_instruction').removeClass('hidden');
      $('#search_attr_insert_name').html(':' + name);

      var rsas = _this.load_items(_this.block);
      // Set up the YAML
      var rsa = rsas.add_item(name, type, { allow_replace: true });
      rsa.label = label;
      rsa.multiple = multi;
      rsa.hidden = hidden_field;
      rsa.resource_name = resource_name;
      rsa.selections = rsa.load_value_hash(selections_yaml);
      rsa.conditions = rsa.load_value_hash(conditions_yaml);
      rsa.filter = filter;
      rsa.defined_selector = defined_selector;
      if (multi.indexOf('multiple') >= 0) {
        // If this is a multi selector type field, set the default as a list, split by newlines
        rsa.default = rsa.load_value_list(defval);
      }
      else {
        // If this is a text field, just set the value directly
        rsa.default = defval;
      }
      rsa.disabled = no_disabled;
      rsa.filter_selector = filter_selector;

      // Update the YAML editor
      var yaml = rsas.yaml;
      var attel = $attel[0];
      attel.CodeMirror.save();
      $attel.val(yaml);
      attel.CodeMirror.setValue(yaml);
      attel.CodeMirror.refresh();

      _this.setup_search_attr_list(_this.block);
      $("a[href='#report-admin-search-attr-add-block']").click();
    });
  }

  // Set up the list of the report criteria fields
  setup_search_attr_list() {
    var $item_list = this.block.find('#search_attr_item_list');
    var rsas = this.load_items();
    $item_list.html('');
    Object.values(rsas.items).forEach((item) => {
      var li = `<li>${item.name}</li>`;
      $item_list.append(li);
    });
  }

  // Set up the form fields and initial state
  setup_search_attr_form() {
    $('.report-attr-checks').collapse('hide');
    $('#search_no_disabled').val('1').attr('checked', true);

    // Make sure the YAML field loads
    $('#search_attr_definer_config').on('shown.bs.collapse', function () {
      $('#search_attr_definer_config .code-editor')[0].CodeMirror.refresh();
    });

    // Prevent Enter submitting full report form
    $('#search_attr_definer_form').on('keydown', ':input:not(textarea)', function (event) {
      return event.key != 'Enter';
    });

    // Clean form on opening
    $('a[href="#report-admin-search-attr-add-block"]').on('click', function () {
      $('#search_attr_definer_form').find(':input').val(null);
      $('#search_attr_definer_form')
        .find(':input')
        .each(function () {
          $(this)[0].CodeMirror && $(this)[0].CodeMirror.refresh();
        });
    });
  }
}
