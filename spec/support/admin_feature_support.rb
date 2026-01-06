# frozen_string_literal: true

# Helper methods for admin panel system specs
# Provides helpers for selecting from dropdowns, big-select fields, and waiting for AJAX
module AdminFeatureSupport
  # Helper to clear a chosen dropdown field (select blank option)
  # Uses JavaScript to reset the chosen field properly
  def clear_admin_chosen_field(field_name_suffix)
    selector = "select[id$='_#{field_name_suffix}']"
    field = find(selector, match: :first, visible: :all)
    field_id = field['id']

    # Use JavaScript to clear the chosen dropdown
    page.execute_script(<<~JS)
      var field = document.getElementById('#{field_id}');
      if (field) {
        field.value = '';
        $(field).trigger('chosen:updated');
        $(field).trigger('change');
      }
    JS
    sleep 0.3
  end

  # Helper method to select from dropdown using chosen or regular select
  # Uses name attribute since IDs vary between new/edit forms
  def select_admin_field(field_name, value)
    # Find by name pattern
    selector = "select[name*='[#{field_name}]']"
    field = find(selector, visible: :all)

    if field['class']&.include?('use-chosen')
      # Handle chosen dropdown
      field_id = field['id']
      chosen_id = "#{field_id}_chosen"

      # Scroll and click the chosen container
      chosen_container = find("##{chosen_id}")
      page.execute_script('arguments[0].scrollIntoView(true);', chosen_container)
      sleep 0.2
      chosen_container.click
      sleep 0.3

      # Wait for dropdown and click option - search at body level
      results_selector = 'body > .chosen-container.chosen-with-drop .chosen-results li.active-result'
      expect(page).to have_css(results_selector, wait: 5)

      # Find matching result
      results = all(results_selector)
      matching = results.find { |r| r.text.strip == value.to_s }
      unless matching
        raise "Could not find option '#{value}' in #{field_name}. Available: #{results.map(&:text).inspect}"
      end

      matching.click
      sleep 0.3
    else
      # Regular select
      field.select(value)
    end
  end

  # Helper to select by field name suffix (works for both new and edit forms)
  # NOTE: For chosen dropdowns, this method MUST be called outside of any within blocks
  def select_admin_field_by_id(field_name_suffix, value)
    # Use name attribute which is consistent across new/edit forms
    selector = "select[name$='[#{field_name_suffix}]']"
    field = all(selector, visible: :all).first # Use first() in case of multiple matches
    field_id = field['id']

    if field['class']&.include?('use-chosen')
      # Delegate to FeatureSupport's select_from_chosen which properly handles body-level dropdowns
      # This requires the field name without the admin_ prefix
      # Extract the actual field name from the id (e.g., 'admin_user_access_control_user_id' -> 'user_id')
      field_name_parts = field_id.split('_')
      # Find where the model name ends and field name begins
      # For 'admin_user_access_control_user_id', we want 'user_id'
      actual_field_name = field_name_suffix

      # Use the select_from_chosen helper which works at body level
      chosen_id = "#{field_id}_chosen"
      expect(page).to have_css("##{chosen_id}", visible: :all, wait: 2)
      chosen_container = all("##{chosen_id}", match: :first).first
      scroll_into_view(chosen_container)
      sleep 0.2
      chosen_container.click
      sleep 0.5

      # The dropdown appears absolutely positioned at body level
      results_selector = 'body > .chosen-container.chosen-with-drop .chosen-results li.active-result'
      expect(page).to have_css(results_selector, wait: 5)

      # Find matching result at page level (not within any scoped context)
      results = page.all(results_selector)
      matching = results.find { |r| r.text.strip == value.to_s }
      unless matching
        raise "Could not find option '#{value}' in #{field_name_suffix}. Available: #{results.map(&:text).inspect}"
      end

      matching.click
      sleep 0.3
    else
      # Regular select - use select_option to avoid ambiguous matches
      option = field.all('option', visible: :all).find { |opt| opt.text == value.to_s || opt.value == value.to_s }
      unless option
        available = field.all('option', visible: :all).map { |opt| "#{opt.text} (#{opt.value})" }
        raise "Could not find option '#{value}' in #{field_name_suffix}. Available: #{available.inspect}"
      end
      option.select_option
    end
  end

  # Helper to select from big-select field (handles grouped options)
  def select_admin_big_select(field_name, value, group_name: nil)
    # Find the input field that triggers big-select
    field = find("input[name*='#{field_name}'].use-big-select", visible: :all)

    # Scroll into view and focus
    page.execute_script('arguments[0].scrollIntoView(true);', field)
    sleep 0.3
    field.click
    page.execute_script('arguments[0].focus();', field)

    # Wait for modal at body level
    expect(page).to have_css('#primary-modal.fade.in', wait: 5)

    # Check if there are grouped items (collapsible panels)
    if page.has_css?('.big-select-group-head', wait: 2)
      # Find all group headers
      group_headers = page.all('.big-select-group-head')

      target_group = if group_name
                       # Find specific group
                       group_headers.find { |h| h.text.include?(group_name) }
                     else
                       # Use first group by default
                       group_headers.first
                     end

      raise "Could not find group '#{group_name}'. Available: #{group_headers.map(&:text).inspect}" unless target_group

      # Click the group header link to expand it
      within(target_group) do
        find('a[data-toggle="collapse"]').click
      end
      sleep 0.5
    end

    # Wait for items to be visible
    expect(page).to have_css('.big-select-item', wait: 3)

    # Find and click the item
    all_items = page.all('.big-select-item', visible: true)
    matching = all_items.find { |item| item.text.include?(value) || item['data-bsi-key'] == value }

    unless matching
      raise "Could not find '#{value}' in big-select. Available: #{all_items.map(&:text).take(10).inspect}"
    end

    matching.click

    # Wait for modal to close
    expect(page).not_to have_css('#primary-modal.fade.in', wait: 3)
    sleep 0.5
  end

  # Helper to wait for AJAX form to complete
  def wait_for_admin_form_save
    # Wait for the saved-row class to appear
    expect(page).to have_css('.saved-row', wait: 10)
    sleep 0.5
  end

  # Helper to select from access field which has multiple options with same value in different optgroups
  # Selects the first option with the given value in a visible/enabled optgroup
  # Uses JavaScript to properly select the option since Capybara has issues with
  # multiple options having the same value in different optgroups
  def select_admin_access_field(value)
    selector = "select[name*='[access]']"
    field = find(selector, visible: :all)

    # Use JavaScript to properly select the option in a visible optgroup
    # This handles both native selects and Chosen.js selects
    result = page.evaluate_script(<<~JS)
      (function() {
        var select = document.querySelector("#{selector}");
        if (!select) return { error: 'Select not found' };
      #{'  '}
        var options = select.querySelectorAll('option[value="#{value}"]');
        if (!options.length) return { error: 'No options with value', available: Array.from(select.options).map(o => o.value) };
      #{'  '}
        for (var i = 0; i < options.length; i++) {
          var opt = options[i];
          var og = opt.parentElement;
          if (og.tagName === 'OPTGROUP') {
            var isHidden = og.style.display === 'none';
            var isDisabled = og.disabled;
            if (!isHidden && !isDisabled) {
              // Found a valid option - use selectedIndex to select it specifically
              var allOpts = select.options;
              for (var j = 0; j < allOpts.length; j++) {
                if (allOpts[j] === opt) {
                  select.selectedIndex = j;
                  break;
                }
              }
              // Trigger change event and Chosen update
              $(select).trigger('change').trigger('chosen:updated');
              return { success: true, index: j };
            }
          } else {
            // Not in optgroup, just select it
            select.selectedIndex = Array.from(select.options).indexOf(opt);
            $(select).trigger('change').trigger('chosen:updated');
            return { success: true };
          }
        }
        return { error: 'No option in visible optgroup' };
      })()
    JS

    raise "Could not select access '#{value}': #{result['error']}" if result['error']

    sleep 0.3
    true
  end

  # Check for validation errors after form submission
  def expect_no_validation_errors
    return unless page.has_css?('.alert-danger, .field_with_errors', wait: 1)

    errors = all('.alert-danger, .help-block, .field_with_errors').map(&:text).join('; ')
    raise "Validation errors found: #{errors}"
  end
end
