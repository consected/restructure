_fpa.cache = function(name){
    
    var res = localStorage.getItem(name);
    res = JSON.parse(res);
    return res;    
};

_fpa.set_cache = function(name, val){
    localStorage.removeItem(name);
    val = JSON.stringify(val);
    localStorage.setItem(name, val);
};