// To use cached localStorage provided by the browser, set to true
_fpa.use_cached_local_storage = true;

if(_fpa.use_cached_local_storage) {
  _fpa.local_storage = localStorage;
}
else {
  _fpa.local_storage = {};
}

_fpa.cache = function(name){
    name = _fpa.cache_name(name);
    if(_fpa.use_cached_local_storage) {
      var res = _fpa.local_storage.getItem(name);
      res = JSON.parse(res);
    }
    else {
      var res = _fpa.local_storage[name];
    }
    return res;
};

_fpa.cache_name = function(name){
    return name + '--' + _fpa.version;
};

_fpa.set_definition = function(name, callback){

  var from_cache = true;

  var get_def = function(name){
    console.log('Getting definition: ' + name);

    $.ajax('/definitions/'+name, {
      success: function(data){
        var res = data;
        _fpa.set_cache(name, res);
        from_cache = false;
        if(callback) callback();
      }
    });

  };

  try{
      var res = _fpa.cache(name);
      if(!res)
          get_def(name);
      else
          if(callback) callback();
  }
  catch(e){
      get_def(name);
  }

};

// Cache multiple definitions in a single request
_fpa.cache_definitions = function(names, callback){

  var from_cache = true;
  var str_names = names.join(",");
  var cache_name_defs = "multiple-defs-"+ str_names;

  var get_defs = function(names) {
    console.log('Getting definitions: ' + str_names);

    $.ajax('/definitions', {
      method: 'post',
      data: {
        names: str_names
      },
      success: function(data){

        for(var i in names) {
          var name = names[i];
          var res = data[name];
          _fpa.set_cache(name, res);
          from_cache = false;
          if(callback) callback();
        }

        _fpa.set_cache(cache_name_defs, 'true');

      }
    });

  };

  try{
      // Cache an item named with all the names to act as an indicator for whether this has been done already
      var res = _fpa.cache(cache_name_defs);
      if(!res)
          get_defs(names);
      else
          if(callback) callback();
  }
  catch(e){
      get_defs(names);
  }

};

_fpa.set_cache = function(name, val){

    if(typeof(name) != 'string') {
      throw('set_cache has name that is not a string: ' + name);
    }

    var basename = name + '--';
    name = _fpa.cache_name(name);

    // Force removal of previous versions of the cached item.
    // This must be done synchronously, otherwise the item downloaded in a moment is also removed
    for(var i in _fpa.local_storage){
      if(_fpa.local_storage.hasOwnProperty(i)){
        if(i.indexOf(basename)===0){
          if(_fpa.use_cached_local_storage) {
            _fpa.local_storage.removeItem(i);
          }
          else {
            delete(_fpa.local_storage[i]);
          }
          console.log("removed cache item: " +i);
        }
      }
    };

    if(_fpa.use_cached_local_storage) {
      val = JSON.stringify(val);
      _fpa.local_storage.setItem(name, val);
    }
    else {
      _fpa.local_storage[name] = val;
    }
    console.log("storing cache item: " + name );

};


_fpa.clean_cache = function(){

  if(!_fpa.version)
    return;

  for(var i in _fpa.local_storage){
    if(_fpa.local_storage.hasOwnProperty(i)){
      if(i.indexOf(_fpa.version) < 0 && (i.indexOf('general_selections-') == 0 || i.indexOf('multiple-defs-') == 0)){
        if(_fpa.use_cached_local_storage) {
          _fpa.local_storage.removeItem(i);
        }
        else {
          delete(_fpa.local_storage[i]);
        }
        console.log("cleaned old cache item: " +i);
      }
    }
  }
}
