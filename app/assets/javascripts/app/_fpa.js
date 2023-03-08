_fpa = {
  templates: {},
  partials: {},
  app: {},
  state: {
    caption_before: {},
    dialog_before: {},
    template_config: {},
    template_config_versions: {},
  },

  view_handlers: {},
  app_specific: {},
  version: '0',
  remote_request: null,
  remote_request_block: null,

  non_versioned_template_types: [
    'trackers',
    'player_infos',
    'pro_infos',
    'addresses',
    'player_contacts',
    'nfs_store/manage/stored_files',
    'nfs_store/manage/archived_files',
    'nfs_store_containers',
    'messages',
    'masters',
    'masterss',
    'search_actions',
    'user_profiles',
    'user_preferences'
  ],

  HandlebarsCompileOptions: { preventIndent: true },
  page_transition_callback: null,

  result_target: function (block) {
    var d = $(block).attr('data-result-target');
    if (d && d.length > 1) return d;
    return null;
  },
  ajax_working: function (block) {
    try {
      var $block = $(block);

      var do_action = function ($block) {
        $block.addClass('ajax-running').removeClass('ajax-canceled');
        var bclicked = $block.data('button_clicked');
        if (bclicked) bclicked.addClass('ajax-clicked-running');
        var d = _fpa.result_target(block);
        if (d) $(d).addClass('ajax-running');
      };

      do_action($block);
      // data-working-target attribute allows us to indicate
      // a specific element is the target and is loading,
      // rather than the link or button we clicked.
      var alt_target = $block.attr('data-working-target');
      if (alt_target) do_action($(alt_target));
    } catch (err) { }
  },
  ajax_done: function (block) {
    try {
      var $block = $(block);

      var do_action = function ($block) {
        $block.removeClass('ajax-running').removeClass('ajax-canceled');
        var bclicked = $block.data('button_clicked');
        if (bclicked) bclicked.removeClass('ajax-clicked-running').blur();
        $block.data('button_clicked', null);
        var d = _fpa.result_target(block);
        if (d) $(d).removeClass('ajax-running').removeClass('ajax-canceled');
      };

      do_action($block);
      // data-working-target attribute allows us to indicate
      // a specific element is the target and is loading,
      // rather than the link or button we clicked.
      var alt_target = $block.attr('data-working-target');
      if (alt_target) do_action($(alt_target));
    } catch (err) { }
    _fpa.remote_request = null;
    _fpa.state.search_running = false;
  },
  ajax_canceled: function (block) {
    try {
      var $block = $(block);
      $block.removeClass('ajax-running').addClass('ajax-canceled');
      var bclicked = $block.data('button_clicked');
      if (bclicked) bclicked.removeClass('ajax-clicked-running').blur();
      $block.data('button_clicked', null);
      var d = _fpa.result_target(block);
      if (d) $(d).removeClass('ajax-running').addClass('ajax-canceled');
    } catch (err) { }
    _fpa.remote_request = null;
    _fpa.state.search_running = false;
  },
  compile_templates: function () {
    $('body').addClass('status-compiling');
    $('script.handlebars-partial')
      .not('.compiled')
      .each(function () {
        $(this).addClass('compiled');
        var id = $(this).attr('id');

        id = id.replace('-partial', '');

        var fnTemplate = Handlebars.compile($(this).html(), _fpa.HandlebarsCompileOptions);
        Handlebars.registerPartial(id, fnTemplate);
        _fpa.partials[id] = fnTemplate;
      });

    $('script.handlebars-template')
      .not('.compiled')
      .each(function () {
        $(this).addClass('compiled');
        var id = $(this).attr('id');
        var source = $(this).html();
        _fpa.templates[id] = Handlebars.compile(source, _fpa.HandlebarsCompileOptions);
      });
    $('body').removeClass('status-compiling initial-compiling').addClass('status-compiled');
  },

  send_ajax_request: function (url, options) {
    if (!options) options = {};

    options.url = url;
    $.rails.ajax(options).done(function (data, status, xhr) {
      var el = $('.temp-ajax-requester');
      if (el.length === 0) {
        el = $('a.temp-ajax-requester');

        if (el.length === 0) {
          el = $('<a data-remote="true" class="hidden temp-ajax-requester">background</a>');
          $('body').append(el);
        }
      }

      var tac = options.try_app_callback;
      if (tac) el[0].app_callback = tac;

      tac = options.try_app_post_callback;
      if (tac) el[0].app_post_callback = tac;

      $.rails.fire(el, 'ajax:success', [data, status, xhr]);
    });
  },

  // View a handlebars template
  // unless the block or its parent are marked as having been processed already
  // block - jQuery element to update
  // template_name
  // data - data context for handlebars
  // options  - currently options.position  =  null, 'before' or 'after'
  // before or after will place the result before or after the block (and empty the block)
  // alt_preprocessor - alternative preprocessor function to use if the template name doesn't work
  // The exception to the positioning of 'before' and 'after' is that if
  // the rendered template html has an id for its root element
  // that already exists on the page, the result will replace that existing element.
  // This maintains the integrity of ids in the DOM, and prevents the need to handle specific
  // replace functionality within preprocessors
  // The function returns a promise, resolved when then template has been fully prepared and rendered
  view_template: function (block, template_name, data, options, alt_preprocessor) {
    return new Promise(function (resolve, reject) {
      // Prevent an attempt to render the template in a block that has already been rendered in this request
      if (block.hasClass('view-template-created') || block.parent().hasClass('view-template-created')) return;

      // Potentially don't reload, especially if a sidebar request has been made
      if (block.parents('[data-no-load]').length) return;

      _fpa.ajax_working(block);
      if (!options) options = {};
      if (!options.position) {
        block.html('');
      }

      _fpa.prepare_template(block, template_name, data, options);
      _fpa.do_preprocessors(template_name, block, data, alt_preprocessor);
      _fpa.prepare_template_configs(data).then(function () {
        _fpa.render_template(block, template_name, data, options, alt_preprocessor);
        resolve();
      });
    });
  },

  prepare_template: function (block, template_name, data, options) {
    if (!template_name) console.log('no template_name provided');

    // Pull the template from the pre-compiled templates
    var template = _fpa.templates[template_name];

    if (!template) console.log('template for ' + template_name + ' was not found');

    options.template = template;
  },

  // A function that provides a promise.
  // Allow background loading of versioned definition template configs
  // that have not already been downloaded.
  // The promise is only resolved when the download has completed.
  prepare_template_configs: function (data) {
    return new Promise(function (resolve, reject) {
      var data_type = data.multiple_results;

      if (!data_type) {
        var data_for_data_type;
        for (var k in data) {
          if (k == 'masters' || k.indexOf('_') != 0) {
            data_type = k;
            break;
          }
        }

        data_for_data_type = data[data_type];

        // Model references have an item type attribute
        if (data_for_data_type) {
          data_for_data_type.vdef_version = data_for_data_type.vdef_version || 'v'
          var item_type = data_for_data_type.item_type || data_type;
        } else {
          var item_type = data_type;
        }

        var data_array = [data_for_data_type];
        var url_data_type = item_type.split('__').join('/').pluralize();
      } else {
        var data_array = data[data_type];
        var url_data_type = data_type.split('__').join('/');
      }

      var list_data_items = [];
      var list_data_item_state_ids = [];

      if (!url_data_type || _fpa.non_versioned_template_types.indexOf(url_data_type) >= 0) {
        resolve();
        return;
      }

      var data_master_id;

      for (var k in data_array) {
        if (!data_array.hasOwnProperty(k)) continue;

        var data_item = data_array[k];
        data_master_id = data_master_id || data && data.master_id || data_item && data_item.master_id;
        // Prevent requesting the template for the same instance multiple times
        // We don't use the definition version here, since it is possible for different
        // instances with the same definition version to return different results
        // due to runtime model references returning results with different template versions
        if (data_item) {
          var did = url_data_type + '/' + data_item.id;
          if (_fpa.state.template_config_versions[did] || !data_item.id) continue;

          _fpa.state.template_config_versions[did] = true;
          list_data_item_state_ids.push(did);
          list_data_items.push(data_item.id);
        }
      }
      if (list_data_items.length == 0 || !list_data_items[0]) {
        console.log('no template configs to get');
        resolve();
        return;
      }

      var url = '';
      if (data_master_id) {
        url = '/masters/' + data_master_id;
      }

      url = url + '/' + url_data_type + '/' + list_data_items.join(',') + '/template_config';

      $.ajax(url, {
        success: function (data) {
          var temploc = $('#master-main-template').first();
          // Iterate all the returned scripts and only add them to the DOM if a script with the same id
          // doesn't already exist. This prevents accidental bloating of the DOM with duplicates
          $(data).each(function () {
            var templateid = $(this).attr('id');
            if (!$('#' + templateid).length) {
              temploc.after($(this));
            }
          });
          _fpa.compile_templates();
          resolve();
        },
        error: function (data) {
          for (var k in list_data_item_state_ids) {
            _fpa.state.template_config_versions[did] = false;
          }
          resolve();
        },
      });
    });
  },

  // Render a retrieved template using the appropriate data in the DOM
  render_template: function (block, template_name, data, options, alt_preprocessor) {
    var template = options.template;
    var process_block = block;

    // Throw away the result if told to show no result
    if (!options.show_no_result) {

      // Render the result using the template and data
      try {
        var html = template(data);
      } catch (err) {
        console.log('(' + err + ') template function not defined for ' + template_name);
        console.log(err.stack);
      }
      html = $(html).addClass('view-template-created');

      var new_block = block;

      // Position the result before, after or in the current block
      if (options.position && options.position.indexOf('before') === 0) {
        var beforeBlock = block;
        if (options.position.indexOf('parent') > 0) {
          beforeBlock = block.parent();
        }

        new_block = html;
        var id = new_block.attr('id');
        // If the results has a root element with an id that exist in the DOM already,
        // TODO: !!!! this seems wrong - we don't want duplicate items !!!! and has not been created in this transaction,
        // replace it rather than placing the result before the specified block

        var existing = $('#' + id); //.not('.view-template-created');
        if (existing.length > 0) {
          existing.replaceWith(new_block);
        } else {
          beforeBlock.before(new_block);
        }
        process_block = new_block;
        block.html('');
      } else if (options.position && options.position.indexOf('after') === 0) {
        var afterBlock = block;
        if (options.position.indexOf('parent') > 0) {
          afterBlock = block.parent();
        }

        new_block = html;
        var id = new_block.attr('id');
        var existing = $('#' + id);
        // If the results has a root element with an id that exist in the DOM already,
        // replace it rather than placing the result after the specified block
        if (existing.length > 0) {
          existing.replaceWith(new_block);
        } else {
          afterBlock.after(new_block);
        }
        block.html('');
        process_block = new_block;
      } else {
        new_block = html;

        // If the results has a root element with an id that matches the existing block,
        // replace it rather than placing the result inside the current item
        if (block.attr('id') && block.attr('id') == new_block.attr('id')) {
          block.replaceWith(new_block);
        } else {
          // Just replace the content of the specified block
          block.html(html);
        }
      }
    }
    // We handle the post processing in a timeout to give the UI the opportunity to render the
    // template, providing for a more responsive, less jerky experience.
    window.setTimeout(function () {
      _fpa.do_postprocessors(template_name, process_block, data, alt_preprocessor);
      _fpa.reset_page_size();
      _fpa.ajax_done(block);
    }, 1);
  },

  // For certain layouts with clever fixed positioning requirements, allow the
  // page dimensions to be set after major changes to the page
  reset_page_size: function () { },

  // Provide inheritance style functionality of javascript prototypes
  inherit_from: function (original_prototype, new_t) {
    function F() { }
    F.prototype = original_prototype;
    $.extend(F.prototype, new_t);
    return F.prototype;
  },

  // Sometimes we need a preprocessor or postprocessor to be able to define a callback that will be called on the next successful
  // AJAX response. This function attempts to call that callback if it has been set, and then clears it after use.
  try_app_callback: function (el, xhr) {
    var data = xhr.responseJSON || $(xhr.responseText);

    if (el[0].app_callback) {
      el[0].app_callback(el[0], data);
      el[0].app_callback = null;
    }
  },

  try_app_post_callback: function (el) {
    if (el[0].app_post_callback) {
      el[0].app_post_callback(el[0]);
      el[0].app_post_callback = null;
    }
  },

  // Run preprocessing function
  // Use the *pre* argument as the primary function name to use
  // If not found using this, and alt_preprocessor is specified, try this instead
  // Finally, run the default preprocessor, indicating if either pre or alt_
  // preprocessors were run, allowing the default preprocessor
  // logic to selectively run some or all of the functionality.
  do_preprocessors: function (pre, block, data, alt_preprocessor) {
    var procfound = false;
    if (pre) {
      pre = pre.replace(/-/g, '_');
      if (_fpa.preprocessors[pre]) {
        _fpa.preprocessors[pre](block, data);
        procfound = true;
      }
    }

    if (!procfound && alt_preprocessor) {
      alt_preprocessor = alt_preprocessor.replace(/-/g, '_');
      if (_fpa.preprocessors[alt_preprocessor]) {
        _fpa.preprocessors[alt_preprocessor](block, data);
        procfound = true;
      }
    }

    if (_fpa.app_specific.preprocessor) {
      _fpa.app_specific.preprocessor(block, data);
    }

    _fpa.preprocessors.default(block, data, procfound);
  },

  do_postprocessors: function (pre, block, data, alt_processor) {
    var procfound = false;
    if (pre) {
      pre = pre.replace(/-/g, '_');
      if (_fpa.postprocessors[pre]) {
        _fpa.postprocessors[pre](block, data);
        procfound = true;
      }
    }

    if (!procfound && alt_processor) {
      alt_processor = alt_processor.replace(/-/g, '_');
      if (_fpa.postprocessors[alt_processor]) {
        _fpa.postprocessors[alt_processor](block, data);
        procfound = true;
      }
    }

    if (_fpa.app_specific.postprocessor) {
      _fpa.app_specific.postprocessor(block, data);
    }

    _fpa.postprocessors.default(block, data, procfound);
  },

  // Handle AJAX calls made through Rails data-remote="true" functionality
  handle_remotes: function () {
    if (_fpa.state.remotes_setup) return;
    console.log('Handling remotes');
    var sel = "form[data-remote='true'], a, btn";

    $(document)
      .on('click', sel, function (ev) {
        // Clear flash notices by clicking an ajax enabled link or form
        if ($(this).attr('disabled')) return;
        if ($(this).is(':visible') && !$(this).hasClass('keep-notices')) {
          _fpa.clear_flash_notices();
        }
      })
      .on('ajax:before', sel, function (ev) {
        // Prevent this being handled in a parent, such as happens if we have a link in a form
        if (ev.target != ev.currentTarget) return;

        var block = $(this);
        _fpa.remote_request = null;
        _fpa.remote_request_block = block;

        var bclicked = block.find('input[type="submit"], button');

        if (bclicked.is(':focus')) {
          block.data('button_clicked', bclicked);
        } else {
          block.data('button_clicked', null);
        }

        // If a form was submitted, clear any of the enclosed .field_was_changed flags
        // If not a form submit or cancel and there is an outer form that holds fields with this flag
        // show the user a notice and allow them to cancel or continue the save.
        var bsubmitted = block.find('input[type="submit"]:focus');
        if (bsubmitted.length) {
          block.find('.field-was-changed').removeClass('field-was-changed');
          block.parents('form').find('.field-was-changed').removeClass('field-was-changed');
          if (block.parents('.prevent-reload-on-reference-save').length === 0 &&
            block.parents('[data-model-data-type="activity_log"]').find('.field-was-changed').length) {
            _fpa.flash_notice('Form fields have not been saved. Do you want to <a class="btn btn-default submit-cancel-change">cancel and keep the changes</a> so you can save the form, or <a class="btn btn-danger submit-continue-change">continue without saving</a>', 'warning');

            $('.alert a.submit-continue-change').on('click', function () {
              block.parents('[data-model-data-type="activity_log"]').find('.field-was-changed').removeClass('field-was-changed');
              bsubmitted.click();
              _fpa.clear_flash_notices();
            })
            $('.alert a.submit-cancel-change').on('click', function () {
              _fpa.clear_flash_notices();
            })
            ev.preventDefault();
            return false;
          }
        }

        // Handle the special case where we don't want the request to continue if the
        // triggering element has the class prevent-on-collapse and it is collapsed.
        // This allows for expanders to only trigger in one direction,
        // when expanding rather than collapsing
        if ($(this).hasClass('prevent-on-collapse') && !$(this).hasClass('collapsed')) {
          ev.preventDefault();
          return false;
        }

        // Add the class prevent-first-ajax to a data-remote link
        // to prevent the first ajax call from this link, then re-enable future requests
        if ($(this).hasClass('prevent-first-ajax')) {
          ev.preventDefault();
          $(this).removeClass('prevent-first-ajax');
          return false;
        }

        if ($(this).hasClass('one-time-only-ajax')) {
          if ($(this).hasClass('one-time-only-fired')) {
            ev.preventDefault();
            return false;
          } else {
            $(this).addClass('one-time-only-fired');
          }
        }

        _fpa.preprocessors.before_all(block);
        _fpa.ajax_working(block);
        _fpa.form_utils.set_field_errors(block);

        // data-only-for allows hidden and other inputs to be blanked if the dependent
        // 'only-for' input is blank. This ensures the data is set only for the times when the
        // related data is a real value
        $(this)
          .find('[data-only-for]')
          .each(function () {
            var dof = $(this).attr('data-only-for');
            var all_null = true;
            $(dof).each(function () {
              var dofv = $(this).val();
              if (dofv !== null && dofv !== '') all_null = false;
            });

            if (all_null) {
              $(this).removeClass('has-value').val('');
            }
          });

        return true;
      })
      .on('ajax:beforeSend', sel, function (ev, xhr) {
        // Save the current AJAX request so that we have the opportunity to cancel it before it completes
        _fpa.remote_request = xhr;
      })
      .on('ajax:success', sel, function (e, data, status, xhr) {
        // Since the result was a success, reset the client-side session timeout counter
        // This is required, otherwise a user working on a single page application for an extended
        // period of time could get bounced out of the page because the client thinks they have timed out,
        // but their session is still valid and active after multiple AJAX requests
        _fpa.status.session.reset_timeout();
        var block = $(this);
        var data = xhr.responseJSON;
        if ($(this).is(':visible') && !$(this).hasClass('keep-notices')) {
          _fpa.clear_flash_notices();
        }
        _fpa.ajax_done(block);

        var prep_template_promises = [];

        // Attempt an app-specific callback that a preprocessor may have created.
        // Typically used by special UI blocks that need to perform additional functions before the response
        // attempts to process
        _fpa.try_app_callback($(this), xhr);

        // If the result is JSON process the data
        // else, process the rendered HTML
        if (data) {
          var t;
          var t_force;
          var use_target = false;

          if (data.flash_message_only) {
            _fpa.flash_notice(data.flash_message_only);
            return;
          }

          // Identify whether to target the results at a single dom element or to handle data subscriptions
          // Check the first entry in the returned data to see if the record indicates it was created
          // This will not show if a result set of multiple items is returned
          // (whether the result of an index or a create that affected multiple items)
          // which is the desired effect, as multiple results must not be directed at a single DOM element
          // Results that were not newly created can be directed at the specified data-result-target if other data-sub-item
          // markup is not found for returned item.
          t = $(this).attr('data-result-target');
          var item_key;
          var dataitem;
          var target_data;

          // Handle the requirement that data in the response may not have an exact matching key to the template.
          // For example, activity log blank items have this, where the template name is "activity_log__player_contact_phone_blank_log"
          // but the data comes back from a standard ActivityLog::PlayerContactPhone object and therefore has a JSON response
          // keyed by "activity_log__player_contact_phone"
          // The block markup (the form) can use data-use-alt-result-key="activity_log__player_contact_phone_blank_log" to force
          // the use data into the key the template is expecting
          var alt_data_key = block.attr('data-use-alt-result-key');

          if (data.multiple_results && data.original_item) {
            item_key = data.multiple_results;
            dataitem = data.original_item;
            target_data = {};

            target_data[dataitem.item_type] = dataitem;
          } else {
            // Get the first data key (ignoring _control, which is used for non-data management tasks)
            for (item_key in data) {
              if (data.hasOwnProperty(item_key) && item_key != '_control') break;
            }

            if (alt_data_key && alt_data_key != item_key) {
              data[alt_data_key] = data[item_key];
              dataitem = data[alt_data_key];
              // delete the original key, so we don't use it mistakenly elsewhere
              delete data[item_key];
            } else {
              dataitem = data[item_key];
            }
            target_data = data;
            // Ensure we use the target if there are multiple results specified, but no original item from a create or merge
            t_force = !!data.multiple_results;
          }

          var t_abs_force = false;
          if ($(this).attr('data-result-target-force') === 'true') t_abs_force = true;

          // If a triggering block has the attribute data-result-target
          // decide if the rendered template should display where this attribute requests
          // We use the specified result-target if we get a _created or _merged response (when the request
          // is returning a result that is mostly likely different to that we would normally expect, such as an update returning a list of changed elements).
          // If no data-sub-item or data-sub-list is specified that matches a key in the reponse data, then we really have no other option but to position the result
          // where requested.
          // Finally if the results are 'multiple_results' but there was no original_item specified, then this a pure index. If there is a target, use it.
          if (
            t &&
            (t_abs_force ||
              t_force ||
              dataitem === null ||
              dataitem['_created'] ||
              dataitem['_merged'] ||
              $('[data-sub-item="' + item_key + '"], [data-sub-list="' + item_key + '"] [data-sub-item]').length ===
              0 ||
              $(this).parents('[data-result-target-for-child]').length > 0)
          ) {
            use_target = true;
          }

          var options = {};
          if (use_target) {
            // Check if a parent tells us to use a different target (a div around a form can force this to point to a specific location by putting the
            // target in the data-result-target-for-child attribute)
            var base_block = $('body');
            // if(!t_abs_force) {
            var pt = $(this).parents('[data-result-target-for-child]').first();
            if (pt.length == 1) {
              drtc = pt.attr('data-result-target-for-child');
              if (drtc) {
                t = drtc;
                base_block = $(this).parents('[data-template]');
              }
            }
            // }
            // A specific target was specified an is being used.
            // Handle class markup that state whether to target this item directly, or add new elements above or below
            // the targeted element
            var b = base_block.find(t);
            if (b.hasClass('new-block')) {
              if (b.hasClass('new-after-parent')) options.position = 'after parent';
              else if (b.hasClass('new-before-parent')) options.position = 'before parent';
              else if (b.hasClass('new-below')) options.position = 'after';
              else if (b.hasClass('new-after')) options.position = 'after';
              else options.position = 'before';
            }

            // Do not add the result template if the class show-no-result is set on the target container.
            // Pre and post processors are still called though.
            if (b.hasClass('show-no-result')) {
              options.show_no_result = true;
            }
            // Since we may have specified multiple items to match the target, run through each in turn
            // making sure to use any specific templates they specify
            var default_tname = $(this).attr('data-template');

            b.each(function () {
              var $this = $(this);

              // Render the template result using the data-template attribute name for the template
              // It is possible that this request will be canceled within view_template, avoiding double-rendering of items.
              // That said, if the view_template request completes fully, no subsequent processing will overwrite this block's contents
              // (which can happen with complex interactions otherwise)
              var tname = default_tname;
              var alt_tname = $this.attr('form-res-template');
              if (alt_tname && alt_tname !== '') {
                tname = alt_tname;
              }

              if (!tname) console.log('Warning: data-template for this triggering element was not found');

              var pre = $(this).attr('data-preprocessor');
              var prom = _fpa.view_template($this, tname, target_data, options, pre);
              prep_template_promises.push(prom);
              prom.then(function () {
                _fpa.try_app_post_callback($this);
              });
            });
          }

          // Wait on all previous templates being viewed, to ensure items aren't overwritten incorrectly
          Promise.all(prep_template_promises).then(function () {
            if (!t_abs_force) {
              if (block.hasClass('new-block')) {
                block.html('');
              }
              // Run through the top level of data to pick the keys to look for in element subscriptions
              for (var di in data) {
                if (di == 'multiple_results') continue;

                if (data.hasOwnProperty(di)) {
                  var res = {};
                  var d = data[di];

                  // DOM attribute targeting
                  // will only use the following targets
                  // Certain refinements to each of these are identified through additional markup, specified below
                  var targets = $(
                    '[data-sub-item="' +
                    di +
                    '"], [data-sub-list="' +
                    di +
                    '"] [data-sub-item], [data-item-class="' +
                    di +
                    '"]'
                  );

                  res[di] = d;
                  targets.each(function () {
                    var $this = $(this);
                    var use_data = res;
                    var dsid = $this.attr('data-sub-id');
                    var dst = $this.attr('data-sub-item');
                    // data-item-class is used for activity logs that gain the step type in the data-sub-item, breaking the matching
                    // data-item-class is the plain class name
                    var dsc = $this.attr('data-item-class');
                    if (dsid && (dst || dsc)) {
                      use_data = null;
                      // Optionally use a different ID attribute (such as master_id) for the following listeners
                      var dsfor = $this.attr('data-sub-for');
                      if (!dsfor) dsfor = 'id';

                      // Check if we should be looking in the root of the data, rather than in the items
                      // This special case only kicks in when the triggered block has the attribute data-sub-for-root
                      // It allows for processing of groups of items with a 'master key' specified by the combo sub-for-root (naming the key) and
                      // sub-id (specifying the value of that key), rather than just responding to individual items in the data.
                      // Typical markup is:
                      // <span data-sub-for-root="master_id" data-sub-id="234" data-sub-item="trackers" ...>{{trackers.length}}</span>
                      // which responds to a data response like:
                      // {master_id: 234, trackers: [{},{},{}]}
                      // Since this will only respond to master_id == 234 and a root element 'trackers', we can be quite specific in the data
                      // we respond to, while general enough that we can broadly listen to meaningful results.
                      // As this sends the full set of data, it is especially for counters and handlers of arrays of elements
                      var dsforroot = $this.attr('data-sub-for-root');
                      if (dsforroot) {
                        if (data[dsforroot]) {
                          item_data = data;
                          // if the returned data has the specified attribute in its root
                          // and also has the specified data-sub-item attribute
                          if (item_data[dsforroot] === +dsid && item_data[dst]) {
                            use_data = {};
                            use_data = item_data;
                          }
                        }
                      } else if (d && d[dsfor]) {
                        // Another special case when we are looking just for elements that match the item type
                        // (forced back into the data at the start of response handling) and either the
                        // id or the attribute specified by data-sub-for
                        // For example:
                        // <div data-sub-for="master_id" data-sub-id="789" data-sub-item="player_info">
                        // which would respond to the data
                        // {master_id:789, player_info:{<this data gets passed>}, player_contact:{} }
                        // This listener is looking for individual player_info records with a specific 'master key', and passing just
                        // the content of that data to the template.
                        // Note that we underscore the item_type, since this handles the compounded parent/item_type
                        // results for 'works_with_item' classes
                        item_data = d;
                        var matching_data_sub_item = alt_data_key;
                        if (!matching_data_sub_item && item_data.item_type) matching_data_sub_item = item_data.item_type.underscore();
                        if (item_data[dsfor] === +dsid) {
                          if (matching_data_sub_item == null) {
                            use_data = {};
                            use_data[dst] = item_data;
                          } else if (matching_data_sub_item === dst) {
                            use_data = {};
                            use_data[dst] = item_data;
                          } else if (matching_data_sub_item === dsc) {
                            use_data = {};
                            use_data[dsc] = item_data;
                            use_data[dst] = item_data;
                          }
                        }
                      } else if (d) {
                        // The least specific case is to run through the array of data elements, having
                        // id or the attribute specified by data-sub-for, and seeing whether any
                        // match the specified value
                        // This is a simple case:
                        // <div data-sub-item="player_contact" data-sub-id="456" ...>
                        // which will match data like this:
                        // {player_contact: {id: 456, <this data>}, player_info: {id: 888, <not this data>} }
                        // and will pass just the matched item to the template
                        for (var g in d) {
                          var item_data = d[g];
                          if (
                            item_data &&
                            typeof item_data != 'string' &&
                            item_data[dsfor] === +dsid &&
                            item_data.item_type === dst
                          ) {
                            use_data = {};
                            use_data[dst] = item_data;
                          }
                        }
                      }
                    }

                    // We got a usable result, so display it (according to the rule that
                    // we can't overwrite a block previously processed in this request)
                    if (use_data) {
                      var dt = $this.attr('data-template');
                      var pre = $(this).attr('data-preprocessor');
                      if (!dt) console.log('WARN: no data-template template name found');
                      var prom = _fpa.view_template($this, dt, use_data, null, pre);
                      prom.then(function () {
                        _fpa.try_app_post_callback($this);
                      });
                    }
                  });
                }
              }
            }
            $('.view-template-created').removeClass('view-template-created');
          });
        } else {
          var put_in_position = function (t, d) {
            var pos = t.attr('data-result-position');
            if (pos == 'replace') t.replaceWith(d);
            else if (pos == 'before') t.before(d);
            else if (pos == 'after') t.after(d);
            else {
              t.html(d);
              t.removeClass('hidden');
              t.show();
            }
          };

          // Since the results was basic HTML rendered by a partial typically, just push it into the
          // DOM where specified
          var html = $(xhr.responseText);
          $('.query-error').remove();
          var updated = 0;

          // Set up an array that can be used in preprocessor to assign data in postprocessors, etc.
          if (!data) data = {};

          var trigger = $(this);

          html.find('[data-result]').each(function () {
            var d = $(this);
            var di = d.attr('data-result');
            var isform = d.find('form');
            var formcontainer = $(e.currentTarget).parents('[data-form-container]');

            if (trigger.attr('data-target-force') === 'true') {
              var t = trigger.attr('data-target');
              if (!t || t === '')
                console.log(
                  'Failed due to no data-target attribute being set when data-target-force is true and the result is an HTML block'
                );
              var targets = $(t);
              e.stopPropagation();
            } else {
              if (isform.length == 1 && formcontainer.length == 1) {
                if (formcontainer.attr('data-subscription') == di) var targets = formcontainer;
                else var targets = formcontainer.find('[data-subscription="' + di + '"]');
              } else {
                var targets = $('[data-subscription="' + di + '"]');
              }

              if (targets.length === 0) console.log('WARN: [data-subscription="' + di + '"] returns no targets');
            }

            if (isform.length == 1) data.form_data = _fpa.form_utils.data_from_form(isform);

            var res = {};
            res[di] = d;
            targets.each(function () {
              var $target = $(this);
              // If a subscription was inside an element that has already been replaced, just return
              if ($target.parents('body').length === 0) return;

              // By default, These preprocessors are defined on the target element, not the trigger,
              // so each target is treated differently.
              var pre = $target.attr('data-preprocessor');
              // NOTE: the target element may be replaced through these functions
              // $(this) is used on each to ensure that the latest target is used for each call
              _fpa.do_preprocessors(pre, $(this), data);
              put_in_position($(this), d);
              _fpa.do_postprocessors(pre, $(this), data);
              updated++;
            });
          });

          if (updated === 0) {
            var $trigger = $(this);
            var target = $trigger.attr('data-result-target');
            if (target) {
              // These preprocessors are defined on the triggering element (often a link)
              // rather than an updated block (since there was no updated block)
              var pre = $trigger.attr('data-preprocessor');

              // NOTE: the target element may be replaced through these functions
              // $(target) is used on each to ensure that the latest target is used for each call
              _fpa.do_preprocessors(pre, $(target), data);
              put_in_position($(target), html);
              _fpa.do_postprocessors(pre, $(target), data);
            }
          }
        }
        $('.view-template-created').removeClass('view-template-created');
      })
      .on('ajax:error', function (e, xhr, status, error) {
        var block = $(this);
        _fpa.clear_flash_notices();
        _fpa.ajax_done(block);

        $('.ajax-clicked-running').removeClass('ajax-clicked-running').blur();

        var format_message = function (j) {
          var msg = '';
          var msgar = [];
          for (var i in j) {
            if (j.hasOwnProperty(i)) {
              msgar.push(i.replace(/_/g, ' ') + ' ' + j[i]);
            }
          }
          msg = msgar.join(' \n');
          return msg;
        };

        if (status != 'abort') {
          var j = xhr.responseJSON;
          if (xhr.status === 422) {
            _fpa.form_utils.set_field_errors($('.ajax-running'), j);
            if (j) {
              var msg = '<p>Could not complete action:</p>';
              msg += format_message(j);
            } else {
              j = xhr.responseText;
              if (j) var msg = '<div>' + j + '</div>';
              else
                var msg =
                  '<p>Could not complete action. Please <a href="#" onclick="window.location.reload(); return false;">refresh the page</a> and try again.</p>';
            }

            _fpa.flash_notice(msg, 'warning');
          } else {
            if (j) {
              msg = format_message(j);
              _fpa.flash_notice(msg, 'danger');
            } else if (xhr.responseText && xhr.responseText[0] != '<') {
              _fpa.flash_notice(xhr.responseText, 'danger');
            } else {
              _fpa.flash_notice('An error occurred.', 'danger');
            }
          }
        }

        _fpa.postprocessors.after_error(block, status, error);

        $('.ajax-running').removeClass('ajax-running');
      })
      .addClass('attached');

    _fpa.state.remotes_setup = true;
  },

  // Enable a long running ajax request to be canceled
  cancel_remote: function () {
    if (_fpa.remote_request) {
      console.log('Cancel requested');

      _fpa.remote_request.abort();

      _fpa.ajax_canceled(_fpa.remote_request_block);
      _fpa.remote_request_block = null;
      _fpa.remote_request = null;
      _fpa.state.search_running = false;
    }
  },

  // Display Rails style flash notices in response to Ajax events (or any other Javascript that wishes to use this mechanism)
  flash_notice: function (msg, type) {
    if (!type) type = 'info';
    if (!msg || msg == '') return;

    if (msg.indexOf('password is not correct. Account has been locked.') > 0) {
      window.location.href = '';
      return;
    }

    var a = '<div class="alert alert-' + type + '" role="alert">';
    a +=
      '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>';
    if (type == 'error' || type == 'danger') {
      var msg_safe = $('<div/>').text(msg).html();
      a += msg_safe.replace(/\n/g, '<br/>');
    } else {
      a += msg.replace(/\n/g, '<br/>');
    }
    a += '</div>';

    $('.flash').append(a);
    _fpa.timed_flash_fadeout();
  },

  timed_flash_fadeout: function () {
    window.setTimeout(function () {
      $('.alert-info').fadeOut(1000);
    }, 6000);
  },
  clear_flash_notices: function (type) {
    if (!type) type = '';
    else type = '.alert-' + type;
    $('.flash div.alert' + type).remove();
  },

  // Show a bootstrap style modal dialog
  show_modal: function (message, title, large, add_class, modal_index, callback) {
    if (!modal_index) modal_index = '';
    var pm = $(`#primary-modal${modal_index}`);
    var t = pm.find('.modal-title');
    var m = pm.find('.modal-body');
    t.html('');
    m.html('');

    if (title) t.html(title);
    if (message) m.html(message);

    // Reset the class to the original
    var md = pm.find('.modal-dialog')
    md.prop('class', 'modal-dialog')

    if (large && large == 'md') md.removeClass('modal-lg').addClass('modal-md');
    else if (large) md.removeClass('modal-md').addClass('modal-lg');
    else md.removeClass('modal-lg').removeClass('modal-md');

    if (add_class)
      md.addClass(add_class);

    pm.on('hidden.bs.modal', function () {
      m.html('');
      _fpa.utils.scrollTo(0, 0, 0, m)
      var riomc = $('.refresh-item-on-modal-close').first();
      if (riomc.length) {
        riomc.parents('.common-template-item').last().find('a.refresh-item').click();
        riomc.removeClass('refresh-item-on-modal-close');
      }

      if ($('.modal.was-in').length == 0) {
        $('body').removeClass('table-results');
        $('html').css({ overflow: 'auto' });
        _fpa.reports.reset_window_scrolling();
        if (_fpa.state.scroll_pos_before_modal != null)
          _fpa.utils.scrollTo(_fpa.state.scroll_pos_before_modal, 0, 0, $(document));
      }

      pm.off('shown.bs.modal');
      pm.off('hidden.bs.modal');
    });

    _fpa.state.scroll_pos_before_modal = $(document).scrollTop();

    pm.modal('show');

    pm.on('shown.bs.modal', function () {
      _fpa.utils.scrollTo(0, 0, 0, m)
      $('html').css({ overflow: 'hidden' });
      if (callback) callback(m);
    })

    if (modal_index) {
      // Hide a previously shown modal back
      $('.modal.in').removeClass('in').addClass('was-in');

      pm.on('click.dismiss.bs.modal', `[data-dismiss="modal${modal_index}"]`, function () {
        _fpa.hide_modal(modal_index);
      })
    }


    return pm;
  },

  hide_modal: function (modal_index) {
    if (!modal_index) modal_index = '';
    var pm = $(`#primary-modal${modal_index}`);

    if (pm.hasClass('was-in')) return;

    var t = pm.find('.modal-title');
    var m = pm.find('.modal-body');
    _fpa.utils.scrollTo(0, 0, 0, m);

    t.html('');
    m.html('');
    pm.modal('hide');

    // Put a previously shown modal back
    window.setTimeout(function () {
      $('.modal.was-in').removeClass('was-in').addClass('in');
    }, 300)
  },

  get_item_by: function (attr, obj, evid) {
    for (var pi in obj) {
      if (obj.hasOwnProperty(pi)) {
        var p = obj[pi];
        if (p[attr] == evid) {
          return p;
        }
      }
    }
  },

  // Get array of items from cached data (basically equivalent of .map function) based on attribute and value
  get_items_by: function (attr, obj, evid) {
    var res = [];
    for (var pi in obj) {
      if (obj.hasOwnProperty(pi)) {
        var p = obj[pi];
        if (p[attr] == evid) {
          res.push(p);
        }
      }
    }
    return res;
  },

  // Get array of items from cached data based on attribute and value
  // returning a hash array key set from the index_attr
  // For example:
  // _fpa.get_items_as_hash_by('item_type', pe, "activity_log__bhs_assignment_select_result", 'value');
  // returns:
  // {complete: {…}, in progress: {…}}
  get_items_as_hash_by: function (attr, obj, evid, index_attr) {
    var res = {};
    for (var pi in obj) {
      if (obj.hasOwnProperty(pi)) {
        var p = obj[pi];
        if (p[attr] == evid) {
          res[p[index_attr]] = p;
        }
      }
    }
    return res;
  },

  catch_page_transition: function (callback) {
    _fpa.page_transition_callback = callback;
    $('body').addClass('prevent-page-change');
  },

  default_page_transition: function () {
    _fpa.page_transition_callback = null;
    $('body').removeClass('prevent-page-change');
  },
};

_fpa.preprocessors = {};
_fpa.loaded = {};
