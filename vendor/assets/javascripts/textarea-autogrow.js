/*
The MIT License (MIT)

Copyright (c) 2015 Evyatar Rosner

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
 to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// Original Source: https://github.com/evyros/textarea-autogrow


(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        define([], factory);
    } else if (typeof module === 'object' && module.exports) {
        module.exports = factory();
    } else {
        root.Autogrow = factory();
  }
})(this, function(){
    return function(textarea, maxLines){
        var self = this;

        if(maxLines === undefined){
            maxLines = 999;
        }

        /**
         * Calculates the vertical padding of the element
         * @param textarea
         * @returns {number}
         */
        self.getOffset = function(textarea){
            var style = window.getComputedStyle(textarea, null),
                props = ['paddingTop', 'paddingBottom'],
                offset = 0;

            for(var i=0; i<props.length; i++){
                offset += parseInt(style[props[i]]);
            }
            return offset;
        };

        /**
         * Sets textarea height as exact height of content
         * @returns {boolean}
         */
        self.autogrowFn = function(){
            var newHeight = 0, hasGrown = false;
            if((textarea.scrollHeight - offset) > self.maxAllowedHeight){
                textarea.style.overflowY = 'scroll';
                newHeight = self.maxAllowedHeight;
            }
            else {
                textarea.style.overflowY = 'hidden';
                textarea.style.height = 'auto';
                newHeight = textarea.scrollHeight - offset;
                hasGrown = true;
            }
            textarea.style.height = newHeight + 'px';
            return hasGrown;
        };

        var offset = self.getOffset(textarea);
        self.rows = textarea.rows || 1;
        self.lineHeight = (textarea.scrollHeight / self.rows) - (offset / self.rows);
        self.maxAllowedHeight = (self.lineHeight * maxLines) - offset;

        // Call autogrowFn() when textarea's value is changed
        textarea.addEventListener('input', self.autogrowFn);
    };
});
