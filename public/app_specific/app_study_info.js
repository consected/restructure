_fpa.app_specific = {

  reformat_edit_block(block) {
    if (block.hasClass('use-config-layout')) {
      var dl = block.find('.result-field-container[data-field-name="default_layout"]').attr('data-field-val')
      dl = dl || 'rows'
      block.addClass(`cl-default-layout-${dl}`)
      var $mre  = block.find('.mr-expander')
      $mre.click()
      $mre.parents('.rr-mr').hide()
    }

    if (block.parents('.use-config-layout')) {
      var $mr = block.parents('.model-reference-result').first()
      
      var wv = block.find('.result-field-container[data-field-name="block_width"]').attr('data-field-val')
      if (wv == null) wv = block.find('.edit-field-container [data-attr-name="block_width"]').val()
      if (wv == null) wv = '100%' 
      
      var pn = block.find('.result-field-container[data-field-name="position_number"]').attr('data-field-val')
      if (pn == null) pn = block.find('.edit-field-container [data-attr-name="position_number"]').val()
      if (pn == null) pn = 100000
      $mr.css({width: wv, order: pn})
    }
  },

  postprocessor (block, data) {
    console.log('use config layout')

    
    _fpa.app_specific.reformat_edit_block(block)      
    
    block.find('.use-config-layout').each(function() {
      _fpa.app_specific.reformat_edit_block($(this))      
    })

  },
}
