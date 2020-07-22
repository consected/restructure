_fpa.view_handlers.address = function (block) {

  // Setup display of address state, country and source names
  block.find('[class*="address-state_name"] small').each(function () { $(this).html('state'); });
  block.find('[class*="address-country_name"] small').each(function () { $(this).html('country'); });
  block.find('[class*="address-source_name"] small').each(function () { $(this).html('source'); });
};

_fpa.view_handlers.address_edit = function (block) {

  var check_zip = function () {

    block.find('input[data-attr-name="zip"]').mask("00000-9999", { 'translation': { 0: { pattern: /\d/ }, 0: { pattern: /\d/, optional: true } } });
  };

  check_zip();

  var handle_country = function (val) {

    if (!val || val === 'US' || val === '') {
      block.find('.list-group-item[class*="address-region"]').slideUp();
      block.find('.list-group-item[class*="address-postal_code"]').slideUp();
      block.find('.list-group-item[class*="address-zip"]').slideDown();
      block.find('.list-group-item[class*="address-state"]').slideDown();
      block.find('.list-group-item[class*="address-region"] [data-attr-name="region"]').val('');
      block.find('.list-group-item[class*="address-postal_code"] [data-attr-name="postal_code"]').val('');
    } else {
      block.find('.list-group-item[class*="address-region"]').slideDown();
      block.find('.list-group-item[class*="address-postal_code"]').slideDown();
      block.find('.list-group-item[class*="address-zip"]').slideUp();
      block.find('.list-group-item[class*="address-state"]').slideUp();
      block.find('.list-group-item[class*="address-zip"] [data-attr-name="zip"]').val('');
      block.find('.list-group-item[class*="address-state"] [data-attr-name="state"]').val('');
    }

  };

  var country_input = block.find('[data-attr-name="country"]');

  country_input.change(function () {
    handle_country($(this).val());
  });

  window.setTimeout(function () {
    handle_country(country_input.val());
  }, 10);


}