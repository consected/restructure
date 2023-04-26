_fpa.loaded.registrations = () => {

    const GDPR_COUNTRY_CODES = ['GR', 'FR', 'ES', 'DE', 'GB'];

    const isGdprCountry = (countryCode) => {
        return GDPR_COUNTRY_CODES.includes(countryCode);
    }

    const gdprTermsOfUse = $('#eula-gdpr');
    const defaultTermsOfUse = $('#eula-default');
    const handleEulaContext = () => {
        $('#user_country').on('change', (event) => {
            const selectElement = $(event.currentTarget);
            const countryCode = selectElement.val();
            if (isGdprCountry(countryCode)) {
                defaultTermsOfUse.hide();
                gdprTermsOfUse.show();
            } else {
                gdprTermsOfUse.hide();
                defaultTermsOfUse.show();
            }
        });
    };

    handleEulaContext();
    gdprTermsOfUse.hide();
};
