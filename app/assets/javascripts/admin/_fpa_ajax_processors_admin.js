_fpa.postprocessors_admin = {

  admin_edit_form: function (block, data) {
    var _admin = this;
    _fpa.utils.scrollTo(block, 200, -50);

    $('tr.new-record').before($('tr.admin-list-item').first());

    $('.saved-row').removeClass('saved-row');
    $('.edit-as-custom-setup').removeClass('edit-as-custom-setup');
    _fpa.form_utils.format_block(block);
    block.find('#admin-edit-cancel').click(function (ev) {
      ev.preventDefault();
      block.html('');
    });

    if (block.find('.admin-edit-form.admin-report').length === 1) {
      _admin.handle_admin_report_config(block);
    };

    window.setTimeout(function () {
      var el = $('.admin-edit-form textarea');
      el.click();
    }, 300);


    // For the selection of resource types / names in user access control form
    var res_type_change = function ($el) {
      var val = $el.val();
      $('#admin_user_access_control_resource_name').attr('data-big-select-subtype', val)

      $('#admin_user_access_control_access optgroup[label]').hide();
      $('#admin_user_access_control_access optgroup[label="' + val + '"]').show();
      //   if (val == 'activity_log_type') {
      //     var url = new URL(window.location.href);

      //     var p = url.searchParams.get('filter[resource_name]')
      //     var opts = $('#admin_user_access_control_resource_name optgroup[label="' + val + '"] option');
      //     opts.show();
      //     if (p) {
      //       ps = p.replace('__%', '');
      //       if (ps != p) {
      //         opts.each(function () {
      //           var h = $(this).val();
      //           if (h.indexOf(ps) < 0) {
      //             $(this).hide();
      //           }
      //         });
      //       }
      //     }
      //   }
    };

    res_type_change($('#admin_user_access_control_resource_type'));
    block.on('change', '#admin_user_access_control_resource_type', function () {
      res_type_change($(this));
    });

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

    block.find('#admin_user_role_role_name').not('.added-user-role-typeahead').each(function () {
      var el = $(this);
      _fpa.set_definition('user_roles', function () {
        _fpa.form_utils.setup_typeahead(el, 'user_roles', "user_roles", 50);
      });
    }).addClass('added-user-role-typeahead');


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

    block.find('.extra-help-info').not('.code-extra-help-info-formatted').each(function () {
      if (!$(this).is(':visible')) return;
      _fpa.admin.setup_yaml_viewer($(this));
    }).addClass('code-extra-help-info-formatted');

    $('[data-toggle="tab"]').filter(':visible').on('shown.bs.tab', function () {

      var tar = $($(this).attr('href'));
      if (!tar.is(':visible')) return;

      var ehi = tar.find('.extra-help-info').not('.code-extra-help-info-formatted-in-tab');
      if (ehi.length) {
        CodeMirror.fromTextArea(ehi[0]).refresh();
        ehi.addClass('code-extra-help-info-formatted-in-tab')
      }
    })

    // $('.has-editor[data-toggle="collapse"]').filter(':visible').each(function () {
    //   var el = $($(this).attr('href'));

    //   el.on('shown.bs.collapse', function () {
    //     var ehi = $(this).find('.extra-help-info').not('.code-extra-help-info-formatted-in-collapse, .code-extra-help-info-formatted-in-tab').filter(':visible');
    //     ehi.each(function () {
    //       _fpa.admin.setup_yaml_editor($(this));
    //       ehi.addClass('code-extra-help-info-formatted-in-collapse code-extra-help-info-formatted-in-tab')
    //     });
    //   })
    // });

    $('.collapse.has-editor').on('shown.bs.collapse', function () {
      var ehi = $(this).find('.extra-help-info').not('.code-extra-help-info-formatted-in-collapse, .code-extra-help-info-formatted-in-tab').filter(':visible');
      ehi.each(function () {
        _fpa.admin.setup_yaml_editor($(this));
        ehi.addClass('code-extra-help-info-formatted-in-collapse code-extra-help-info-formatted-in-tab')
      });
    })

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


    // Handle big-select fields

    block.find('.use-big-select').each(function () {
      var label = $(`label[for="${$(this).attr('id')}"]`).html();
      $.big_select($(this),
        $('#primary-modal .modal-body'),
        $(this)[0].big_select_hash,
        function () { _fpa.show_modal('', label); },
        function () { _fpa.hide_modal(); }
      );

    })

    _fpa.form_utils.on_open_click(block);
    _fpa.form_utils.setup_drag_and_drop(block);

    if (block.find('.admin-edit-form .edit_dynamic_model').length === 1) {
      _admin.handle_admin_dynamic_model(block);
    };

  },

  admin_result: function (block, data) {
    $('#admin-edit-').html('');
    var b = $('.attached-tablesorter').trigger("update");;
    // _fpa.form_utils.format_block($('.tablesorter').parent());
    $('.postprocessed-scroll-here').removeClass('postprocessed-scroll-here').addClass('prevent-scroll');

    window.setTimeout(function () {
      _fpa.utils.scrollTo(block, 200, -50);
    }, 100);
    window.setTimeout(function () {
      $('prevent-scroll').removeClass('prevent-scroll');
    }, 1000);
  }

};
$.extend(_fpa.postprocessors, _fpa.postprocessors_admin);
