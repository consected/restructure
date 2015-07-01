_fpa = {
    setup_typeahead: function(element, list, name){
      
      if(typeof list === 'string')  
        list = _fpa.cache(list);  
        
      var items = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,        
        local: list
      });

      $(element).typeahead({
        hint: true,
        highlight: true,
        minLength: 1,
        autoselect: true
      },
      {
        name: name,
        source: items
      });
  },
  ajax_working: function(block){

    $(block).addClass('ajax-running');
  },
  ajax_done: function(block){  
    $(block).removeClass('ajax-running');
  },
          
  view_template: function(block, template_name, data, options){    
    
    
    _fpa.ajax_working(block);
    if(!options || !options.position){        
        block.html('');
    }
    
    
    
    
    
    window.setTimeout(function(){  
    var source = $('#'+template_name).html();
    var template = Handlebars.compile(source);
    
    if(!options) options = {};
    
    if(data.code){
      data._code_flag = {};
      data._code_flag[data.code] = true;
    }
    _fpa.preprocessors.default(block, data);
    if(_fpa.preprocessors[template_name])
        _fpa.preprocessors[template_name](block, data);
    
    if(options.position)
        data._created = true;
      
    var html = template(data);
    
    if(options.position === 'before'){        
        block.before(html);
        block.html('');
    }
    else
        block.html(html);
    _fpa.postprocessors.default(block, data);
    if(_fpa.postprocessors[template_name])
        _fpa.postprocessors[template_name](block, data);
    
    _fpa.handle_remotes();
    _fpa.reset_page_size();
    _fpa.ajax_done(block);
    }, 10);
  },
          
  reset_page_size:function(){
    var bh = $('body').height();
    var hh = $('html').height();
    if(bh < hh) $('body').height(hh);
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
  
  handle_remotes: function(){
    var block = $("form[data-remote='true'], a[data-remote='true']").not('.attached');
    
    // data-only-for allows hidden and other inputs to be blanked if the dependent
    // 'only-for' input is blank. This ensures the data is set only for the times when the
    // related data is a real value
    block.on('click', function(ev){
      
      _fpa.clear_flash_notices();
   
    }).on('ajax:before', function(ev){
        if($(this).hasClass('prevent-on-collapse') && !$(this).hasClass('collapsed')){
            ev.preventDefault();
            return false;
        }
        
        _fpa.prevent_dup_clicks($(this));
        
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
    }).on("ajax:success", function(e, data, status, xhr) {    
        var data = xhr.responseJSON;
        _fpa.clear_flash_notices();
        _fpa.ajax_done(block);    
        if(xhr.responseJSON){
            var t = $(this).attr('data-result-target');
            var options = {}
            if(t){
                var b = $(t);
                if(b.hasClass('new-block')){
                    options.position = 'before';
                }                    
                _fpa.view_template(b, $(this).attr('data-template'), xhr.responseJSON, options);
            }else{
                for(var di in data ){
                    if (data.hasOwnProperty(di)){
                        var d = data[di];
                        var targets = $('[data-subscription="'+di+'"]');
                        var res = {};
                        res[di] = d;
                        targets.each(function(){                                                        
                            _fpa.view_template($(this), $(this).attr('data-template'), res);                  
                        });              
                        window.setTimeout(function(){_fpa.handle_remotes();},1);
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
                    _fpa.preprocessors.default($(this), data);
                    if(_fpa.preprocessors[pre])
                        _fpa.preprocessors[pre](block, data);
                    $(this).html(d);
                    _fpa.postprocessors.default($(this), data);
                    if(_fpa.postprocessors[pre])
                        _fpa.postprocessors[pre](block, data);
                    window.setTimeout(function(){_fpa.handle_remotes();},1);
                });

            });
        }
        
        
    }).on("ajax:error", function(e, xhr, status, error){
      _fpa.clear_flash_notices();
      _fpa.ajax_done(block);
      _fpa.flash_notice("An error occurred.", 'danger');
      
    }).addClass('attached');


    
      
    
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
  }

};

_fpa.callbacks = {
  
  loaded: function(block, data){
    if(!this.loaded_callbacks) this.loaded_callbacks = [];
    
    for(var lc in this.loaded_callbacks){
      if(this.loaded_callbacks.hasOwnProperty(lc)){
        var lcs = this.loaded_callbacks[lc];
        window.setTimeout(function(){
          lcs(block, data);
        },1);
      }      
    }
  },
  
  add_loaded_callback: function(f){
    if(!this.loaded_callbacks) this.loaded_callbacks = [];
    this.loaded_callbacks.push(f);
  },
  remove_last_loaded_callback:  function(f){
    this.loaded_callbacks.pop();
  },
  reset_loaded_callbacks:  function(f){
    this.loaded_callbacks = [];
  },        
  
  do_ajax_request: function (options, cb_success, cb_fail, cb_always) {        
    $.ajax(options).done(
      function(data){
        if(!data || data.code && data.code != 'OK'){
          if(cb_fail) cb_fail(data);
          return null;
        }      
        if(cb_success) cb_success(data);      
      }).fail(function(data){
        if(cb_fail) cb_fail(data);
      }).always(function(){
        if(cb_always) cb_always(data);
      });
  },
  
  get_data: function(url, cb_success, cb_fail, cb_always){        
    this.do_ajax_request({url: url}, cb_success, cb_fail, cb_always);
  }
  
};

_fpa.preprocessors = {};
_fpa.loaded = {};

$('html').ready(function(){
  _fpa.reset_page_size();  
  
  $(document).on('click', 'a.view-image-modal', function(ev){
    ev.preventDefault;    
    var v = $('#view-image-modal');
    v.find('.modal-title').html('View Image');
    var src = $(this).attr('data-img-src');
    v.find('.modal-body').html('<img src="'+src+'" class="img img-responsive center center-block"/>');
    
  });
  
  $(function () {
    $('[data-toggle="tooltip"]').tooltip();    
    $('[data-toggle="popover"]').popover();
    $('[data-show-popover="auto"]').popover('show');
  });
  
  _fpa.handle_remotes();
  _fpa.loaded.default();
});
