_fpa.masker = {};

// Create a jQuery mask from a HTML5 input pattern attribute
_fpa.masker.mask_from_pattern = function(p) {

  var m = '';
  var s = '';
  var v = '';
  var vopt = '';
  var vrec = '';
  var reverse = false;
  var opt_block = false;
  var opt_follow = false;
  var re_curl = /^\{(\d+),?(\d*)?\}/
  var re_opt_block = /^\(.+\)\?/
  for(var i = 0; i < p.length ; i++){
    var c = p[i];
    if(s !== 'escape') {
      if(c === '.') {
        s = 'char';
        v = 'W';
        vopt = 'X';
        vrec = 'Y';
      }
      else if(c === '\\') {
        s = 'escape';
      }
      else if(c === '(') {
        s = 'startblock';
        if(p.substring(i).match(re_opt_block))
          opt_block = true
      }
      else if(opt_block && c === ')') {
        s = 'endblock';
      }
      else if(opt_block && c === '?') {
        s = 'endopt';
        opt_block = false
      }
      else if(c === '+') {
        s = 'char';
        opt_follow = true;
        if(prev_vopt === 'T' )
          vopt = 'U';
        else if(prev_vopt === 'B' )
            vopt = 'D';
        else if(prev_vopt === '9' )
            vopt = '#';

        v = vopt;
      }
      else if(c === '*') {
        s = 'char';
        opt_follow = true;
        if(prev_vopt === 'T' )
          vopt = 'R';
        else if(prev_vopt === 'B' )
            vopt = 'C';
        else if(prev_vopt === '9' )
            vopt = '*';

        v = vopt;
      }
      else {
        s = 'char';
        v = c;
        vopt = c;
      }
    }
    else if(s === 'escape') {
      if(c === 'd') {
        s = 'char';
        v = '0';
        vopt = '9';
        vrec = '*';
        reverse = true;
      }
      else if(c === 'D') {
        s = 'char';
        v = 'S';
        vopt = 'T';
        vrec = 'R';
      }
      else {
        s = 'char';
        v = c;
        vopt = c;
      }
    }


    var r = p.substring(i+1).match(re_curl)
    if(s === 'char') {
      times = 1;
      opttimes = 0;
      recursive = 0;
      if (r) {
        r1 = r[1];
        r2 = r[2];
        if(r1 && r[0].indexOf(',') < 0){
          times = parseInt(r1);
        }
        else if(r1 && !r2){
          // Have a comma indicating no max limit
          times = parseInt(r1);
          recursive = 1;
        }

        if(r1 === '0' && r2){
          opttimes = parseInt(r2);
          times = 0;
        }
        if(r1 !== '0' && r2){
          times = parseInt(r1);
          opttimes = parseInt(r2) - parseInt(r1);
        }

        i += r[0].length;
      }

      if(!reverse){
        for(var j = 0; j < times; j++) {
          if(!opt_block)
            m += v;
          else
            m += vopt;
        }

        for(var j = 0; j < opttimes; j++) {
          m += vopt;
        }

        if(recursive)
          m += vrec;
      }
      else {
        if(recursive)
          m += vrec;

        for(var j = 0; j < times; j++) {
          if(!opt_block)
          m += v;
          else
          m += vopt;
        }
        for(var j = 0; j < opttimes; j++) {
          m += vopt;
        }
      }
      prev_s = s;
      prev_v = v;
      prev_vopt = vopt;
      s = '';
      v = '';
      vopt = '';
    }

  }
  return {mask: m, reverse: false, translation: _fpa.masker.translation};
}


_fpa.masker.translation = {
  '0': {pattern: /\d/},
  '9': {pattern: /\d/, optional: true},
  '#': {pattern: /\d/, recursive: true},
  '*': {pattern: /\d/, optional: true, recursive: true},
  'A': {pattern: /[a-zA-Z0-9]/},
  'B': {pattern: /[a-zA-Z0-9]/, optional: true},
  'C': {pattern: /[a-zA-Z0-9]/, optional: true, recursive: true},
  'D': {pattern: /[a-zA-Z0-9]/, recursive: true},
  'S': {pattern: /[a-zA-Z]/},
  'T': {pattern: /[a-zA-Z]/, optional: true},
  'R': {pattern: /[a-zA-Z]/, optional: true, recursive: true},
  'U': {pattern: /[a-zA-Z]/, recursive: true},
  'W': {pattern: /./},
  'X': {pattern: /./, optional: true},
  'Y': {pattern: /./, optional: true, recursive: true},
  'Z': {pattern: /./, recursive: true},

};
