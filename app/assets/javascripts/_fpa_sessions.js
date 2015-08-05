_fpa.session = function(timeout) {
    if(!timeout) return;
    this.default_timeout = timeout + this.tick/1000;
    this.start_counting(true);
    
    return this;
};

_fpa.session.prototype = {
    
  default_timeout: null,
  last_reset: null,
  tick: 10000,
  
  time_now: function(){
    return (new Date().getTime()) / 1000;
  },
  
  reset_timeout: function(){
        console.log("reset_timeout to "+this.default_timeout + ' seconds');
        window.localStorage.setItem('session_last_reset', this.time_now());
  },
  
  start_counting: function(reset){
      if(reset) this.reset_timeout();
      var self = this;
      window.setTimeout(function(){
          self.count_down()
      }, this.tick);
  },
  
  count_down: function(){
      var timeout_in = this.time_passed();
      console.log("timeout in: "+ timeout_in +" :: default timeout: " + this.default_timeout);
      if(timeout_in > this.default_timeout){
          console.log("timed out!");
          window.location.href="/";
      }else{
        this.start_counting();
      };
  },
  
  time_passed: function(){
      var tlr = window.localStorage.getItem('session_last_reset');
      if(!tlr) 
          tlr = 0;
      else
          tlr = parseInt(tlr);
      var t = this.time_now() - tlr;
      return t;
  }
    
};