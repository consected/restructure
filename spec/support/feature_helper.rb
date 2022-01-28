# frozen_string_literal: true

module FeatureHelper
  def scroll_to(el_selector, options = {})
    options[:check_it] = true if options[:check_it].nil?

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
