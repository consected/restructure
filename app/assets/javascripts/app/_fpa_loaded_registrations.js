_fpa.loaded.registrations = () => {

    const setupOtpForm = $('#form-validate-otp');
    if (setupOtpForm.length > 0) {
        const timeoutSecs = parseInt(setupOtpForm.data('otp-setup-idle-timeout'), 10) || 300;
        const signInPath = setupOtpForm.data('sign-in-path');
        const signOutPath = setupOtpForm.data('sign-out-path');
        const csrfToken = $('meta[name="csrf-token"]').attr('content');
        let setupOtpTimer = null;

        const signOutAndRedirect = () => {
            const redirectPath = signInPath || '/users/sign_in';

            if (!signOutPath) {
                window.location.assign(redirectPath);
                return;
            }

            $.ajax({
                url: signOutPath,
                method: 'POST',
                data: { _method: 'delete' },
                headers: csrfToken ? { 'X-CSRF-Token': csrfToken } : {}
            }).always(() => {
                window.location.assign(redirectPath);
            });
        };

        setupOtpTimer = window.setTimeout(() => {
            $('#otp_attempt').val('');
            signOutAndRedirect();
        }, timeoutSecs * 1000);

        setupOtpForm.on('submit', () => {
            if (setupOtpTimer) {
                clearTimeout(setupOtpTimer);
                setupOtpTimer = null;
            }
        });
    }

    /**
     see also, config/initializers/app_settings.rb GdprCountryCodes

     https://www.gdpradvisor.co.uk/gdpr-countries
     Austria AT
     Belgium BE
     Bulgaria BG
     Croatia HR
     Cyprus CY
     Czech Republic CZ
     Denmark DK
     Estonia EE
     Finland FI
     France FR
     Germany DE
     Greece GR
     Hungary HU
     Ireland IE
     Italy IT
     Latvia LV
     Lithuania LT
     Luxembourg LU
     Malta MT
     Netherlands NL
     Poland PL
     Portugal PT
     Romania RO
     Slovakia SK
     Slovenia SI
     Spain ES
     Sweden SE
     United Kingdom GR
     */

    const GDPR_COUNTRY_CODES = _fpa.gdpr_country_codes;

    const isGdprCountry = (countryCode) => {
        return GDPR_COUNTRY_CODES.includes(countryCode);
    }

    const getLocalizedData = () => {
        const localizedData = {};
        const language = navigator.language
        const localeData = moment.localeData(language);
        localizedData.timezone = new Intl.DateTimeFormat().resolvedOptions().timeZone;
        localizedData.date_formatter = localeData.longDateFormat('L');
        localizedData.time_formatter = localeData.longDateFormat('LT').replace(':', "\:");
        return JSON.stringify(localizedData);
    }

    $('#user_client_localized').val(getLocalizedData());

    const gdprTermsOfUse = $('#terms-of-use-gdpr');
    const defaultTermsOfUse = $('#terms-of-use-default');
    const termsOfUseCheckbox = $('#user_terms_of_use');

    const handleTermsOfUseContext = (selectElement) => {
        const countryCode = selectElement.val();

        if (!countryCode) {
            // hide everything and uncheck the terms of use if the country is not selected.
            defaultTermsOfUse.hide();
            gdprTermsOfUse.hide();
            termsOfUseCheckbox.hide().prop('checked', false);
            return;
        }

        if (isGdprCountry(countryCode)) {
            defaultTermsOfUse.hide();
            gdprTermsOfUse.show();
        } else {
            gdprTermsOfUse.hide();
            defaultTermsOfUse.show();
        }
        // after changing the country uncheck the terms of use
        termsOfUseCheckbox.show().prop('checked', false);
    };

    const countryCodeSelect = $('#user_country_code');
    countryCodeSelect.on('change', (event) => {
        const selectElement = $(event.currentTarget);
        handleTermsOfUseContext(selectElement);
    }).trigger('change');

    _fpa.form_utils.setup_open_in_tab();
};
