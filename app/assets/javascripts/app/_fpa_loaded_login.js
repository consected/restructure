_fpa.loaded.login = function () {

  let allow_submit = false;
  const el_mfa_form = $('#mfa-step1')[0];

  // Setup help icon trigger
  const $nav = $('body');
  _fpa.form_utils.setup_data_toggles($nav);

  // Force email usernames to lowercase in the form
  $('#user_email, #admin_email').on('blur change', function () {
    const email = $(this).val();
    $(this).val(email.toLowerCase());
  });

  if (!el_mfa_form || $('.login-block').length === 0) return;

  // Expose OTP idle timeout from settings to client-side state
  _fpa.loaded.login_state = {
    otp_idle_timeout: parseInt($(el_mfa_form).data('otp-idle-timeout')) || 300
  };

  const otp_idle_timer = _fpa.loaded.two_factor_timeout.create_timer(
    _fpa.loaded.login_state.otp_idle_timeout,
    function () {
      allow_submit = false;
      $('#user_password, #admin_password').val('');
      $('#user_otp_attempt, #admin_otp_attempt').val('');
      $('.login-2fa-block').hide();
      $('.login-user-password-block').show();
      $('#user_otp_attempt, #admin_otp_attempt').removeAttr('required');
    }
  );

  const $form = $('form#new_user, form#new_admin');
  const $btn_final = $('input[type="submit"]');
  const orig_final_caption = $btn_final.attr('data-orig-value');

  function handle_step1_response(responseData) {
    window.setTimeout(function () {

      allow_submit = true;
      // Avoid crude attempts for bad actors to get user MFA status
      $('#mfa-step1').prop('action', '/bad_request');

      // Reset the caption on the submit button
      $btn_final.attr('disabled', null).val(orig_final_caption);

      if (responseData.need_2fa) {
        $('.login-user-password-block').hide();
        $('.login-2fa-block').show();
        $('#user_otp_attempt, #admin_otp_attempt').attr('required', true).focus();

        // Start idle timeout: reset to step 1 if OTP not submitted in time
        otp_idle_timer.start();
      }
      else {
        $('form#new_user, form#new_admin').submit();
      }
    }, 300);
  }

  // Bind ajax:success directly on #mfa-step1 so step1 responses are handled
  // on every submission (not just the first, unlike app_callback which is one-shot).
  $(el_mfa_form).on('ajax:success', function (e, data, status, xhr) {
    handle_step1_response(xhr.responseJSON || {});
  });

  $form.on('submit', function (ev) {
    if (allow_submit) {
      // User is submitting the OTP - clear the idle timeout timer
      otp_idle_timer.clear();
      return;
    }

    ev.preventDefault();
    // Force email usernames to lowercase in the form
    const email = $('#user_email, #admin_email').val().toLowerCase();
    const password = $('#user_password, #admin_password').val();

    $('#step1-email').val(email);
    $('#step1-password').val(password);

    // Avoid crude attempts for bad actors to get user MFA status
    $('#mfa-step1').prop('action', '/mfa/step1.json');
    $('#mfa-step1').submit();

  }).addClass('ready-for-2fa');


};
