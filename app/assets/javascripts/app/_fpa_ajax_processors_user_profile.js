_fpa.postprocessors_user_profile = {

  user_profile_container: function (block, data) {

    // Force the accordion to work correctly
    var tabs = block.find('#user-profiles-tabs a[data-toggle="collapse"]');
    tabs.on('click', function () {
      var clicked = $(this).prop('id');
      tabs.each(function () {
        if (clicked == $(this).prop('id')) return;
        $($(this).attr('data-target')).collapse('hide');
      })
    });

  }

}

_fpa.loaded.user_profiles = function () {

}

$.extend(_fpa.postprocessors, _fpa.postprocessors_user_profile);

