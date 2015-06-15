// Display date in local format, without adjusting the timezone and giving the appearance of changing the day
Handlebars.registerHelper('local_date', function(date_string, unknown, options) {
    if(date_string === null || date_string === '' ) return unknown;
    var startTime = new Date(Date.parse(date_string + 'T00:00:00Z'));
    
    if((!startTime || startTime == 'Invalid Date') && options.hash.return_string)
        return date_string;
    
    startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
    return startTime.toLocaleDateString();
});


Handlebars.registerHelper('pretty_string', function(stre, options) {
    if(stre === null || stre === '' ) return "";
    
    if(stre.length >= 8)
        var startTime = new Date(Date.parse(stre + 'T00:00:00Z'));
    
    if((!startTime || startTime == 'Invalid Date' ) && options.hash.return_string){
        if(options.hash.capitalize)
            return _fpa.utils.capitalize(stre);
        else
            return stre;
    }
    
    startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
    return startTime.toLocaleDateString();
});


Handlebars.registerHelper('capitalize', function(str){
  return _fpa.utils.capitalize(str);
});


Handlebars.registerHelper('one_decimal', function(num){
  return num.toFixed(1);
});

Handlebars.registerHelper('pretty_print', function(obj) {
 return JSON.stringify(obj, null, 2);
});

Handlebars.registerHelper('humanize', function(obj) {
    
 return obj.replace('_', ' ');
});

Handlebars.registerHelper('in', function(context, key, items, options) {
  
  var ins = items.split(',');
  
  
  if(ins.indexOf(key) >= 0)
    return options.fn(context);
  else
    return options.inverse(context);
  
  
});

