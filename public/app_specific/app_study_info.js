_fpa.app_specific = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  static postprocessor(block, data) {
    console.log('use config layout')

    var processor = new _fpa.app_specific(block, data)

    // Process the current block
    processor.reformat_page()
    processor.handle_part()

    // Process any blocks it contains that have the class use-config-layout
    // which is typical when loading a list of pages
    block.find('.use-config-layout').each(function () {
      var block_processor = new _fpa.app_specific($(this), this.data)
      block_processor.reformat_page()
      block_processor.handle_part()
    })

  }


  // Reformat page if it has the class use-config-layout
  reformat_page() {

    if (!this.block.hasClass('use-config-layout')) return

    this.add_layout_class()
    this.load_referenced_parts()

    // If this is author mode
    if (this.is_author_mode()) {
      this.add_expander_icon()
    }

  }

  // If the current block is a part of a page, handle its formatting
  handle_part() {
    var block = this.block
    var $outer = block.parents('.use-config-layout')

    // Return if this is not a part of a page, or the page block doesn't have the class use-config-layout
    if (!$outer.length) return

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

  // Add a class representing the layout based on the field default_layout
  add_layout_class() {
    var dl = this.block.find('.result-field-container[data-field-name="default_layout"]').attr('data-field-val')
    if (dl) {
      this.block.addClass(`cl-default-layout-${dl}`)
    }
  }

  // Load the referenced parts automatically if they haven't already been marked as opened
  // Hide the reference links
  // Do nothing if the page was not previously expanded
  load_referenced_parts() {
    if (!this.was_page_expanded()) return

    var $mre = this.block.find('.mr-expander').not('.mr-opened')
    $mre.click().addClass('mr-opened')
    $mre.parents('.rr-mr').hide()
  }

  is_author_mode() {
    return !this.block.hasClass('common-page-template-item')
  }

  was_page_expanded() {
    return this.block.hasClass('page-was-expanded')
  }

  // Add an expander icon to the start of the part's header
  add_expander_icon() {
    var processor = this
    var block = this.block

    // If the icon is already in place, return
    if (block.find('.dynamic-show-label').length) return

    // Add the icon
    block.find('.object-results-header .list-group-item-heading').before('<a class="dynamic-show-label glyphicon glyphicon-triangle-bottom"></a>')


    // Add the click handler
    block.on('click', '.dynamic-show-label', function (e) {

      if ($(this).hasClass('glyphicon-triangle-bottom')) {
        // Not expanded

        processor.block.addClass('page-was-expanded')
        $(this).addClass('glyphicon-triangle-top')
        $(this).removeClass('glyphicon-triangle-bottom')
        processor.load_referenced_parts()
      }
      else {
        // Is expanded
        processor.block.removeClass('page-was-expanded')
        $(this).addClass('glyphicon-triangle-bottom')
        $(this).removeClass('glyphicon-triangle-top')
      }

      e.preventDefault()
    })

    block.on('click', '.edit-entity', function (e) {
      processor.block.addClass('page-was-expanded')
    })

  }
}
