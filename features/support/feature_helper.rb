module FeatureHelper
  def finish_form_formatting
    have_no_css('.formatting-block')
    have_no_css('.collapsing')
  end

  def scroll_to el_selector, options={}
    
    options[:check_it] = true if options[:check_it].nil?

    if all(el_selector).length == 0
      puts "The page does not have this selector to scroll to: #{el_selector}"
    else

      run_script = "document.querySelectorAll('#{el_selector.gsub("'", '"') }')[0].scrollTop += 100;"
      begin
        page.execute_script run_script
      rescue => e
        puts "Failed to run the scroll_to javascript: #{run_script}."
        puts e.backtrace.join("\n")
      end      
    end

    if options[:check_it]
      expect(page).to have_selector("#{el_selector}", visible: true)
    end

  end


end
World(FeatureHelper)
