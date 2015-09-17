_fpa.cache = function(name){
    name += _fpa.version;
    var res = localStorage.getItem(name);
    res = JSON.parse(res);
    return res;    
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
    name += _fpa.version;
    localStorage.removeItem(name);
    val = JSON.stringify(val);
    localStorage.setItem(name, val);
};