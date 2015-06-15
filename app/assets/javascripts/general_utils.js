_fpa.utils = {};
_fpa.utils.capitalize = function(str) {
    if(str != null && str.replace)
        return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
    else 
        return str;
};