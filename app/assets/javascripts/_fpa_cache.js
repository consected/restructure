_fpa.cache = function(name){
    name += _fpa.version;
    var res = localStorage.getItem(name);
    res = JSON.parse(res);
    return res;    
};

_fpa.set_definition = function(name){
  
  var get_def = function(name){
    $.ajax('/definitions/'+name).success(function(data){
        var res = data;
        _fpa.set_cache(name, res);
    });
  
  };
  
  try{
      var res = _fpa.cache(name);
      if(!res)
          get_def(name);
  }
  catch(e){
      get_def(name);
  }
    
};

_fpa.set_cache = function(name, val){
    name += _fpa.version;
    localStorage.removeItem(name);
    val = JSON.stringify(val);
    localStorage.setItem(name, val);
};