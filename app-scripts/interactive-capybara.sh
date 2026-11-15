#!/bin/bash
# Allow interactive access to a Capybara session within the Rails debugger.
# Enables AI agents to collaborate with human operators of the browser to build new specs
# For example, when the debugger is shown, you can do anything that Capybara allows, and use existing helpers, such as:
#
#   setup_browser_console_capture
#   get_browser_console_logs
#   field = page.find("input,select,textarea", focused: true)
#   field_name = field["name"]
#   field_value = field["value"]
#   set_yes_no_field('is_ok_yes_no', 'yes')

NOT_HEADLESS=true INTERACTIVE=true bundle exec rspec spec/system/interactive_spec.rb
