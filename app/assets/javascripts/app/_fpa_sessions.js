_fpa.session = function (timeout) {
  if (!timeout) return;
  this.timeout = timeout;
  this.default_timeout = timeout + this.tick / 1000;
  if (timeout <= this.alarm_time) this.alarm_time = timeout * 0.7;
  this.start_counting(true);

  return this;
};

_fpa.session.prototype = {

  timeout: null, // requested timeout time
  default_timeout: null, // timeout plus another tick
  last_reset: null,
  tick: 10000,
  alarm_time: 120,
  alarmed: null,
  is_counting: false,
  has_ticked: null, // will be set to false when timeout is set, and true when timeout is triggered

  time_now: function () {
    return (new Date().getTime()) / 1000;
  },

  alarm_bell: function () {
    var timeout_in = this.time_passed();
    var res = timeout_in > (this.default_timeout - this.alarm_time);
    this.alarmed = res;
    return res;
  },

  reset_timeout: function () {
    // console.log("reset_timeout to "+this.default_timeout + ' seconds');
    window.localStorage.setItem('session_last_reset', this.time_now());
    this.alarmed = null;
  },

  start_counting: function (reset) {
    if (reset) this.reset_timeout();

    this.is_counting = true;

    if (this.has_ticked === false) return;

    var self = this;
    window.setTimeout(function () {
      self.has_ticked = true;
      self.count_down()
    }, this.tick);

    this.has_ticked = false;
  },

  count_down: function () {
    var timeout_in = this.time_passed();
    //console.log("timeout in: "+ timeout_in +" :: default timeout: " + this.default_timeout);
    if (timeout_in > this.default_timeout) {
      console.log("timed out!");
      window.location.href = "/";
    } else {
      if (this.alarmed) {
        _fpa.clear_flash_notices();
      }
      if (this.alarm_bell()) {
        let tr = this.time_remaining();
        let trmin = Math.round(tr / 60);
        console.log(`Session will timeout in ${tr} seconds`)
        var msg = `<p>Your session will time out in ${trmin} ${trmin == 1 ? 'minute' : 'minutes'}.</p><p><a href="/pages/version.json" onclick="_fpa.status.session.reset_timeout(); _fpa.clear_flash_notices();" data-remote="true" class="btn btn-warning">Continue working</a> to continue working</a> or <a href="/users/sign_out"  data-method="delete" class="btn btn-default">logout</a></p>`;
        _fpa.flash_notice(msg, 'warning');
        _fpa.utils.beep();
      }
      this.start_counting();
    };
  },

  time_remaining: function () {
    let res = (this.timeout - this.time_passed());
    if (res < 0) res = 0;
    return res
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
