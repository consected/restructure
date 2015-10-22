(function (root, factory) {
    if (typeof exports === 'object') {
        module.exports = factory(require('handlebars'));
    } else if (typeof define === 'function' && define.amd) {
        define(['handlebars'], factory);
    } else {
        root.HandlebarsHelpersRegistry = factory(root.Handlebars);
    }
}(this, function (Handlebars) {

    var isArray = function(value) {
        return Object.prototype.toString.call(value) === '[object Array]';
    };

    var ExpressionRegistry = function() {
        this.expressions = [];
    };

    ExpressionRegistry.prototype.add = function (operator, method) {
        this.expressions[operator] = method;
    };

    ExpressionRegistry.prototype.call = function (operator, left, right) {
        if ( ! this.expressions.hasOwnProperty(operator)) {
            throw new Error('Unknown operator "'+operator+'"');
        }

        return this.expressions[operator](left, right);
    };

    var eR = new ExpressionRegistry;
    eR.add('not', function(left, right) {
        return left != right;
    });
    eR.add('>', function(left, right) {
        return left > right;
    });
    eR.add('<', function(left, right) {
        return left < right;
    });
    eR.add('>=', function(left, right) {
        return left >= right;
    });
    eR.add('<=', function(left, right) {
        return left <= right;
    });
    eR.add('===', function(left, right) {
        return left === right;
    });
    eR.add('!==', function(left, right) {
        return left !== right;
    });
    eR.add('in', function(left, right) {
        if ( ! isArray(right)) {
            right = right.split(',');
        }
        return right.indexOf(left) !== -1;
    });
    

    var isHelper = function() {
        var args = arguments
        ,   left = args[0]
        ,   operator = args[1]
        ,   right = args[2]
        ,   options = args[3]
        ;

        if (args.length == 2) {
            options = args[1];
            if (left) return options.fn(this);
            return options.inverse(this);
        }

        if (args.length == 3) {
            right = args[1];
            options = args[2];
            if (left == right) return options.fn(this);
            return options.inverse(this);
        }

        if (eR.call(operator, left, right)) {
            return options.fn(this);
        }
        return options.inverse(this);
    };
    
    
    var containsHelper = function (str, pattern, options) {
      if (str && str.indexOf(pattern) !== -1) {
        return options.fn(this);
      }
      return options.inverse(this);
    };



    Handlebars.registerHelper('is', isHelper);

    Handlebars.registerHelper('contains', containsHelper);

    Handlebars.registerHelper('split', function(obj, el){
      var res = '';
      if(!obj) return res;
      for(var i in obj){
        res += '<'+el+'>'+obj[i]+'</'+el+'>'; 
      }
      return res;
    });

    Handlebars.registerHelper('was', function(obj, options){
        if(obj || obj === 0)
            return options.fn(this);
        else
            return options.inverse(this);
    });


    Handlebars.registerHelper('includes', function(obj, inc){
      if(!obj) return null;
      return (obj.indexOf(inc) >= 0);
    });

    Handlebars.registerHelper('with_content',function(name, type, context, options){
        return with_content(name, type, context, options);
    });

    Handlebars.registerHelper('stringify',function(obj){
        return JSON.stringify(obj, undefined, 4);
    });

    Handlebars.registerHelper('plain_object',function(obj){
      return obj;
    });

    Handlebars.registerHelper('nl2br', function(text) {
        return _fpa.utils.nl2br(text);
    });


    Handlebars.registerHelper('date_time', function(text) {
        if(text){
            var ds = new Date(Date.parse(text));
            var d = ds.toLocaleString();
            return new Handlebars.SafeString(d);            
        }else{
            var ds = new Date();
            var d = ds.toLocaleString();
            return new Handlebars.SafeString(d);
        }
    });


    Handlebars.registerHelper('format_sage_id', function(text) {
        var d = text.substring(0,3) + ' ' + text.substring(3,6) + ' ' + text.substring(6,10)
        return new Handlebars.SafeString(d);
    });
    
    Handlebars.registerHelper('simple_log', function(t) {
        console.log(t);        
    });
    
    Handlebars.registerHelper('log', function() {
        console.log(['Values:'].concat(
            Array.prototype.slice.call(arguments, 0, -1)
        ));
    });

    Handlebars.registerHelper('debug', function() {
        console.log('Context:', this);
        console.log(['Values:'].concat(
            Array.prototype.slice.call(arguments, 0, -1)
        ));
    });


    Handlebars.registerHelper('filter', function(array, items, options) {
        var item, result, _i, _len;
        result = '';
        var ins = items.split(',');

        
        for (_i = 0, _len = ins.length; _i < _len; _i++) {
          item = array[ins[_i]];
          result += options.fn(item, {data: {key: ins[_i]}});
        }

        return result;
    });

    // Display date in local format, without adjusting the timezone and giving the appearance of changing the day
    Handlebars.registerHelper('local_date', function(date_string, unknown, options) {
        if(date_string === null || date_string === '' ) return unknown;
        var startTime = date_string; //
        var testTime = new Date(Date.parse(date_string + 'T00:00:00Z'));
        

        if(!testTime || testTime == 'Invalid Date'){
            if(options.hash.return_string)
                return date_string;
            else
                return unknown;
        }
            

       // startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
        //return startTime.toLocaleDateString();
        
        // Using information from https://bugzilla.mozilla.org/show_bug.cgi?id=1139167 to prevent occasional day difference issues
        return new Date(startTime).toLocaleDateString(undefined, {timeZone: "UTC"});
        
        
    });

    Handlebars.registerHelper('underscore', function(stre, options) {
        if(!stre) return null;
        return stre.toLowerCase().replace(/ /g, '_');
    });

    Handlebars.registerHelper('pretty_string', function(stre, options) {
        if(stre === null || stre === '' ) return "";
        var startTime;
        var asTimestamp;
        if(stre && stre.length >= 8){
            if (!stre.match(/^\d\d\d\d-\d\d-\d\d.*/)){
            }else if((stre.indexOf('t')>=0 && stre.indexOf('z')>=0) || (stre.indexOf('T')>=0 && stre.indexOf('Z')>=0)){
                startTime = new Date(Date.parse(stre ));
                asTimestamp = true;
            }
            else{
                startTime = new Date(Date.parse(stre + 'T00:00:00Z'));
                asTimestamp = false;
            }
        }
        if(typeof startTime === 'undefined' || !startTime || startTime == 'Invalid Date'){
            if(options.hash.return_string){
                if(options.hash.capitalize){
                    if(!stre || stre.length < 30){
                        //stre = Handlebars.Utils.escapeExpression(stre);
                        return _fpa.utils.capitalize(stre);
                    }else{
                        return _fpa.utils.nl2br(stre);
                    }
                }
                else{
                    return _fpa.utils.nl2br(stre);
                }
            } else {
                return null;
            }
        }
        if(asTimestamp){
            startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
            return startTime.toLocaleDateString();
        } else {
            return new Date(stre).toLocaleDateString(undefined, {timeZone: "UTC"});
        }
        
        return stre;
    });


    Handlebars.registerHelper('capitalize', function(str){
      return _fpa.utils.capitalize(str);
    });

    Handlebars.registerHelper('hyphenate', function(str){
      if(!str) return;
      return str.replace(/_+/g, '-');
    });


    Handlebars.registerHelper('one_decimal', function(num){
      return num.toFixed(1);
    });

    Handlebars.registerHelper('pretty_print', function(obj) {
     return JSON.stringify(obj, null, 2);
    });
    
    Handlebars.registerHelper('pretty_print_html', function(obj) {
     return JSON.stringify(obj, null, '<div>  ');
    });
    
    Handlebars.registerHelper('humanize', function(obj) {
     if(!obj) return;
     return obj.replace(/_/g, ' ');
    });

    Handlebars.registerHelper('in', function(context, key, items, options) {

      var ins = items.split(',');


      if(ins.indexOf(key) >= 0)
        return options.fn(context);
      else
        return options.inverse(context);


    });








    return eR;

}));




