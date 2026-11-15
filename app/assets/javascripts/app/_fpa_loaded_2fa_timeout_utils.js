_fpa.loaded.two_factor_timeout = {
  default_timeout_secs: 300,

  safe_path(path, fallbackPath) {
    if (typeof path === 'string' && path.charAt(0) === '/') return path;
    return fallbackPath;
  },

  create_timer(timeoutSecs, onTimeout) {
    let timerId = null;
    const parsedTimeout = parseInt(timeoutSecs, 10);
    const durationSecs = Number.isFinite(parsedTimeout) && parsedTimeout > 0 ? parsedTimeout : this.default_timeout_secs;

    return {
      duration_secs: durationSecs,

      start() {
        if (timerId) window.clearTimeout(timerId);
        timerId = window.setTimeout(function () {
          timerId = null;
          onTimeout();
        }, durationSecs * 1000);
      },

      clear() {
        if (!timerId) return;
        window.clearTimeout(timerId);
        timerId = null;
      }
    };
  },

  sign_out_and_redirect({ signInPath, signOutPath, csrfToken }) {
    const redirectPath = this.safe_path(signInPath, '/users/sign_in');
    const safeSignOutPath = this.safe_path(signOutPath, null);

    if (!safeSignOutPath) {
      window.location.assign(redirectPath);
      return;
    }

    $.ajax({
      url: safeSignOutPath,
      method: 'POST',
      data: { _method: 'delete' },
      headers: csrfToken ? { 'X-CSRF-Token': csrfToken } : {}
    }).always(function () {
      window.location.assign(redirectPath);
    });
  }
};
