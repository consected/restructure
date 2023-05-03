_fpa.loaded.registrations = () => {

    /**
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
     The Netherlands NL
     Poland PL
     Portugal PT
     Romania RO
     Slovakia SK
     Slovenia SI
     Spain ES
     Sweden SW
     United Kingdom GR
     */

    const GDPR_COUNTRY_CODES = ['AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU',
        'IE', 'IT', 'LV', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SW', 'GB'];

    const isGdprCountry = (countryCode) => {
        return GDPR_COUNTRY_CODES.includes(countryCode);
    }

    const gdprTermsOfUse = $('#terms-of-use-gdpr');
    const defaultTermsOfUse = $('#terms-of-use-default');
    const handleTermsOfUseContext = () => {
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

    handleTermsOfUseContext();
    gdprTermsOfUse.hide();
};
