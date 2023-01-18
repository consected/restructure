_fpa.loaded.login = function () {

  let allow_submit = false;
  const el_mfa_form = $('#mfa-step1')[0];

  // Force email usernames to lowercase in the form
  $('#user_email, #admin_email').on('blur change', function () {
    const email = $(this).val();
    $(this).val(email.toLowerCase());
  });

  if (!el_mfa_form || $('.login-block').length === 0) return;

  const $form = $('form#new_user, form#new_admin');
  const $btn_final = $('input[type="submit"]');
  const orig_final_caption = $btn_final.attr('data-orig-value');

  el_mfa_form.app_callback = function (block, data) {
    window.setTimeout(function () {

      allow_submit = true;
      // Avoid crude attempts for bad actors to get user MFA status
      $('#mfa-step1').prop('action', '/bad_request');

      // Reset the caption on the submit button
      $btn_final.attr('disabled', null).val(orig_final_caption);

      if (data.need_2fa) {
        $('.login-user-password-block').hide();
        $('.login-2fa-block').show();
        $('#user_otp_attempt, #admin_otp_attempt').attr('required', true).focus();
      }
      else {
        $('form#new_user, form#new_admin').submit();
      }
    }, 300)
  };

  $form.on('submit', function (ev) {
    if (allow_submit) return;

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
