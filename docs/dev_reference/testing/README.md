# Testing Documentation Index

**⚠️ IMPORTANT:** Always use helper methods from `spec/support/feature_support.rb` - DO NOT write raw Capybara selectors or inspect HTML directly!

## Feature Spec Development Resources

### Quick Start

If you're new to feature spec development or need a quick reminder:

**Start Here:** [Helper Methods Reference](helper-methods-reference.md)

- Complete catalog of all helper methods
- Field interaction, section expansion, navigation
- Debug helpers for development
- Best practices and cheat sheet

**Then:** [Feature Spec Quick Reference](feature-spec-quick-reference.md)

- 3 critical patterns to remember
- Common errors and fixes
- Essential debug commands
- Big select and show_if patterns

### Comprehensive Guide

For detailed explanations, examples, and best practices:

**Read Next:** [Feature Spec Development Guide](feature-spec-development-guide.md)

- All UI patterns with complete examples
- Common pitfalls catalog
- Debugging techniques
- Test organization strategies
- Real implementation examples

### Grant Aims Case Study

To see these patterns applied in a real implementation:

**Case Study:** [Grant Aims Development Summary](grant-aims-development-summary.md)

- What was accomplished (Phases 1-5 complete)
- Key technical discoveries
- Helper module organization
- Metrics and lessons learned
- Files changed

### In-Context AI Guidance

AI assistants (Copilot, etc.) have access to patterns during development:

**AI Reference:** [Copilot Instructions - Feature Spec Section](../../../.github/copilot-instructions.md#feature-spec-development-patterns)

- Edit button AJAX pattern
- Hidden field handling
- Collapsible section pattern
- Show_if conditional visibility
- Big select interaction
- And more...

## Grant Aims Specific Documentation

### Implementation Status

Current state of the Grant Aims feature specs:

**Status Report:** [Grant Aims Implementation Status](../../features/grant_aims/IMPLEMENTATION_STATUS.md)

- Test progress (5 passing, 1 blocked)
- What's working, what needs fixing
- Infrastructure status

### Form Structure Analysis

HTML structure and selector information:

**Structure Guide:** [Grant Aims Form Structure Guide](../../features/grant_aims/FORM_STRUCTURE_GUIDE.md)

- HTML investigation results
- Key selectors
- mr-expander sections
- Field naming patterns

### Overview

General information about the Grant Aims tests:

**README:** [Grant Aims Feature Specs README](../../features/grant_aims/README.md)

- Quick links to all docs
- Test results
- Running tests
- Debugging tips

## Test Execution

### Running Tests

```bash
# Standard run (headless)
bundle exec rspec spec/system/your_spec.rb

# With visible browser for debugging
app-scripts/not_headless_rspec.sh spec/system/your_spec.rb

# Specific test
bundle exec rspec spec/system/your_spec.rb:38

# Clean database first
app-scripts/clean-test-db.sh
```

### Setup Requirements

```bash
# One-time after reboot
app-scripts/setup-dev-filestore.sh

# In before(:all) block - MUST BE FIRST
change_setting('TwoFactorAuthDisabledForUser', true)
change_setting('TwoFactorAuthDisabledForAdmin', true)
```

## Documentation Updates

### What Was Added

1. **Feature Spec Development Guide** (NEW)
   - Location: `docs/dev_reference/testing/feature-spec-development-guide.md`
   - Comprehensive patterns and best practices
   - ~700 lines of detailed guidance

2. **Feature Spec Quick Reference** (NEW)
   - Location: `docs/dev_reference/testing/feature-spec-quick-reference.md`
   - Essential patterns on one page
   - Quick fixes and debug commands

3. **Grant Aims Development Summary** (NEW)
   - Location: `docs/dev_reference/testing/grant-aims-development-summary.md`
   - Complete development journey
   - Lessons learned and metrics

4. **Copilot Instructions** (UPDATED)
   - Location: `.github/copilot-instructions.md`
   - Added "Feature Spec Development Patterns" section
   - ~400 lines of in-context guidance

5. **Grant Aims Implementation Status** (UPDATED)
   - Location: `spec/system/grant_aims/IMPLEMENTATION_STATUS.md`
   - Updated status from "tests pass but don't fill forms" to "Phases 1-5 fully working"
   - Phase 6 blocking issue documented

## Related Documentation

### Requirements

**Original Requirements:** `restructure-apps/docs/test_grant_aims_process.md`

- Test requirements
- How users interact with UI
- Status instructions
- Implementation approach

### General Testing

**Main Testing Approach:** `.github/copilot-instructions.md#testing-approach`

- RSpec framework
- Running tests
- Parallel execution
- Feature test tips

## Getting Help

### Debug Workflow

1. **Save HTML snapshot:** `File.write('/tmp/debug.html', page.html)`
2. **Check available sections:** `all('.mr-expander').each { |e| puts e[:id] }`
3. **List all fields:** `all('input, select', visible: :all).each { |f| puts f[:name] }`
4. **Run with visible browser:** `app-scripts/not_headless_rspec.sh`
5. **Examine HTML with Nokogiri:** See Quick Reference for commands

### Common Issues

| Problem | Where to Look |
|---------|---------------|
| Can't find field | Quick Reference → "Unable to find field" |
| Element not clickable | Development Guide → "Hidden Form Fields" |
| AJAX timing issues | Development Guide → "AJAX Timing and Validation" |
| Big select not working | Quick Reference → "Big Select Field Pattern" |
| Form doesn't save | Development Guide → "Edit Button AJAX Pattern" |

## For Future Feature Specs

### Recommended Workflow

1. **Review Quick Reference** - Remember the 3 critical patterns
2. **Copy Grant Aims helpers** - Use as templates for similar workflows
3. **Reference Development Guide** - When you encounter specific patterns
4. **Save HTML early and often** - Debug field names and structure
5. **Organize helpers by responsibility** - Setup, actions, expectations, etc.

### Helper Module Template

Generalized helpers live in the `spec/support` directory. Feature specific helpers appear in their own sub-directory.

```
spec/support/
├── feature_helper.rb
├── user_actions_setup.rb
├── feature_support.rb

spec/support/{feature}_feature_support/
├── {feature}_setup.rb          # Database, config, access controls
├── {feature}_user_setup.rb     # User creation, role assignment
├── {feature}_login.rb          # Authentication flows
├── {feature}_navigation.rb     # Page navigation, waiting
├── {feature}_actions.rb        # UI interactions, form filling
├── {feature}_expectations.rb   # Assertions and validations
└── z_{feature}_main.rb         # Main module that includes all
```

## Contributing

When you discover new patterns or pitfalls:

1. Update the Quick Reference with the pattern
2. Add detailed explanation to Development Guide
3. Update the common pitfalls table
4. Consider updating Copilot Instructions if broadly applicable
5. Document the discovery in your feature's summary

Keep this documentation living and growing as you learn more!
