_fpa.app_specific = {

  reformat_edit_block(block) {

    if (block.hasClass('use-config-layout')) {

      // Add a class representing the layout
      var dl = block.find('.result-field-container[data-field-name="default_layout"]').attr('data-field-val')
      if (dl) {
        block.addClass(`cl-default-layout-${dl}`)
      }

      // Load the referenced parts automatically
      var $mre = block.find('.mr-expander')
      $mre.click()
      $mre.parents('.rr-mr').hide()

      // If this is an editor mode
      if (!block.hasClass('common-page-template-item') && !block.hasClass('done-use-config-layout')) {

        // Add a show caret label
        if (block.find('.dynamic-show-label').length == 0) {
          block.find('.object-results-header .list-group-item-heading').before('<a class="dynamic-show-label glyphicon glyphicon-triangle-bottom"></a>')
          block.on('click', '.dynamic-show-label', function (e) {
            var block = $(this).parents('.use-config-layout').first()
            if ($(this).hasClass('glyphicon-triangle-bottom')) {

              if (!$(this).hasClass('already-clicked')) {
                // Load the referenced parts automatically
                var $mre = block.find('.mr-expander')
                $mre.click()
                $mre.parents('.rr-mr').hide()
              }
              block.addClass('user-selected')
              $(this).addClass('glyphicon-triangle-top already-clicked')
              $(this).removeClass('glyphicon-triangle-bottom')
            }
            else {
              block.removeClass('user-selected')
              $(this).addClass('glyphicon-triangle-bottom')
              $(this).removeClass('glyphicon-triangle-top')
            }

            e.preventDefault()
          })
          block.addClass('added-user-show')
        }

      }
    }

    var $outer = block.parents('.use-config-layout')
    if ($outer.length) {
      var $mr = block.parents('.model-reference-result').first()
      if (!$mr.length || $mr.hasClass('done-use-config-layout')) return


      var wv = $mr.find('.result-field-container[data-field-name="block_width"]').attr('data-field-val')
      if (!wv) wv = $mr.find('.edit-field-container [data-attr-name="block_width"]').val()
      if (!wv) wv = '100%'

      var pn = $mr.find('.result-field-container[data-field-name="position_number"]').attr('data-field-val')
      if (!pn) pn = $mr.find('.edit-field-container [data-attr-name="position_number"]').val()
      if (!pn) pn = 0

      pn = parseInt(pn) + 1000
      $mr.css({ width: wv, order: pn })
      $mr.addClass('done-use-config-layout')
    }

  },

  postprocessor(block, data) {
    console.log('use config layout')


    _fpa.app_specific.reformat_edit_block(block)

    block.find('.use-config-layout').each(function () {
      _fpa.app_specific.reformat_edit_block($(this))
    })

  },
}
