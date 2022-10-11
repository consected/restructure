_fpa.e_signature = class {
  static setup(block, force) {
    var $els = block.find('.e-signature-container');
    if (!force) {
      $els = $els.not('.e-signature-setup');
    }

    $els.each(function () {
      const e_signature = new _fpa.e_signature($(this));
      e_signature.setup_container();

    }).addClass('e-signature-setup');


  }

  constructor($container) {
    this.$container = $container;
    this.$iframe = $container.find('.e_signature_document_iframe');
    this.$print_link = $container.find('.e-sign-print-frame');
  }

  setup_container() {
    if (this.$iframe.length === 0) {
      this.$print_link.hide();
      console.log('no e-signature iframe to set up')
      return;
    }

    const _this = this;
    window.setTimeout(function () {
      _this.load_document_into_iframe()
      _this.handle_print()
    }, 10);
  }

  load_document_into_iframe() {
    const $container = this.$container;
    const $iframe = this.$iframe;

    const $doc = $container.find('.e_signature_document');
    const html = $doc.val();
    $iframe.attr('srcdoc', html);
    // Ensure the iframe is fully loaded with a timeout
    window.setTimeout(function () {
      const content = $iframe[0].contentDocument;
      if (content && content.body) {
        $iframe.height(content.body.offsetHeight + 50);
      }
      else {
        $iframe.height(500);
      }
    }, 200);

  }

  handle_print() {
    const $print_link = this.$print_link;
    const $iframe = this.$iframe;
    $print_link.not('.click-ev-attached').on('click', function () {
      $iframe[0].contentWindow.print();
    }).addClass('click-ev-attached');

  }


} 
