_fpa.reports_custom_handling.add_handler_implementation('array_field_to_blocks', function () {
  var first = null;
  var all_items = [];
  const $block = this.$block;

  const $list_cell = $block.find('td[data-col-type="array_field_to_blocks_items"]')
  const all_items_text = $list_cell.first().text();
  if (all_items_text && all_items_text != '' && all_items_text != '[nil]') {
    all_items = JSON.parse(all_items_text)
  }
  $block.find('[data-col-type="array_field_to_blocks_items"]').hide();

  // Handle the header
  var $th = $block.find('th[data-col-name="array_field_to_blocks"]');
  $th.hide();
  let newth = '';
  for (let i = 0; i < all_items.length; i++) {
    newth = `${newth}<th class="added"><span class="added-label">${all_items[i]}</span></th>`
  }
  $th.after(newth);

  // Handle each row
  $block.find('td[data-col-type="array_field_to_blocks"]').each(function () {
    let h = $(this).text()
    let j = []
    if (h && h != '' && h != '[nil]') {
      j = JSON.parse(h)
    }

    let res = []
    for (let i = 0; i < all_items.length; i++) {
      res[i] = (j.indexOf(all_items[i]) >= 0)
    }
    let newh = '';
    for (let has in res) {
      newh = `${newh}<td class="rch-aftb gotitem gotitem-${res[has]}"></td>`
    }
    $(this).html('').after(newh)
  }).hide();

});
