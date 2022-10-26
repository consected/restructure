_fpa.session = function (timeout) {
  if (!timeout) return;
  this.default_timeout = timeout + this.tick / 1000;
  this.start_counting(true);

  return this;
};

_fpa.session.prototype = {

  default_timeout: null,
  last_reset: null,
  tick: 10000,
  alarm_time: 120,
  alarmed: null,

  time_now: function () {
    return (new Date().getTime()) / 1000;
  },

  alarm_bell: function () {
    var timeout_in = this.time_passed();
    var res = timeout_in > (this.default_timeout - this.alarm_time) && !this.alarmed;
    if (res) this.alarmed = true;
    return res;
  },

  reset_timeout: function () {
    // console.log("reset_timeout to "+this.default_timeout + ' seconds');
    window.localStorage.setItem('session_last_reset', this.time_now());
    this.alarmed = null;
  },

  start_counting: function (reset) {
    if (reset) this.reset_timeout();
    var self = this;
    window.setTimeout(function () {
      self.count_down()
    }, this.tick);
  },

  count_down: function () {
    var timeout_in = this.time_passed();
    //console.log("timeout in: "+ timeout_in +" :: default timeout: " + this.default_timeout);
    if (timeout_in > this.default_timeout) {
      console.log("timed out!");
      window.location.href = "/";
    } else {
      if (this.alarm_bell()) {
        console.log('Session will timeout in ' + this.alarm_time)
        var msg = '<p>Your session will time out in ' + Math.round(this.alarm_time / 60) + ' minutes.</p><p><a href="/pages/version.json" onclick="_fpa.status.session.reset_timeout(); _fpa.clear_flash_notices();" data-remote="true" class="btn btn-warning">Continue working</a> to continue working</a> or <a href="/users/sign_out"  data-method="delete" class="btn btn-default">logout</a></p>';
        _fpa.flash_notice(msg, 'warning');
      }
      this.start_counting();
    };
  },

  time_passed: function () {
    var tlr = window.localStorage.getItem('session_last_reset');
    if (!tlr)
      tlr = 0;
    else
      tlr = parseInt(tlr);
    var t = this.time_now() - tlr;
    return t;
  }

};
