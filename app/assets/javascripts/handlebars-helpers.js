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
        var nl2br = (text + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + '<br>' + '$2');
        return new Handlebars.SafeString(nl2br);
    });


    Handlebars.registerHelper('date_time', function(text) {
      var ds = new Date();
      var d = ds.toLocaleString();
        return new Handlebars.SafeString(d);
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


    // Display date in local format, without adjusting the timezone and giving the appearance of changing the day
    Handlebars.registerHelper('local_date', function(date_string, unknown, options) {
        if(date_string === null || date_string === '' ) return unknown;
        var startTime = new Date(Date.parse(date_string + 'T00:00:00Z'));

        if(!startTime || startTime == 'Invalid Date'){
            if(options.hash.return_string)
                return date_string;
            else
                return unknown;
        }
            

        startTime =   new Date( startTime.getTime() + ( startTime.getTimezoneOffset() * 60000 ) );
        return startTime.toLocaleDateString();
    });


    Handlebars.registerHelper('pretty_string', function(stre, options) {
        if(stre === null || stre === '' ) return "";
        var startTime;
        var asTimestamp;
        if(stre.length >= 8){
            if(stre.indexOf('t') && stre.indexOf('z')){
                startTime = new Date(Date.parse(stre ));
                asTimestamp = true;
            }
            else{
                startTime = new Date(Date.parse(stre + 'T00:00:00Z'));
                asTimestamp = false;
            }
        }
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








    return eR;

}));




