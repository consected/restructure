_fpa = {

  templates: {},
  partials: {},
  app: {},
  state: {},
  version: '0',
  remote_request: null,
  remote_request_block: null,

  ajax_working: function(block){

    $(block).addClass('ajax-running').removeClass('ajax-canceled');
  },
  ajax_done: function(block){
    $(block).removeClass('ajax-running').removeClass('ajax-canceled');
    _fpa.remote_request = null;
  },
  ajax_canceled: function(block){
    $(block).removeClass('ajax-running').addClass('ajax-canceled');
    _fpa.remote_request = null;
  },
  compile_templates: function(){
    $('script.handlebars-partial').each(function(){
        var id = $(this).attr('id');

        id = id.replace('-partial', '');
        var fnTemplate = Handlebars.compile($(this).html());
        Handlebars.registerPartial(id, fnTemplate);
        _fpa.partials[id] = fnTemplate;
    });

    $('script.handlebars-template').each(function(){
        var id = $(this).attr('id');
        var source = $(this).html();
        _fpa.templates[id] = Handlebars.compile(source);

    });

  },

  send_ajax_request: function(url, options){

    if(!options)
      options = {};

    options.url = url;

    $.rails.ajax(options).done(function(data, status, xhr){
      var el = $('.temp-ajax-requester');
      if(el.length === 0) {
        el = $('a.temp-ajax-requester');

        if(el.length === 0) {
          el = $('<a data-remote="true" class="hidden temp-ajax-requester">background</a>');
          $('body').append(el);
        }
      }

      var tac = options.try_app_callback;
      if(tac)
        el[0].app_callback = tac;

      tac = options.try_app_post_callback;
      if(tac)
        el[0].app_post_callback = tac;

      $.rails.fire(el, 'ajax:success', [data, status, xhr]);
    });

  },

  // View a handlebars template
  // block - jQuery element to update
  // template_name
  // data - data context for handlebars
  // options  - currently options.position  =  null, 'before' or 'after'
  // before or after will place the result before or after the block (and empty the block)
  // The exception to the positioning of 'before' and 'after' is that if
  // the rendered template html has an id for its root element
  // that already exists on the page, the result will replace that existing element.
  // This maintains the integrity of ids in the DOM, and prevents the need to handle specific
  // replace functionality within preprocessors
  view_template: function(block, template_name, data, options){

    // Prevent an attempt to render the template in a block that has already been rendered in this request
    if(block.hasClass('view-template-created')) return;

    if(!template_name) console.log("no template_name provided");

    _fpa.ajax_working(block);
    if(!options || !options.position){
        block.html('');
    }

    // Pull the template from the pre-compiled templates
    var template =_fpa.templates[template_name];

    if(!template)
      console.log("template for "+template_name+" was not found");

    if(!options) options = {};

    // Special handling for handlebars handling of certain codes.
    // Can most likely be removed
    if(data.code){
      data._code_flag = {};
      data._code_flag[data.code] = true;
    }

    _fpa.do_preprocessors(template_name, block, data);

    // Render the result using the template and data
    var html = template(data);
    html = $(html).addClass('view-template-created');

    var new_block = block;

    // Position the result before, after or in the current block
    if(options.position && options.position.indexOf('before') === 0){
        var beforeBlock = block;
        if(options.position.indexOf('parent') > 0){
          beforeBlock = block.parent();
        }

        new_block = html;
        var id = new_block.attr('id');
        // If the results has a root element with an id that exist in the DOM already,
        // and has not been created in this transaction,
        // replace it rather than placing the result before the specified block
        var existing = $('#'+id).not('.view-template-created');
        if(existing.length > 0){
            existing.replaceWith(new_block);
        }
        else{
            beforeBlock.before(new_block);
        }
        block.html('');
    } else if(options.position && options.position.indexOf('after') === 0){

        var afterBlock = block;
        if(options.position.indexOf('parent') > 0){
          afterBlock = block.parent();
        }

        new_block = html;
        var id = new_block.attr('id');
        var existing = $('#'+id);
        // If the results has a root element with an id that exist in the DOM already,
        // replace it rather than placing the result after the specified block
        if(existing.length > 0){
          existing.replaceWith(new_block);
        }
        else{
          afterBlock.after(new_block);
        }
        block.html('');
    }
    else{
        // Just replace the content of the specified block
        block.html(html);
    }

    // We handle the post processing in a timeout to give the UI the opportunity to render the
    // template, providing for a more responsive, less jerky experience.
    window.setTimeout(function(){
        _fpa.do_postprocessors(template_name, new_block, data);
        _fpa.reset_page_size();
        _fpa.ajax_done(block);
    }, 1);
  },


  // For certain layouts with clever fixed positioning requirements, allow the
  // page dimensions to be set after major changes to the page
  reset_page_size: function(){

  },

  // Provide inheritance style functionality of javascript prototypes
  inherit_from: function(original_prototype, new_t){
    function F() {}
    F.prototype = original_prototype;
    $.extend(F.prototype, new_t);
    return F.prototype;
  },


  // Sometimes we need a preprocessor or postprocessor to be able to define a callback that will be called on the next successful
  // AJAX response. This function attempts to call that callback if it has been set, and then clears it after use.
  try_app_callback: function(el){
    if(el[0].app_callback){
        el[0].app_callback(el[0]);
        el[0].app_callback = null;
    }
  },

  try_app_post_callback: function(el){
    if(el[0].app_post_callback){
        el[0].app_post_callback(el[0]);
        el[0].app_post_callback = null;
    }
  },

  do_preprocessors: function(pre, block, data){
    var procfound = false;
    if(pre){
        pre = pre.replace(/-/g, '_');
        if(_fpa.preprocessors[pre]){
            _fpa.preprocessors[pre](block, data);
            procfound = true;
        }
    }
    _fpa.preprocessors.default(block, data, procfound);
  },

  do_postprocessors: function(pre, block, data){
    var procfound = false;
    if(pre){
        pre = pre.replace(/-/g, '_');
        if(_fpa.postprocessors[pre]){
            _fpa.postprocessors[pre](block, data);
            procfound = true;
        }
    }
    _fpa.postprocessors.default(block, data, procfound);
  },


  // Handle AJAX calls made through Rails data-remote="true" functionality
  handle_remotes: function(){

    var sel = "form[data-remote='true'], a[data-remote='true']";

    $(document).on('click', sel,  function(ev){
      // Clear flash notices by clicking an ajax enabled link or form
      _fpa.clear_flash_notices();

    }).on('ajax:before', sel, function(ev){
        var block = $(this);
        _fpa.remote_request = null;
        _fpa.remote_request_block = block;

        console.log((new Date()).toLocaleString() +' event requested by:');
        console.log(block);

        // Handle the special case where we don't want the request to continue if the
        // triggering element has the class prevent-on-collapse and it is collapsed.
        // This allows for expanders to only trigger in one direction,
        // when expanding rather than collapsing
        if($(this).hasClass('prevent-on-collapse') && !$(this).hasClass('collapsed')){
            ev.preventDefault();
            return false;
        }

        if($(this).hasClass('one-time-only-ajax')){

            if($(this).hasClass('one-time-only-fired')){
                ev.preventDefault();
                return false;
            }else{
                $(this).addClass('one-time-only-fired');
            }
        }


        _fpa.preprocessors.before_all(block);
        _fpa.ajax_working(block);

        // data-only-for allows hidden and other inputs to be blanked if the dependent
        // 'only-for' input is blank. This ensures the data is set only for the times when the
        // related data is a real value
        $(this).find('[data-only-for]').each(function(){
            var dof = $(this).attr('data-only-for');
            var all_null = true;
            $(dof).each(function(){
                var dofv = $(this).val();
                if(dofv !== null && dofv !== '') all_null = false;
            });

            if(all_null){
                $(this).removeClass('has-value').val('');

            }

        });

        return true;
    }).on('ajax:beforeSend', sel, function(ev, xhr){
        // Save the current AJAX request so that we have the opportunity to cancel it before it completes
        _fpa.remote_request = xhr;

    }).on("ajax:success", sel, function(e, data, status, xhr) {
        // Since the result was a success, reset the client-side session timeout counter
        // This is required, otherwise a user working on a single page application for an extended
        // period of time could get bounced out of the page because the client thinks they have timed out,
        // but their session is still valid and active after multiple AJAX requests
        _fpa.status.session.reset_timeout();
        var block = $(this);
        var data = xhr.responseJSON;
        _fpa.clear_flash_notices();
        _fpa.ajax_done(block);

        // Attempt an app-specific callback that a preprocessor may have created.
        // Typically used by special UI blocks that need to perform additional functions before the response
        // attempts to process
        _fpa.try_app_callback($(this));

        // If the result is JSON process the data
        // else, process the rendered HTML
        if(data){
            var t;
            var t_force;
            var use_target = false;
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

            if(data.multiple_results && data.original_item) {
                item_key = data.multiple_results;
                dataitem = data.original_item;
                target_data = {};

                target_data[dataitem.item_type] = dataitem;

            }
            else {
                for (item_key in data) break;

                if(alt_data_key){
                  data[alt_data_key] = data[item_key];
                  dataitem = data[alt_data_key];
                  // delete the original key, so we don't use it mistakenly elsewhere
                  delete data[item_key];
                }
                else {
                  dataitem = data[item_key];
                }
                target_data = data;
                // Ensure we use the target if there are multiple results specified, but no original item from a create or merge
                t_force = !!data.multiple_results;
            }

            var t_abs_force = false;
            if($(this).attr('data-result-target-force') === 'true')
                t_abs_force = true;

            // If a triggering block has the attribute data-result-target
            // decide if the rendered template should display where this attribute requests
            // We use the specified result-target if we get a _created or _merged response (when the request
            // is returning a result that is mostly likely different to that we would normally expect, such as an update returning a list of changed elements).
            // If no data-sub-item or data-sub-list is specified that matches a key in the reponse data, then we really have no other option but to position the result
            // where requested.
            // Finally if the results are 'multiple_results' but there was no original_item specified, then this a pure index. If there is a target, use it.
            if(t && (t_abs_force || t_force || dataitem===null || dataitem['_created'] || dataitem['_merged'] ||  $('[data-sub-item="'+item_key+'"], [data-sub-list="'+item_key+'"] [data-sub-item]').length===0 ))
                use_target = true;

            var options = {};
            if(use_target){

                // Check if a parent tells us to use a different target (a div around a form can force this to point to a specific location by putting the
                // target in the data-result-target-for-child attribute)
                var pt = $(this).parents('[data-result-target-for-child]').first();
                if(pt.length == 1)
                  t = pt.attr('data-result-target-for-child');
                // A specific target was specified an is being used.
                // Handle class markup that state whether to target this item directly, or add new elements above or below
                // the targeted element
                var b = $(t);
                if(b.hasClass('new-block')){
                    if(b.hasClass('new-after-parent'))
                        options.position = 'after parent';
                    else if(b.hasClass('new-before-parent'))
                      options.position = 'before parent';
                    else if(b.hasClass('new-below'))
                      options.position = 'after';
                    else
                      options.position = 'before';
                }
                // Since we may have specified multiple items to match the target, run through each in turn
                // making sure to use any specific templates they specify
                var default_tname = $(this).attr('data-template');

                b.each(function(){

                  // Render the template result using the data-template attribute name for the template
                  // It is possible that this request will be canceled within view_template, avoiding double-rendering of items.
                  // That said, if the view_template request completes fully, no subsequent processing will overwrite this block's contents
                  // (which can happen with complex interactions otherwise)
                  var tname = default_tname;
                  var alt_tname = $(this).attr('form-res-template');
                  if(alt_tname && alt_tname !== ''){
                    tname = alt_tname;
                  }

                  if(!tname)
                    console.log("Warning: data-template for this triggering element was not found");
                  _fpa.view_template($(this), tname, target_data, options);
                  _fpa.try_app_post_callback($(this));
                });
            }

            if(!t_abs_force){
                if(block.hasClass('new-block')){
                    block.html('');
                }
                // Run through the top level of data to pick the keys to look for in element subscriptions
                for(var di in data ){
                    if (data.hasOwnProperty(di)){
                        var res = {};
                        var d = data[di];

                        // DOM attribute targeting
                        // will only use the following targets
                        // Certain refinements to each of these are identified through additional markup, specified below
                        var targets = $('[data-sub-item="'+di+'"], [data-sub-list="'+di+'"] [data-sub-item], [data-item-class="'+di+'"]');

                        res[di] = d;
                        targets.each(function(){
                            var use_data = res;
                            var dsid = $(this).attr('data-sub-id');
                            var dst = $(this).attr('data-sub-item');
                            // data-item-class is used for activity logs that gain the step type in the data-sub-item, breaking the matching
                            // data-item-class is the plain class name
                            var dsc = $(this).attr('data-item-class');
                            if(dsid && (dst || dsc)){
                                use_data = null;
                                // Optionally use a different ID attribute (such as master_id) for the following listeners
                                var dsfor = $(this).attr('data-sub-for');
                                if(!dsfor) dsfor = 'id';

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
                                var dsforroot = $(this).attr('data-sub-for-root');
                                if(dsforroot){
                                    if(data[dsforroot]){
                                        item_data = data;
                                        // if the returned data has the specified attribute in its root
                                        // and also has the specified data-sub-item attribute
                                        if(item_data[dsforroot] === +dsid && item_data[dst]){
                                            use_data = {};
                                            use_data = item_data;
                                        }
                                    }
                                }else if(d && d[dsfor]){
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
                                    if(!matching_data_sub_item) matching_data_sub_item = item_data.item_type.underscore();
                                    if(item_data[dsfor] === +dsid){
                                      if(matching_data_sub_item === dst) {
                                        use_data = {};
                                        use_data[dst] = item_data;
                                      }
                                      else if(matching_data_sub_item === dsc) {
                                        use_data = {};
                                        use_data[dsc] = item_data;
                                        use_data[dst] = item_data;
                                      }
                                    }
                                }else if(d){
                                    // The least specific case is to run through the array of data elements, having
                                    // id or the attribute specified by data-sub-for, and seeing whether any
                                    // match the specified value
                                    // This is a simple case:
                                    // <div data-sub-item="player_contact" data-sub-id="456" ...>
                                    // which will match data like this:
                                    // {player_contact: {id: 456, <this data>}, player_info: {id: 888, <not this data>} }
                                    // and will pass just the matched item to the template
                                    for(var g in d){
                                        var item_data = d[g];
                                        if(item_data[dsfor] === +dsid && item_data.item_type === dst){
                                            use_data = {};
                                            use_data[dst] = item_data;
                                        }
                                    }
                                }
                            }

                            // We got a usable result, so display it (according to the rule that
                            // we can't overwrite a block previously processed in this request)
                            if(use_data){
                                var dt = $(this).attr('data-template');
                                _fpa.view_template($(this), dt, use_data);
                                _fpa.try_app_post_callback($(this));
                            }
                        });

                    }
                }
            }
        } else {

            // Since the results was basic HTML rendered by a partial typically, just push it into the
            // DOM where specified
            var html = $(xhr.responseText);
            $('.query-error').remove();
            var updated = 0;

            // Set up an array that can be used in preprocessor to assign data in postprocessors, etc.
            if(!data) data = {};

            var trigger = $(this);

            html.find('[data-result]').each(function(){
                var d = $(this);
                var di = d.attr('data-result');
                if(trigger.attr('data-target-force') === 'true'){
                  var t = trigger.attr('data-target');
                  if(!t || t === '')
                    console.log('Failed due to no data-target attribute being set when data-target-force is true and the result is an HTML block');
                  var targets = $(t);
                }
                else {
                  var targets = $('[data-subscription="'+di+'"]');
                  if(targets.length === 0)
                    console.log('WARN: [data-subscription="'+di+'"] returns no targets');
                }
                var res = {};
                res[di] = d;
                targets.each(function(){
                    var pre = $(this).attr('data-preprocessor');

                    _fpa.do_preprocessors(pre, $(this), data);
                    $(this).html(d);
                    _fpa.do_postprocessors(pre, $(this), data);
                    updated++;
                });

            });

            if(updated===0){
                var target = $(this).attr('data-result-target');
                if(target){
                    var pre = $(this).attr('data-preprocessor');

                    _fpa.do_preprocessors(pre, $(target), data);
                    $(target).html(html);
                    _fpa.do_postprocessors(pre, $(target), data);
                }
            }

        }
        $('.view-template-created').removeClass('view-template-created');


    }).on("ajax:error", function(e, xhr, status, error){
        var block = $(this);
        _fpa.clear_flash_notices();
        _fpa.ajax_done(block);

        var format_message = function(j){
            var msg = '';
            for(var i in j){
                if(j.hasOwnProperty(i)){
                  msg += '|' + i.replace(/_/g, ' ') + ' ' + j[i] + '|';
                }
            }

            return msg;
        }

        if(status!='abort'){

            var j = xhr.responseJSON;
            if(xhr.status === 422){
                if(j) {
                    var msg = "<p>Could not complete action:</p>";
                    msg += format_message(j);
                }
                else {
                    var msg = "<p>Could not complete action. Please <a href=\"#\" onclick=\"window.location.reload(); return false;\">refresh the page</a> and try again.</p>";
                }

                _fpa.flash_notice(msg, 'warning');
            }
            else {
                if(j) {
                    msg = format_message(j);
                    _fpa.flash_notice(msg, 'danger');
                }
                else if(xhr.responseText && xhr.responseText[0] != '<') {
                    _fpa.flash_notice(xhr.responseText, 'danger');
                }
                else {
                    _fpa.flash_notice("An error occurred.", 'danger');
                }
            }
        }

        _fpa.postprocessors.after_error(block, status, error);

        $('.ajax-running').removeClass('ajax-running');
    }).addClass('attached');

  },

  // Enable a long running ajax request to be canceled
  cancel_remote: function(){
    if(_fpa.remote_request){
        console.log("Cancel requested");

        _fpa.remote_request.abort();

        _fpa.ajax_canceled(_fpa.remote_request_block);
        _fpa.remote_request_block = null;
        _fpa.remote_request = null;
    }
  },



  // Display Rails style flash notices in response to Ajax events (or any other Javascript that wishes to use this mechanism)
  flash_notice: function(msg, type){
      if(!type) type = 'info';
      if(!msg || msg == '') return;
      var a = '<div class="alert alert-'+type+'" role="alert">';
      a += '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>';
      if(type == 'error' || type == 'danger'){
        var msg_safe = $('<div/>').text(msg).html();
        a += msg_safe.replace(/\n/g,'<br/>');
      }else
      {
        a += msg.replace(/\n/g,'<br/>');
      }
      a += '</div>';

      $('.flash').append(a);
      _fpa.timed_flash_fadeout();
  },

  timed_flash_fadeout: function(){
      window.setTimeout(function(){
          $('.alert-info').fadeOut(1000);
      }, 6000);
  },
  clear_flash_notices: function(type){
    if(!type)
        type = '';
    else
        type = '.alert-'+type;
    $('.flash div.alert'+type).remove();
  },


  // Show a bootstrap style modal dialog
  show_modal: function(message, title, large){

    var pm = $('#primary-modal');
    var t = pm.find('.modal-title');
    var m = pm.find('.modal-body');
    t.html('');
    m.html('');

    if(title) t.html(title);
    if(message) m.html(message);

    if(large)
        $('.modal-dialog').addClass('modal-lg');
    else
        $('.modal-dialog').removeClass('modal-lg');

    pm.modal('show');
  },

  get_item_by: function(attr, obj, evid){
    for(var pi in obj){
        if(obj.hasOwnProperty(pi)){
            var p = obj[pi];
            if(p[attr] == evid){

                return p;
            }
        }
    }
  }

};


_fpa.preprocessors = {};
_fpa.loaded = {};
