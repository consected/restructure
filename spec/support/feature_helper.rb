# frozen_string_literal: true

module FeatureHelper
  # Allow the test to pause and enter an interactive debugging session.
  # Issue a `sleep 1` command in the debugger to allow the server to process requests.
  # Or use `finish_form_formatting`, `finish_page_loading` or similar Capybara methods
  # to wait for the requests to complete.
  def interactive_debug_session
    debugger
  end

  # Ensure that the app is set to use markdown for notes fields.
  # This is important for tests that rely on rich text editors (often notes or details fields).
  def setup_markdown_notes(app_type: nil)
    @app_type = app_type if app_type
    @app_type.app_configurations.where(name: 'notes field format').update_all(disabled: true)
    Admin::AppConfiguration.create!(
      name: 'notes field format',
      value: 'markdown',
      app_type: @app_type,
      current_admin: @admin
    )
  end

  def scroll_into_view(element)
    page.execute_script('arguments[0].scrollIntoView(true);', element)
  end

  def scroll_to(el_selector, options = {})
    options[:check_it] = true if options[:check_it].nil?

    puts "FeatureHelper#scroll_to: Scrolling to #{el_selector}"
    if all(el_selector).present?

      run_script = "document.querySelectorAll('#{el_selector.gsub("'", '"')}')[0].scrollTop += 100;"
      begin
        page.execute_script run_script
      rescue StandardError => e
        puts "Failed to run the scroll_to javascript: #{run_script}."
        puts e.backtrace.join("\n")
      end
    end

    expect(page).to have_selector(el_selector.to_s, visible: true) if options[:check_it]
  end

  def force_modal_hide
    run_script = "var el = $('.modal'); el.on('shown.bs.modal', function(){ el.modal('hide');});"
    begin
      page.execute_script run_script
    rescue StandardError => e
      puts "Failed to run the scroll_to javascript: #{run_script}."
      puts e.backtrace.join("\n")
    end
  end
end
