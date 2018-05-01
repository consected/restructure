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
    eR.add('includes', function(left, right) {
      if(!left) return;
      var re = new RegExp(right);
      return left.search(right) !== -1;
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

    // if all are true
    // From: https://stackoverflow.com/a/14840042/483133
    Handlebars.registerHelper('if_all', function() {
        var args = [].slice.apply(arguments);
        var opts = args.pop();

        var fn = opts.fn;
        for(var i = 0; i < args.length; ++i) {
            if(args[i])
                continue;
            fn = opts.inverse;
            break;
        }
        return fn(this);
    });

    // Replace instance(s) of replace_str in orig_str, with with_str.
    // re_options represents zero or more standard regex options
    //   g: replace all
    //   i: case insensitive
    //   etc
    Handlebars.registerHelper('replace', function(orig_str, replace_str, with_str, re_options, context){
      var reo;
      // Avoid using the context object if the last option was excluded from the call
      if(!re_options.hasOwnProperty('name'))
        reo = re_options;
      var re = new RegExp(replace_str, reo);
      return orig_str.replace(re, with_str);
    });

    Handlebars.registerHelper('was', function(obj, options){
        if(obj || obj === 0)
            return options.fn(this);
        else
            return options.inverse(this);
    });

    Handlebars.registerHelper('has', function(obj, options){
        if(this.hasOwnProperty(obj))
            return options.fn(this);
        else
            return options.inverse(this);
    });


    Handlebars.registerHelper('includes', function(obj, inc){
      if(!obj) return;
      var re = new RegExp(inc);
      return obj.search(inc) !== -1;
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

    Handlebars.registerHelper('timestamp', function(text) {
      if(text){
        return _fpa.utils.ISOdatetoTimestamp(text);
      }
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


    Handlebars.registerHelper('format_10_digit_external_id', function(text) {
        text = "" + text; // force text type
        var d = text.substring(0,3) + ' ' + text.substring(3,6) + ' ' + text.substring(6,10);
        return new Handlebars.SafeString(d);
    });

    Handlebars.registerHelper('fpa_state_item', function(name, key) {
        var res = _fpa.state[name];
        if(res && key)
          res = res[key];
        return res;
    });

    Handlebars.registerHelper('pad_start', function(value, num, padstr) {
        return String(value).padStart(num, padstr);
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

        // Using information from https://bugzilla.mozilla.org/show_bug.cgi?id=1139167 to prevent occasional day difference issues
        return new Date(startTime).toLocaleDateString(undefined, {timeZone: "UTC"});


    });

    Handlebars.registerHelper('underscore', function(stre, options) {
        if(!stre) return null;
        return stre.toLowerCase().replace(/ /g, '_');
    });

    Handlebars.registerHelper('pretty_string', function(stre, options) {
        if(options && !options.hash) options.hash = {};
        return _fpa.utils.pretty_print(stre, options.hash);
    });


    Handlebars.registerHelper('local_time', function(stre, options) {
        if(!stre) return;
        if(options && !options.hash) options.hash = {};
        return new Date(stre.toString()).toLocaleTimeString('en-US', {hour: 'numeric', minute: '2-digit'});
    });


    Handlebars.registerHelper('capitalize', function(str){
      return _fpa.utils.capitalize(str);
    });

    Handlebars.registerHelper('hyphenate', function(str){
      if(!str) return;
      return str.hyphenate();
    });

    Handlebars.registerHelper('pathify', function(str){
      if(!str) return;
      return str.pathify();
    });


    Handlebars.registerHelper('pluralize', function(str){
      if(!str) return;
      if(str[str.length - 1] == 'y')
        return str.substring(0, str.length - 1) + 'ies';
      return str + 's';
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

     obj = _fpa.utils.translate(obj, 'field_labels');

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
