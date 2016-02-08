// This function is defined purely to allow the WebShim form-validation.js to avoid a typeerror looking for $.swap. 
// This change stopped Date Picker controls from working in Firefox.
// The error was introduced in v3.1.105 when Rails gems were updated to address CVEs. Jquery must have been updated 
// by this release, causing the swap function to be removed.
// The related Jquery commit was https://github.com/jquery/jquery/commit/02a9d9f94b623ea8664b7b39fd57feb7de6c6a14 
// 
// Since an updated version of webshims was not available when this release was due, 
// the original (undocumented) Jquery function was extracted from source 
// and used here as a stop-gap measure.
//
// It is recommended that a future release check the status of the webshim issue #560 at
// https://github.com/aFarkas/webshim/issues/560 
// to check it has been resolved. If it has then this function / file should be removed and the app rebuilt / retested.
//
// This issue is tracked in JIRA as FPHS-252. The issue is intended to remain open until a long term fix is implemented.
//

jQuery.swap = function( elem, options, callback, args ) {
    var ret, name, old = {};
    // Remember the old values, and insert the new ones
    for ( name in options ) {
            old[ name ] = elem.style[ name ];
            elem.style[ name ] = options[ name ];
    }

    ret = callback.apply( elem, args || [] );

    // Revert the old values
    for ( name in options ) {
            elem.style[ name ] = old[ name ];
    }
    return ret;
};
