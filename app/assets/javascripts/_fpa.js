_fpa = {
    
  templates: {},
  app: {},
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
        Handlebars.registerPartial(id, $(this).html());
    });

    $('script.handlebars-template').each(function(){
        var id = $(this).attr('id');
        var source = $(this).html();
        _fpa.templates[id] = Handlebars.compile(source);

    });

  },  
    
  view_template: function(block, template_name, data, options){    
    
    if(block.hasClass('view-template-created')) return;
      
    _fpa.ajax_working(block);
    if(!options || !options.position){        
        block.html('');
    }
    
    
    var template =_fpa.templates[template_name];

    if(!options) options = {};

    if(data.code){
      data._code_flag = {};
      data._code_flag[data.code] = true;
    }

    _fpa.do_preprocessors(template_name, block, data);                    

//    if(options.position)
//        data._created = true;

    var html = template(data);
    html = $(html).addClass('view-template-created');

    var new_block = block;

    if(options.position === 'before'){        
        new_block = html;
        var id = new_block.attr('id');
        var existing = $('#'+id);
        if(existing.length > 0){
            existing.replaceWith(new_block);
        }
        else{
            block.before(new_block);
        }
        block.html('');
    } else if(options.position === 'after'){        
        new_block = html;
        var id = new_block.attr('id');
        var existing = $('#'+id);
        if(existing.length > 0){
            existing.replaceWith(new_block);
        }
        else{
            block.after(new_block);
        }
        block.html('');
    }
    else
        block.html(html);
    
    window.setTimeout(function(){            
        _fpa.do_postprocessors(template_name, new_block, data);            
        _fpa.reset_page_size();
        _fpa.ajax_done(block);
    },1);
  },
          
  reset_page_size:function(){
    //var bh = $('body').height();
    //var hh = $('html').height();
    //if(bh < hh) $('body').height(hh);
  },
  
  inherit_from: function(original_prototype, new_t){
    function F() {}
    F.prototype = original_prototype;    
    $.extend(F.prototype, new_t);
    return F.prototype;
  },
          
 html_entity_map: {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': '&quot;',
    "'": '&#39;'
  },

  escape_html: function (string) {
    return String(string).replace(/[&<>"']/g, function (s) {
      return _fpa.html_entity_map[s];
    });
  },
  
  add_tracking_params: function(submitter){
      var id = submitter.prop('id');
        if(submitter.find('input').length > 0){
            if(submitter.find('input[name="_user_action"]').length === 0)
                submitter.append('<input type="hidden" name="_user_action" value="form:'+id+'"/>');
        }else{
            var p = submitter.prop('href');
            if(id)
                var msg = 'link_id:'+id;
            else
                var msg = 'link_class:'+submitter.attr('class'); 
            if(p.indexOf('?')>0)
                p = p+'&_user_action='+ encodeURIComponent(msg);              
            else
                p = p+'?_user_action='+encodeURIComponent(msg);
            submitter.prop('href', p);
        }
  },
  
  prevent_dup_clicks: function(block){
      var f = block.find('input[type="submit"]');
      if(f.length > 0){
          f.prop('disabled', true);          
          window.setTimeout(function(){
              f.prop('disabled', false);                            
          }, 1000);
      }
  },
  
  try_app_callback: function(el){
    if(el[0].app_callback){
        el[0].app_callback();
        el[0].app_callback = null;
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
  
  handle_remotes: function(){
    //var block = $("form[data-remote='true'], a[data-remote='true']").not('.attached');
    var sel = "form[data-remote='true'], a[data-remote='true']";
    // data-only-for allows hidden and other inputs to be blanked if the dependent
    // 'only-for' input is blank. This ensures the data is set only for the times when the
    // related data is a real value
    $(document).on('click', sel,  function(ev){
      
      _fpa.clear_flash_notices();
   
    }).on('ajax:before', sel, function(ev){
        var block = $(this);
        _fpa.remote_request = null;
        _fpa.remote_request_block = block;
        if($(this).hasClass('prevent-on-collapse') && !$(this).hasClass('collapsed')){
            ev.preventDefault();
            return false;
        }
        _fpa.preprocessors.before_all(block);
        //_fpa.prevent_dup_clicks($(this));
        
        _fpa.ajax_working(block);
        
        
        $(this).find('[data-only-for]').each(function(){
            var dof = $(this).attr('data-only-for');
            var all_null = true;
            $(dof).each(function(){
                var dofv = $(this).val();
                if(dofv !== null && dofv !== '') all_null = false;               
            });
            
            if(all_null)
                $(this).val('');
                
        });
        
        _fpa.add_tracking_params($(this));
        return true;
    }).on('ajax:beforeSend', sel, function(ev, xhr){        
        _fpa.remote_request = xhr;
        
    }).on("ajax:success", sel, function(e, data, status, xhr) {    
                
        
        _fpa.status.session.reset_timeout();
        var block = $(this);
        var data = xhr.responseJSON;
        _fpa.clear_flash_notices();
        _fpa.ajax_done(block);    
        
        _fpa.try_app_callback($(this));
        
        // If the result is JSON process the data
        // else, process the rendered HTML
        if(data){
            var t;
            var use_target = false;
            // Identify whether to target the results at a single dom element or to handle data subscriptions
            // Check the first entry in the returned data to see if the record indicates it was created
            // This will not show if a result set of multiple items is returned 
            // (whether the result of an index or a create that affected multiple items)
            // which is the desire effect, as multiple results must not be directed at a single DOM element
            // Results that were not newly created can be directed at the specified data-result-target if other data-sub-item
            // markup is not found for returned item.
            t = $(this).attr('data-result-target');
            var item_key;            
            var dataitem;           
            var target_data;
            if(data.multiple_results){
                item_key = data.multiple_results;
                dataitem = data['original_item'];
                target_data = {};
                target_data[dataitem.item_type] = dataitem;
                
            }else{                
                for (item_key in data) break;
                dataitem = data[item_key];
                target_data = data;
                
            }
            
            
            if(dataitem===null || dataitem['_created'] || dataitem['_merged'] ||  $('[data-sub-item="'+item_key+'"], [data-sub-list="'+item_key+'"] [data-sub-item]').length===0 )
                use_target = true;

            var options = {};                       
            if(t && use_target){
                // A specific target was specified an is being used.
                // Handle class markup that state whether to target this item directly, or add new elements above or below
                // the targeted element
                var b = $(t);
                if(b.hasClass('new-block')){
                    if(b.hasClass('new-below'))
                        options.position = 'after';
                    else    
                        options.position = 'before';
                }                                    
                _fpa.view_template(b, $(this).attr('data-template'), target_data, options);
            }
            
            {    
                if(block.hasClass('new-block')){
                    block.html('');
                }
                // Run through the top level of data to pick the keys to look for in element subscriptions
                for(var di in data ){
                    if (data.hasOwnProperty(di)){                        
                        var res = {};
                        var d = data[di];                        
                        
                        // Basic DOM attribute targeting
                        // just listen for for data having the top level item being equal to data-sub-item
                        // Typically this is used for forms, such as:
                        // data-sub-item="address-edit-form-100001-"
                        // where the form partial returns 
                        var targets = $('[data-sub-item="'+di+'"], [data-sub-list="'+di+'"] [data-sub-item]');
                                                                        
                        res[di] = d;
                        targets.each(function(){      
                            var use_data = res;
                            var dsid = $(this).attr('data-sub-id');
                            var dst = $(this).attr('data-sub-item');
                            if(dsid && dst){
                                use_data = null;
                                // Optionally use a different ID attribute (such as master_id)
                                var dsfor = $(this).attr('data-sub-for');
                                if(!dsfor) dsfor = 'id';
                                
                                var dsforroot = $(this).attr('data-sub-for-root');
                                // Check if we should be looking in the root of the data, rather than in the items
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
                                }else if(d[dsfor]){
                                    // We should be looking in the only actual data element
                                    item_data = d;
                                    if(item_data[dsfor] === +dsid && item_data.item_type === dst){
                                        use_data = {};
                                        use_data[dst] = item_data;                    
                                    }
                                }else{
                                    // Run through the array of data elements
                                    for(var g in d){
                                        var item_data = d[g];
                                        if(item_data[dsfor] === +dsid && item_data.item_type === dst){
                                            use_data = {};
                                            use_data[dst] = item_data;                    
                                        }
                                    }
                                }
                            }
                            if(use_data){
                                var dt = $(this).attr('data-template');                            
                                _fpa.view_template($(this), dt, use_data);                                              
                            }
                        });              
                                                
                    }
                }                
            }
        } else {
            var html = $(xhr.responseText);
            $('.query-error').remove();
            html.find('[data-result]').each(function(){
                var d = $(this);
                var di = d.attr('data-result');
                var targets = $('[data-subscription="'+di+'"]');
                var res = {};
                res[di] = d;
                targets.each(function(){
                    var pre = $(this).attr('data-preprocessor');                    
  
                    _fpa.do_preprocessors(pre, $(this), data);
                    $(this).html(d);                    
                    _fpa.do_postprocessors(pre, $(this), data);
                    
                });

            });
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
                  msg += '<p>' + i.replace(/_/g, ' ') + ' ' + j[i] + '</p>';
                }                
            }
            
            return msg;
        }
        
        if(status!='abort'){
        
            var j = xhr.responseJSON;
            if(xhr.status === 422){
                if(j){
                    var msg = "<p>Could not complete action:</p>";
                    msg += format_message(j);
                }else{
                    var msg = "<p>Could not complete action. Please <a href=\"#\" onclick=\"window.location.reload(); return false;\">refresh the page</a> and try again.</p>";
                }

                _fpa.flash_notice(msg, 'warning');
            }else{
                
                if(j){
                    msg = format_message(j);
                    _fpa.flash_notice(msg, 'danger');
                }else if(xhr.responseText && xhr.responseText[0] != '<'){
                    _fpa.flash_notice(xhr.responseText, 'danger');
                }else{
                    _fpa.flash_notice("An error occurred.", 'danger');
                }
            }
        }
        
        _fpa.postprocessors.after_error(block, status, error);
        
        $('.ajax-running').removeClass('ajax-running');
    }).addClass('attached');      
    
  },
  
  cancel_remote: function(){
    if(_fpa.remote_request){
        console.log("Cancel requested");
        
        _fpa.remote_request.abort();
        
        _fpa.ajax_canceled(_fpa.remote_request_block);
        _fpa.remote_request_block = null;
        _fpa.remote_request = null;
    }
  },
  
  flash_notice: function(msg, type){
      if(!type) type = 'info';
      
      var a = '<div class="alert alert-'+type+'" role="alert">';
      a += '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>';
      a += msg;
      a += '</div>';
      
      $('.flash').append(a);
      _fpa.timed_flash_fadeout();      
  },
  
  timed_flash_fadeout: function(){
      window.setTimeout(function(){
          $('.alert-info').fadeOut(1000);
      }, 2000);
  },
  clear_flash_notices: function(type){
    if(!type)
        type = '';
    else
        type = '.alert-'+type;
    $('.flash div.alert'+type).remove();
  },

  show_modal: function(message, title){
    
    var pm = $('#primary-modal');  
    var t = pm.find('.modal-title');
    var m = pm.find('.modal-body');
    t.html('');
    m.html('');
    
    if(title) t.html(title);
    if(message) m.html(message);
    
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


