// Common setup across all admin types
_fpa_admin.all.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  static setup(block, data) {

    var aef = new _fpa_admin.all.admin_edit_form(block, data)

    aef.item_specific_setup('admin_edit_form')
    aef.admin_edit_form_setup()
    aef.setup_filtered_selects()
    aef.setup_codemirror_editors()
    aef.setup_yaml_help_viewers()
    aef.setup_auto_loading_links()
    aef.setup_big_select_fields()
    _fpa.form_utils.on_open_click(aef.block);
    _fpa.form_utils.setup_drag_and_drop(aef.block);

  }

  item_specific_setup(setup_type) {
    var block = this.block
    var data = this.data
    // If a specific admin_edit_form handler is in place for the controller, call it:
    // For example _fpa.reports.admin_edit_form
    var admin_type = block.parents('.admin-result-index[data-admin-type]').attr('data-admin-type');
    console.log(admin_type)
    if (admin_type && _fpa_admin[admin_type] && _fpa_admin[admin_type][setup_type])
      _fpa_admin[admin_type][setup_type].setup(block, data);

  }


  // Do some initial setup
  admin_edit_form_setup() {
    var block = this.block

    _fpa.utils.scrollTo(block, 200, -50);
    $('tr.new-record').before($('tr.admin-list-item').first());
    $('.saved-row').removeClass('saved-row');
    $('.edit-as-custom-setup').removeClass('edit-as-custom-setup');
    _fpa.form_utils.format_block(block);
    block.find('#admin-edit-cancel').click(function (ev) {
      ev.preventDefault();
      block.html('');
    });

    // Force some initial configuration of textarea blocks
    window.setTimeout(function () {
      var el = $('.admin-edit-form textarea');
      el.click();
    }, 300);

  }

  // Filter select drop downs based on the selection of a previous drop down (typically the App Type)
  // Common functionality across multiple admin types
  setup_filtered_selects() {
    var block = this.block

    block.find('select[data-filters-select]').not('.filters-select-attached').each(function () {
      var $el = $(this);
      var filter_sel_attr = $el.attr('data-filters-select');
      var filter_sels = filter_sel_attr.split(',');
      $el.on('change', function () {
        var val = $el.val();
        for (var i in filter_sels) {
          var filter_sel = filter_sels[i];
          $(filter_sel + ' optgroup[data-group-num]').hide();
          $(filter_sel + ' optgroup[data-group-num="' + val + '"]').show();
        }
      });

      for (var i in filter_sels) {
        var filter_sel = filter_sels[i];

        var val = $el.val();
        $(filter_sel + ' optgroup[label]').each(function () {
          if (!$(this).attr('data-group-num')) {
            var l = $(this).attr('label');
            var ls = l.split('/', 2);
            var last = ls.length - 1;
            var first = 0;
            $(this).attr('label', ls[last]);
            $(this).attr('data-group-num', ls[first]);
          }

        }).hide();
        $(filter_sel + ' optgroup[data-group-num="' + val + '"]').show();
      }
    }).addClass('filters-select-attached');

  }

  setup_codemirror_editors() {
    var block = this.block

    block.find('.code-editor').not('.code-editor-formatted').each(function () {
      var code_el = $(this).get(0);
      var lint;
      var mode = $(this).attr('data-code-editor-type');
      if (!mode) mode = 'yaml';
      // if(mode == 'yaml') {
      //   lint = true;
      //   mode = 'text/x-yaml';
      // }

      var cm = CodeMirror.fromTextArea(code_el, {
        lineNumbers: true,
        mode: mode,
        foldGutter: true,
        lint: lint,
        gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
        extraKeys: {
          Tab: function (cm) { cm.execCommand("indentMore") },
          "Shift-Tab": function (cm) { cm.execCommand("indentLess") }
        }
      });
      var cme = cm.getWrapperElement();
      cme.style.width = '100%';
      cme.style.height = '100%';
      code_el.CodeMirror = cm;
      cm.refresh();
    }).addClass('code-editor-formatted');

  }

  // Help and information viewers that include readonly codemirror blocks for YAML
  // display require some extra setup, and careful refreshing if they are hidden
  // in panels (or other blocks) when they become visible
  setup_yaml_help_viewers() {
    var block = this.block
    var _this = this


    // Setup each viewer
    block.find('.extra-help-info').not('.code-extra-help-info-formatted').each(function () {
      if (!$(this).is(':visible')) return;
      _this.setup_yaml_viewer($(this));
    }).addClass('code-extra-help-info-formatted');


    // When a tab is shown
    $('[data-toggle="tab"]').filter(':visible').on('shown.bs.tab', function () {

      var tar = $($(this).attr('href'));
      if (!tar.is(':visible')) return;

      var ehi = tar.find('.extra-help-info').not('.code-extra-help-info-formatted-in-tab');
      if (ehi.length) {
        CodeMirror.fromTextArea(ehi[0]).refresh();
        ehi.addClass('code-extra-help-info-formatted-in-tab')
      }
    })

    // When a tab collapses
    $('.collapse.has-editor').on('shown.bs.collapse', function () {
      var ehi = $(this).find('.extra-help-info').not('.code-extra-help-info-formatted-in-collapse, .code-extra-help-info-formatted-in-tab').filter(':visible');
      ehi.each(function () {
        _this.setup_yaml_editor($(this));
        ehi.addClass('code-extra-help-info-formatted-in-collapse code-extra-help-info-formatted-in-tab')
      });
    })

  }

  setup_yaml_viewer(container) {

    var code_el = container.get(0);
    var mode = container.attr('data-code-editor-type');
    if (!mode) mode = 'yaml';

    var cm = CodeMirror.fromTextArea(code_el, {
      lineNumbers: true,
      mode: mode,
      readOnly: true,
      foldGutter: true,
      gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
    });

    var cme = cm.getWrapperElement();
    cme.style.width = '100%';
    cme.style.height = '100%';
    cme.style.backgroundColor = 'rgba(255,255,255, 0.2)';
    code_el.CodeMirror = cm;
    cm.refresh();

  }

  setup_yaml_editor(container) {
    var code_el = container.get(0);
    var mode = container.attr('data-code-editor-type');
    if (!mode) mode = 'yaml';

    var cm = CodeMirror.fromTextArea(code_el, {
      lineNumbers: true,
      mode: mode,
      readOnly: false,
      foldGutter: true,
      gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
    });

    var cme = cm.getWrapperElement();
    cme.style.width = '100%';
    cme.style.height = '100%';
    cme.style.backgroundColor = 'rgb(255,255,255)';
    code_el.CodeMirror = cm;
    cm.refresh();

  }


  // Some links are marked with a class *on-show-auto-click*, indicating they are
  // to be triggered automatically when the tab panel becomes visible
  setup_auto_loading_links() {
    var block = this.block

    window.setTimeout(function () {
      // Handle auto opening of links in tab panels
      block.find('[data-toggle="tab"]').on('show.bs.tab', function () {
        $($(this).attr('href')).find('a.on-show-auto-click').not('.auto-clicked').addClass('auto-clicked').click();
      }).addClass('attached-tab-show');

      // Handle auto opening of links in tab panels when the initial panel is already open
      block.find('[data-toggle="tab"][aria-expanded="true"]').not('.attached-tab-init').each(function () {
        $($(this).attr('href')).find('a.on-show-auto-click').not('.auto-clicked').addClass('auto-clicked').click();
      }).addClass('attached-tab-init')
    }, 100);

  }

  // Handle big-select fields
  setup_big_select_fields() {
    var block = this.block

    block.find('.use-big-select').each(function () {
      var label = $(`label[for="${$(this).attr('id')}"]`).html();
      $.big_select($(this),
        $('#primary-modal .modal-body'),
        $(this)[0].big_select_hash,
        function () { _fpa.show_modal('', label); },
        function () { _fpa.hide_modal(); }
      );

    })
  }

}
