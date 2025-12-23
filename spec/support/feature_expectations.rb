# frozen_string_literal: true

module FeatureExpectations
  def expect_field_to_have_value(field_name, value)
    expect(element_for_field(field_name).value).to eq value
  end

  def expect_no_validation_errors
    finish_page_loading
    finish_form_formatting
    sleep 0.5
    return unless flashed_alert?('danger') || flashed_alert?('warning')

    msgs = alert_messages.join(' | ')
    puts_debug "⚠️  Validation errors: #{msgs}"
    available_form_fields
    puts_form_validation_errors
    save_html_snapshot('/tmp/spec-form-validation-error.html')
    expect(true).to be_falsey, "Presentation date assignment failed with validation errors: #{msgs}"
  end
end
