_fpa.app_specific = class {
  constructor(block, data) {
    this.block = block;
    this.data = data;
  }

  static postprocessor(block, data) {
    console.log('use config layout');

    var processor = new _fpa.app_specific(block, data);

    // Process the current block
    processor.reformat_page();
    processor.handle_part();
    processor.handle_embedded_links();
    processor.handle_glyphicons();

    // Process any blocks it contains that have the class use-config-layout
    // which is typical when loading a list of pages
    block.find('.use-config-layout').each(function () {
      var block_processor = new _fpa.app_specific($(this));
      block_processor.reformat_page();
      block_processor.handle_part();
      $(this)
        .find('.embedded-items-item')
        .each(function () {
          block_processor.adjust_style($(this));
        });
    });
  }

  // Reformat page if it has the class use-config-layout
  reformat_page() {
    if (!this.block.hasClass('use-config-layout')) return;

    this.add_layout_class();
    this.load_referenced_parts();

    // If this is author mode
    if (this.is_author_mode()) {
      this.add_expander_icon();
    }
  }

  // If the current block is a part of a page, handle its formatting
  handle_part() {
    var block = this.block;
    var $outer = block.parents('.use-config-layout');

    // Return if this is not a part of a page, or the page block doesn't have the class use-config-layout
    if (!$outer.length) return;

    var $mr = block.parents('.model-reference-result').first();

    this.adjust_style($mr);
  }

  adjust_style($embedded_block) {
    if (!$embedded_block.length || $embedded_block.hasClass('done-use-config-layout')) return;

    var wv = this.get_part_setting($embedded_block, 'block_width');
    if (!wv && this.default_layout() == 'rows') wv = '100%';

    var pn = this.get_part_setting($embedded_block, 'position_number');
    if (!pn) pn = 1000;

    pn = parseInt(pn) + 1000;
    $embedded_block.css({ width: wv, order: pn });

    if (this.is_author_mode()) {
      var ec = this.get_part_setting($embedded_block, 'extra_classes');
      if (ec) $embedded_block.addClass(ec);
    }

    $embedded_block.addClass('done-use-config-layout');
  }

  get_part_setting($embedded_block, name) {
    var val = $embedded_block.find(`.result-field-container[data-field-name="${name}"]`).attr('data-field-val');
    if (!val) val = $embedded_block.find(`.edit-field-container [data-attr-name="${{ name }}"]`).val();
    return val;
  }

  // Add a class representing the layout based on the field default_layout
  add_layout_class(def_layout) {
    var def_layout = this.default_layout();
    if (def_layout) {
      this.block.addClass(`cl-default-layout-${def_layout}`);
    }
  }

  default_layout() {
    if (this.block.hasClass('use-config-layout')) var $main_block = this.block;
    else var $main_block = this.block.parents('.use-config-layout').first();

    var res = $main_block.find('.result-field-container[data-field-name="default_layout"]').attr('data-field-val');
    if (!res) res = $main_block.attr('data-default-layout');

    return res;
  }

  // Load the referenced parts automatically if they haven't already been marked as opened
  // Don't hide the reference links, since we can't disable references without them, so just remove the
  // toggle caret
  // Do nothing if the page was not previously expanded
  load_referenced_parts() {
    if (!this.was_page_expanded()) return;

    var $mre_active = this.block.find('.rr-mr').not('.model-reference-disabled').find('.mr-expander').not('.mr-opened');
    //model-reference-disabled
    $mre_active.click().addClass('mr-opened');

    var $mre = this.block.find('.mr-expander').not('.mr-opened');
    // Hide caret
    $mre.parents('.rr-mr .mr-expander').hide();
  }

  is_author_mode() {
    return !this.block.hasClass('common-page-template-item');
  }

  was_page_expanded() {
    return this.block.hasClass('page-was-expanded');
  }

  // Add an expander icon to the start of the part's header
  add_expander_icon() {
    var processor = this;
    var block = this.block;

    // If the icon is already in place, return
    if (block.find('.dynamic-show-label').length) return;

    // Add the icon
    block
      .find('.object-results-header .list-group-item-heading')
      .before('<a class="dynamic-show-label glyphicon glyphicon-triangle-bottom"></a>');

    // Add the click handler
    block.on('click', '.dynamic-show-label', function (e) {
      if ($(this).hasClass('glyphicon-triangle-bottom')) {
        // Not expanded

        processor.block.addClass('page-was-expanded');
        $(this).addClass('glyphicon-triangle-top');
        $(this).removeClass('glyphicon-triangle-bottom');
        processor.load_referenced_parts();
      } else {
        // Is expanded
        processor.block.removeClass('page-was-expanded');
        $(this).addClass('glyphicon-triangle-bottom');
        $(this).removeClass('glyphicon-triangle-top');
      }

      e.preventDefault();
    });

    block.on('click', '.edit-entity', function (e) {
      processor.block.addClass('page-was-expanded');
    });
  }

  handle_embedded_links() {
    var processor = this;
    var block = this.block;

    block.find('a[href$="#page_embed"]').each(function () {
      var url = $(this).attr('href').replace('#page_embed', '');
      var url_split = url.split('/');
      var id = url_split[url_split.length - 1].split('?')[0];
      var hyph_name = url_split[url_split.length - 2].hyphenate().singularize();
      var pre = 'common';
      if (url_split[url_split.length - 3] == 'activity_log') {
        hyph_name = `activity-log-${hyph_name}`;
        pre = 'activity_log';
      }

      var block_id = `${hyph_name}--${id}`;

      $(this)
        .attr('data-remote', true)
        .attr('data-result-target-force', true)
        .attr(`data-${hyph_name}-id`, id)
        .attr('data-result-target', `#${block_id}`)
        .attr('data-template', `${hyph_name}-result-template`)
        .attr('data-toggle', 'scrollto-target');

      var text = $(this).parents('.notes-text');
      var html = text.html();
      if (!html) return;

      var new_div = `<div id="${block_id}"
      class="page-embedded-block"
      data-preprocessor="${pre}_edit_form"
      data-model-name="${hyph_name.underscore()}" 
      data-id="${id}"
      data-result-target-for-child="#${block_id}"></div>`;

      var new_html = html.replace('{{page_embedded_block}}', new_div);
      text.html(new_html);
    });
  }

  handle_glyphicons() {
    const processor = this;
    const block = this.block;
    if (block.find('.custom-editor-container').length) return;

    var text = block.html();
    var res = text.match(/{{glyphicon_[a-z_]+}}/g);

    if (!res || res.length < 1) return;

    res.forEach(function (el) {
      const gi = el.replaceAll('_', '-').replaceAll('{{', '').replaceAll('}}', '');
      text = text.replaceAll(el, `<i class="glyphicon ${gi}"></i>`);
    });

    block.html(text);
  }
};
