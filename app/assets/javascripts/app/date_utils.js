// Get locale string, only including the date and not the time portion
Date.prototype.asLocale = function () {
    return _fpa.utils.isoDateStringToLocale(this.toISOString());
};

Date.prototype.asYMD = function () {
    return _fpa.utils.DateTime.fromJSDate(this).toISODate(); //returns YYYY-MM-DD like '2022-09-05'
};