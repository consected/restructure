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
    $.ajax('/definitions/'+name).success(function(data){
        var res = data;
        _fpa.set_cache(name, res);
        from_cache = false;
        if(callback) callback();
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
  
  console.log("Got cache "+name+" from  cache? " + from_cache);
    
};

_fpa.set_cache = function(name, val){
    var basename = name + '--';
    name = _fpa.cache_name(name);
    
    // Force removal of previous versions of the cached item.
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