_fpa_admin.user_access_controls.admin_edit_form = class {

  constructor(block, data) {
    this.block = block
    this.data = data
  }

  // Provide additional admin edit form setup
  static setup(block, data) {

    var aef = new _fpa_admin.user_access_controls.admin_edit_form(block, data)

    aef.setup_selectors()
  }

  // For the selection of resource types / names in user access control form
  setup_selectors() {
    var block = this.block
    var _this = this

    const a_fname = 'form select[name="admin_user_access_control[access]"]'
    const $access_select = $(a_fname)

    // Capture the original access value from the Rails form before any JS runs
    // Look for the option with selected="selected" attribute set by Rails
    const $originally_selected = $access_select.find('option[selected="selected"]')
    this.original_access_value = $originally_selected.length > 0 ? $originally_selected.val() : $access_select.val()

    this.res_type_changed($('form #admin_user_access_control_resource_type'));
    block.on('change', '#admin_user_access_control_resource_type', function () {
      _this.res_type_changed($(this))
    })
    window.setTimeout(function () {
      $('form #admin_user_access_control_resource_type').change()
    }, 1)
  }

  res_type_changed($el) {
    const val = $el.val()
    const rn_fname = 'input[name="admin_user_access_control[resource_name]"]'
    const a_fname = 'form select[name="admin_user_access_control[access]"]'
    const $access_select = $(a_fname)

    $(rn_fname).attr('data-big-select-subtype', val)
    // Hide non-matching optgroups and set disabled attribute so Chosen.js hides those options
    $(`${a_fname} optgroup[label]`).hide().attr('disabled', 'disabled')
    $(`${a_fname} optgroup[label="${val}"]`).show().attr('disabled', null)

    // Before triggering chosen:updated, restore the original value if it exists in visible optgroup
    if (this.original_access_value) {
      // First, clear selected attribute from ALL options (including hidden optgroups)
      $(`${a_fname} option[selected="selected"]`).attr('selected', null)

      const $visible_optgroup = $(`${a_fname} optgroup[label="${val}"]`)
      const $matching_option = $visible_optgroup.find(`option[value="${this.original_access_value}"]`)
      if ($matching_option.length > 0) {
        // Set selected attribute on the correct option
        $matching_option.attr('selected', 'selected')
        // Also set selectedIndex for the native select
        const select_element = $access_select[0]
        const all_options = select_element.options
        for (let i = 0; i < all_options.length; i++) {
          if (all_options[i] === $matching_option[0]) {
            select_element.selectedIndex = i
            break
          }
        }
      }
    }

    $(a_fname).trigger('chosen:updated');
  }

}