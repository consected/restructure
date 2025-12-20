# Feature Spec Quick Reference

## The 3 Critical Patterns (Remember These!)

### 1. Expand mr-expander BEFORE accessing fields

```ruby
# ❌ WRONG - Field doesn't exist yet
click_link proposal_title
fill_in 'Description', with: text

# ✅ CORRECT - Expand section first
click_link proposal_title
finish_page_loading
find('#mr-expander-grant-aims').click
finish_page_loading  # CRITICAL!
fill_in 'Description', with: text
```

### 2. Click edit button for AJAX forms

```ruby
# ❌ WRONG - Visit URL directly
visit edit_path

# ✅ CORRECT - Click edit button
edit_button = find('a.edit-activity-log--resource-name')
edit_button.click
finish_page_loading  # CRITICAL!
# Now form is loaded
```

### 3. Use visible: :all for hidden fields

```ruby
# ❌ WRONG - Can't find hidden radio/checkbox
choose 'yes'
check 'is_selectable'

# ✅ CORRECT - Include hidden elements
choose 'yes', visible: :all
check 'is_selectable', visible: :all
```

## Common Errors and Quick Fixes

| Error | Quick Fix |
|-------|-----------|
| `Unable to find field "Name"` | Expand mr-expander section first |
| `ElementNotInteractableError` | Add `visible: :all` or scroll element |
| `StaleElementReferenceError` | Re-find element after page update |
| `Unable to find option "value"` | Check capitalization (might be "Value") |
| Form submits but data not saved | Click edit button to load AJAX form |
| Intermittent failures | Add `finish_page_loading` after AJAX actions |
| Empty big select dialog | Check query config foreign keys |
| `Ambiguous match, found 2 elements` | Use more specific selector or `within` block |

## Essential Debug Commands

```ruby
# Save current page HTML
File.write('/tmp/debug_page.html', page.html)

# List all mr-expander sections
all('.mr-expander').each { |e| puts "ID: #{e[:id]}" }

# List all inputs in a section
within result_target do
  all('input, select, textarea', visible: :all).each do |f|
    puts "Name: #{f[:name]}, Type: #{f[:type]}"
  end
end

# Check if hidden field exists
all('input[name*="field_name"]', visible: :all).count

# Scroll element into view
page.execute_script('arguments[0].scrollIntoView(true);', element)
sleep 0.5
```

## Extract Field Names from HTML

```bash
# Get all field names
irb --noverbose <<EOF
require 'nokogiri';
file = File.open("/tmp/debug_page.html", "rb");
page = Nokogiri::HTML(file.read);
result = page.css('[data-attr-name]');
result.map {|r| r['data-attr-name']}.join("\n")
EOF

# Get search field names
irb --noverbose <<EOF
require 'nokogiri';
file = File.open("/tmp/debug_page.html", "rb");
page = Nokogiri::HTML(file.read);
result = page.css('input[name*="search_attrs"]');
result.map {|r| r['name']}.join("\n")
EOF
```

## Big Select Field Pattern

```ruby
def select_from_big_select_field(field_name, value)
  field = find("input[name*='#{field_name}']", match: :first)
  page.execute_script('arguments[0].scrollIntoView(true);', field)
  
  # Focus triggers modal
  page.execute_script('arguments[0].focus();', field)
  sleep 1
  
  expect(page).to have_css('#primary-modal.fade.in', wait: 5)
  expect(page).to have_css('.big-select-item', wait: 3)
  
  # Match by key OR text
  page.all('.big-select-item').each do |item|
    if item['data-bsi-key'] == value || item.text.include?(value)
      item.click
      return
    end
  end
  
  File.write('/tmp/big_select_dialog.html', page.html)
  raise "Could not find '#{value}'"
end
```

## Show_if Pattern

```ruby
# Set prerequisite field first
select 'Grant', from: 'funding_source'
sleep 1  # Allow show_if rules to process

# Now dependent field is visible
select_from_big_select_field('select_grant', grant_title)
```

## Validation Check

```ruby
def expect_no_validation_errors
  expect(page).not_to have_selector('div.alert-danger', wait: 2)
  expect(page).not_to have_selector('.error-help', wait: 2)
  
  if page.has_selector?('div.alert-danger')
    error_text = find('div.alert-danger').text
    File.write('/tmp/validation_error.html', page.html)
    raise "Validation failed: #{error_text}"
  end
end
```

## 2FA Setup (MUST BE FIRST!)

```ruby
before(:all) do
  # ✅ THESE MUST BE FIRST
  change_setting('TwoFactorAuthDisabledForUser', true)
  change_setting('TwoFactorAuthDisabledForAdmin', true)
  
  # Then other setup
  SetupHelper.feature_setup
  create_users
end
```

## Test Organization

```
spec/support/{feature}_feature_support/
├── {feature}_setup.rb          # Database, config, access controls
├── {feature}_user_setup.rb     # User creation, roles
├── {feature}_login.rb          # Authentication
├── {feature}_navigation.rb     # Page navigation, waits
├── {feature}_actions.rb        # UI interactions, forms
├── {feature}_expectations.rb   # Assertions
└── z_{feature}_main.rb         # Main module (includes all)
```

## Running Tests

```bash
# Standard headless run
bundle exec rspec spec/features/your_spec.rb

# With visible browser
app-scripts/not_headless_rspec.sh spec/features/your_spec.rb

# Capture full output
bundle exec rspec spec/features/your_spec.rb 2>&1 | tee /tmp/test_run.log | tail -100

# Specific test
bundle exec rspec spec/features/your_spec.rb:38

# Clean database first
app-scripts/clean-test-db.sh
```

## When You Get Stuck

1. **Save HTML:** `File.write('/tmp/debug.html', page.html)`
2. **Check sections:** `all('.mr-expander').each { |e| puts e[:id] }`
3. **List fields:** `all('input, select', visible: :all).each { |f| puts f[:name] }`
4. **Check visibility:** `all('input[name*="field"]', visible: :all).count`
5. **Run with browser:** `app-scripts/not_headless_rspec.sh`

## Full Documentation

- **Comprehensive Guide:** `docs/dev_reference/testing/feature-spec-development-guide.md`
- **Copilot Instructions:** `.github/copilot-instructions.md` (Feature Spec Development Patterns section)
- **Development Summary:** `docs/dev_reference/testing/grant-aims-development-summary.md`
