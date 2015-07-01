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