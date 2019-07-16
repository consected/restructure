_fpa.cache = function(name){
    name = _fpa.cache_name(name);
    var res = localStorage.getItem(name);
    res = JSON.parse(res);
    return res;
};

_fpa.cache_name = function(name){
    return name + '--' + _fpa.version;
};

_fpa.set_definition = function(name, callback){

  var from_cache = true;

  var get_def = function(name){
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

  var get_defs = function(names) {

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

        _fpa.set_cache(str_names, 'true');

      }
    });

  };

  try{
      // Cache an item named with all the names to act as an indicator for whether this has been done already
      var res = _fpa.cache(str_names);
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
    var basename = name + '--';
    name = _fpa.cache_name(name);

    // Force removal of previous versions of the cached item.
    // This must be done synchronously, otherwise the item downloaded in a moment is also removed
    for(var i in localStorage){
      if(localStorage.hasOwnProperty(i)){
        if(i.indexOf(basename)===0){
          localStorage.removeItem(i);
          console.log("removed cache item: " +i);
        }
      }
    };

    val = JSON.stringify(val);
    localStorage.setItem(name, val);
};
