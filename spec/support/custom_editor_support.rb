# frozen_string_literal: true

# Helper methods for testing the custom editor (rich text/wysiwyg) in system specs.
# Provides methods for:
# - Finding and interacting with custom editor elements
# - Typing, pasting, and formatting content
# - Toolbar button interactions including links and images
# - HTML to markdown conversion testing
#
# Include this module in your system specs:
#   include CustomEditorSupport
#
module CustomEditorSupport
  #############################################################################
  # Element Finders
  #############################################################################

  # Find the custom editor container for a given field name
  # @param field_name [String] The field name (e.g., 'notes')
  # @return [Capybara::Node::Element] The custom editor container element
  def find_custom_editor_container(field_name)
    find("[data-edit-field-name='#{field_name}'] .custom-editor-container", wait: 10)
  end

  # Find the contenteditable div for the custom editor
  # @param field_name [String] The field name
  # @return [Capybara::Node::Element] The contenteditable editor div
  def find_custom_editor(field_name)
    find("[data-edit-field-name='#{field_name}'] .custom-editor", wait: 10)
  end

  # Find the toolbar for the custom editor
  # @param field_name [String] The field name
  # @return [Capybara::Node::Element] The toolbar element
  def find_custom_editor_toolbar(field_name)
    find("[data-edit-field-name='#{field_name}'] .btn-toolbar", wait: 10)
  end

  # Find the hidden textarea that stores the markdown value
  # @param field_name [String] The field name
  # @return [Capybara::Node::Element] The hidden textarea
  def find_custom_editor_textarea(field_name)
    find("[data-edit-field-name='#{field_name}'] textarea.text-notes", visible: :all, wait: 10)
  end

  #############################################################################
  # Basic Editor Interactions
  #############################################################################

  # Focus the custom editor to show the toolbar
  # @param field_name [String] The field name
  def focus_custom_editor(field_name)
    editor = find_custom_editor(field_name)
    scroll_into_view(editor)
    editor.click
    sleep 0.3 # Allow toolbar to show
  end

  # Type text directly into the custom editor
  # @param field_name [String] The field name
  # @param text [String] The text to type
  def type_in_custom_editor(field_name, text)
    focus_custom_editor(field_name)
    editor = find_custom_editor(field_name)
    editor.send_keys(text)
    sleep 0.3 # Allow change event to fire
  end

  # Clear the custom editor content
  # @param field_name [String] The field name
  def clear_custom_editor(field_name)
    focus_custom_editor(field_name)
    editor = find_custom_editor(field_name)
    # Select all and delete
    editor.send_keys([:control, 'a'], :backspace)
    sleep 0.3
  end

  # Get the current HTML content of the custom editor
  # @param field_name [String] The field name
  # @return [String] The HTML content
  def get_custom_editor_html(field_name)
    editor = find_custom_editor(field_name)
    editor['innerHTML']
  end

  # Get the current markdown value from the hidden textarea
  # @param field_name [String] The field name
  # @return [String] The markdown content
  def get_custom_editor_markdown(field_name)
    # Trigger blur to ensure markdown is updated
    find('body').click
    sleep 0.6 # Wait for autoparse interval
    textarea = find_custom_editor_textarea(field_name)
    textarea.value
  end

  #############################################################################
  # Paste Simulation
  #############################################################################

  # Simulate pasting HTML content into the custom editor
  # This injects HTML directly and triggers the paste event handler
  # @param field_name [String] The field name
  # @param html_content [String] The HTML to paste
  def paste_html_into_custom_editor(field_name, html_content)
    focus_custom_editor(field_name)

    # Store the HTML content in a window variable
    page.execute_script('window._pasteHtmlContent = arguments[0];', html_content)

    # Execute the paste simulation
    script = <<~JS
      (function() {
        var editor = document.querySelector("[data-edit-field-name='#{field_name}'] .custom-editor");
        if (!editor) return { error: 'Editor not found' };

        // Set the HTML content
        editor.innerHTML = window._pasteHtmlContent;

        // Trigger paste event to invoke the conversion
        var pasteEvent = new Event('paste', { bubbles: true, cancelable: true });
        editor.dispatchEvent(pasteEvent);

        return { success: true };
      })();
    JS

    result = page.evaluate_script(script)
    sleep 0.5 # Wait for paste handler to complete

    result
  end

  #############################################################################
  # Toolbar Button Interactions
  #############################################################################

  # Click a toolbar button by its data-edit attribute
  # @param field_name [String] The field name
  # @param edit_command [String] The data-edit value (e.g., 'bold', 'italic', 'insertunorderedlist')
  def click_toolbar_button(field_name, edit_command)
    focus_custom_editor(field_name)
    toolbar = find_custom_editor_toolbar(field_name)
    button = toolbar.find("[data-edit='#{edit_command}']", wait: 5)
    scroll_into_view(button)
    button.click
    sleep 0.2
  end

  # Click the bold button
  def click_bold_button(field_name)
    click_toolbar_button(field_name, 'bold')
  end

  # Click the italic button
  def click_italic_button(field_name)
    click_toolbar_button(field_name, 'italic')
  end

  # Click the underline button
  def click_underline_button(field_name)
    click_toolbar_button(field_name, 'underline')
  end

  # Click the strikethrough button
  def click_strikethrough_button(field_name)
    click_toolbar_button(field_name, 'strikethrough')
  end

  # Click the subscript button
  def click_subscript_button(field_name)
    click_toolbar_button(field_name, 'subscript')
  end

  # Click the superscript button
  def click_superscript_button(field_name)
    click_toolbar_button(field_name, 'superscript')
  end

  # Click the unordered list button
  def click_bullet_list_button(field_name)
    click_toolbar_button(field_name, 'insertunorderedlist')
  end

  # Click the ordered list button
  def click_numbered_list_button(field_name)
    click_toolbar_button(field_name, 'insertorderedlist')
  end

  # Click the horizontal rule button
  def click_horizontal_rule_button(field_name)
    click_toolbar_button(field_name, 'inserthorizontalrule')
  end

  # Click the indent button
  def click_indent_button(field_name)
    click_toolbar_button(field_name, 'indent')
  end

  # Click the outdent button
  def click_outdent_button(field_name)
    click_toolbar_button(field_name, 'outdent')
  end

  # Click a heading button (h1, h2, etc.)
  # @param field_name [String] The field name
  # @param level [Integer] The heading level (1-4)
  def click_heading_button(field_name, level)
    click_toolbar_button(field_name, "formatBlock <h#{level}>")
  end

  # Click the paragraph button
  def click_paragraph_button(field_name)
    click_toolbar_button(field_name, 'formatBlock <p>')
  end

  #############################################################################
  # Advanced Toolbar Features (Links and Images)
  #############################################################################

  # Add a link using the link dropdown
  # @param field_name [String] The field name
  # @param url [String] The URL to link to
  def add_link_via_toolbar(field_name, url)
    focus_custom_editor(field_name)
    toolbar = find_custom_editor_toolbar(field_name)

    # Click the link dropdown toggle
    link_dropdown = toolbar.find("[data-edit='createLink']", visible: :all).ancestor('.btn-group')
    link_dropdown.find('.dropdown-toggle').click
    sleep 0.3

    # Fill in the URL and click Add
    link_dropdown.find("input[data-edit='createLink']").set(url)
    link_dropdown.find('button', text: 'Add').click
    sleep 0.3
  end

  # Add an image using the image dropdown
  # @param field_name [String] The field name
  # @param image_url [String] The image URL
  def add_image_via_toolbar(field_name, image_url)
    focus_custom_editor(field_name)
    toolbar = find_custom_editor_toolbar(field_name)

    # Click the image dropdown toggle
    image_dropdown = toolbar.find("[data-edit='insertImage']", visible: :all).ancestor('.btn-group')
    image_dropdown.find('.dropdown-toggle').click
    sleep 0.3

    # Fill in the URL and click Add
    image_dropdown.find("input[data-edit='insertImage']").set(image_url)
    image_dropdown.find('button.btn-editor-add-image').click
    sleep 0.3
  end

  #############################################################################
  # Text Selection
  #############################################################################

  # Select text in the editor using JavaScript
  # @param field_name [String] The field name
  # @param start_offset [Integer] Start position
  # @param end_offset [Integer] End position
  # @return [Hash] Result with success status and selected text
  def select_text_in_editor(field_name, start_offset, end_offset)
    script = <<~JS
      (function() {
        var editor = document.querySelector("[data-edit-field-name='#{field_name}'] .custom-editor");
        if (!editor || !editor.firstChild) return { error: 'Editor or content not found' };

        var range = document.createRange();
        var textNode = editor.firstChild;

        // Find the actual text node if wrapped in elements
        while (textNode && textNode.nodeType !== 3 && textNode.firstChild) {
          textNode = textNode.firstChild;
        }

        if (!textNode || textNode.nodeType !== 3) return { error: 'Text node not found' };

        var textLength = textNode.textContent.length;
        var safeStart = Math.min(#{start_offset}, textLength);
        var safeEnd = Math.min(#{end_offset}, textLength);

        range.setStart(textNode, safeStart);
        range.setEnd(textNode, safeEnd);

        var selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);

        return { success: true, selectedText: selection.toString() };
      })();
    JS

    page.evaluate_script(script)
  end

  # Select all text in the editor
  # @param field_name [String] The field name
  def select_all_text_in_editor(field_name)
    focus_custom_editor(field_name)
    editor = find_custom_editor(field_name)
    editor.send_keys([:control, 'a'])
    sleep 0.2
  end

  #############################################################################
  # JavaScript Conversion Testing
  #############################################################################

  # Test the html_to_markdown JavaScript function directly
  # @param html_content [String] The HTML content to convert
  # @return [Hash] Result containing markdown, cleanedHtml, originalHtml, or error
  def convert_html_to_markdown(html_content)
    page.execute_script('window._testHtmlContent = arguments[0];', html_content)

    script = <<~JS
      (function() {
        try {
          var htmlContent = window._testHtmlContent;
          var obj = { html: htmlContent };
          var result = _fpa.utils.html_to_markdown(obj);
          return {
            markdown: result,
            cleanedHtml: obj.html,
            originalHtml: htmlContent
          };
        } catch (e) {
          return {
            error: e.message,
            stack: e.stack
          };
        }
      })();
    JS

    page.evaluate_script(script)
  end
end
