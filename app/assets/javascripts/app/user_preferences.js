class UserPreferences {

    static date_format() {
        const df = {
            'mm/dd/yyyy': 'MM/dd/yyyy',
            'dd/mm/yyyy': 'dd/MM/yyyy',
        };
        return df[_fpa.state.current_user_preference.date_format];
    }

    static date_time_format(with_seconds = false) {

        const seconds = (with_seconds ? ':ss' : '')
        const dtf = {
            'mm/dd/yyyy 24h:mm': `MM/dd/yyyy HH:mm${seconds}`,
            'mm/dd/yyyy hh:mm am/pm': `MM/dd/yyyy h:mm${seconds} a`,
            'dd/mm/yyyy hh:mm am/pm': `dd/MM/yyyy h:mm${seconds} a`,
            'dd/mm/yyyy 24h:mm': `dd/MM/yyyy HH:mm${seconds}`,
        };
        return dtf[_fpa.state.current_user_preference.date_time_format];
    }

    static time_format(with_seconds = false) {
        const seconds = (with_seconds ? ':ss' : '')
        const tf = {
            'hh:mm am/pm': `h:mm${seconds} a`,
            '24h:mm': `H:mm${seconds}`
        };
        return tf[_fpa.state.current_user_preference.time_format];
    }

    static timezone() {
        return _fpa.state.current_user_preference.timezone_iana;
    }
}
