_fpa.utils = {};
_fpa.utils.capitalize = function(str) {
    if(str != null && str.replace){
        var email_address_test = /.+@.+\..+/;
        var email_address = email_address_test.test(str);
        if(!email_address)
            return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
        else
            return str;
    }else{ 
        return str;
    }
};

_fpa.utils.nl2br = function(text){
    var nl2br = (text + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + '<br>' + '$2');
    return new Handlebars.SafeString(nl2br);
};

String.prototype.capitalize = function(){
    return _fpa.utils.capitalize(this);
};
_fpa.utils.is_blank = function(i){
  return (i === null || i === '');  
};

Date.prototype.asYMD = function(){
  
    var now = this;

    var day = ("0" + now.getDate()).slice(-2);
    var month = ("0" + (now.getMonth() + 1)).slice(-2);

    var today = now.getFullYear()+"-"+(month)+"-"+(day) ;
  
    return today;  
};

