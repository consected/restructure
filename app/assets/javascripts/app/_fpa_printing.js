_fpa.printing = {

    // Handle a print request, allowing tabs to be loaded, etc
    waitForLoadingToComplete: function(callback, polltime) {
      if(!polltime) polltime = 1000;
      console.log('waiting for loading to complete');

      window.setTimeout(function () {
        if ( $('.ajax-running, .formatting-block').length > 0 ) {
          // wait again
          _fpa.printing.waitForLoadingToComplete(callback, polltime);
        }
        else {
          // Wait one more time before triggering
          window.setTimeout(function () {
            callback ();
          }, polltime);
        }
      }, polltime);
    },

    appPrintHandler: function() {

      _fpa.printing.appPrintTriggered = true;
      $('.print-preparing').show();

      window.setTimeout(function(){
        $('.details-tabs a.collapsed').each(function () {
          $(this).click();
        });

      }, 10);


      _fpa.printing.waitForLoadingToComplete(function(){
        $('.print-preparing').hide();
        window.print();
        window.setTimeout(function (){
          _fpa.printing.appPrintTriggered = false;
        }, 1000);
      });

      return true;

    },


    // Monitor for a print, recommending that users use the application menu print function
    beforePrintHandler: function() {
      var panels = $('.activity-logs-generic-block, .section-panel');
      if(panels.length == 0) return ;
      if(!_fpa.printing.appPrintTriggered) {
        alert('To ensure all data loads correctly cancel printing use the Print option in the application menu bar');
      }
      else {
        panels.each(function() {
          _fpa.form_utils.resize_children($(this), true);
        });
      }
    },

    afterPrintHandler: function() {
      $('.activity-logs-generic-block, .section-panel').each(function() {
        _fpa.form_utils.resize_children($(this));
      });
    }



};
