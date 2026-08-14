# frozen_string_literal: true

# Helper methods for interacting with CodeMirror editors in system specs
#
# CodeMirror wraps textareas and requires special handling through JavaScript
# to read/modify content. These methods provide a clean interface for common
# operations like getting/setting values, prepending text, and regex replacements.
#
# Usage:
#   # Get editor content
#   content = codemirror_get_value(form_id: 'edit_dynamic_model_123')
#
#   # Set editor content
#   codemirror_set_value(form_id: 'edit_dynamic_model_123', field_name: 'config', value: 'new content')
#
#   # Prepend text
#   codemirror_prepend(form_id: 'edit_dynamic_model_123', text: "# Header\n")
#
#   # Replace with regex
#   codemirror_replace(form_id: 'edit_dynamic_model_123', pattern: '^old', replacement: 'new')
#
#   # Sync to textarea before form submission
#   codemirror_save(form_id: 'edit_dynamic_model_123')
#
module CodemirrorEditorSupport
  # Wait until a CodeMirror editor has been initialized on the target textarea.
  # The CodeMirror library is a large asset and, on its first request in a test run,
  # Sprockets' live compilation can take noticeably longer than the fixed sleeps used
  # elsewhere in these specs, so the textarea's `.CodeMirror` property may not be set
  # yet even after `finish_form_formatting`. Polling here avoids flaky failures where
  # `codemirror_set_value`/`codemirror_get_value` silently no-op because the editor
  # hasn't attached.
  # @param form_id [String] The ID of the form containing the editor
  # @param field_name [String, nil] The data-attr-name of a specific editor in the form
  # @param wait [Numeric] maximum seconds to wait
  def wait_for_codemirror_editor(form_id:, field_name: nil, wait: 20)
    editor_selector = if field_name
                        "textarea.code-editor[data-attr-name='#{field_name}']"
                      else
                        'textarea.code-editor'
                      end
    Timeout.timeout(wait) do
      loop do
        ready = page.evaluate_script(<<~JS)
          (function() {
            var form = document.getElementById('#{form_id}');
            var editor = form ? form.querySelector("#{editor_selector}") : null;
            return !!(editor && editor.CodeMirror);
          })()
        JS
        break if ready

        sleep 0.25
      end
    end
  end

  # Get the current value from a CodeMirror editor
  # @param form_id [String] The ID of the form containing the editor
  # @return [String, nil] The current editor content or nil if not found
  def codemirror_get_value(form_id:)
    page.evaluate_script(<<~JS)
      (function() {
        var form = document.getElementById('#{form_id}');
        var editor = form ? form.querySelector('textarea.code-editor') : null;
        return editor && editor.CodeMirror ? editor.CodeMirror.getValue() : null;
      })()
    JS
  end

  # Set the value in a CodeMirror editor
  # @param form_id [String] The ID of the form containing the editor
  # @param field_name [String, nil] The data-attr-name of a specific editor in the form
  # @param value [String] The new content to set
  # @param sync [Boolean] Whether to sync to the underlying textarea (default: true)
  def codemirror_set_value(form_id:, value:, field_name: nil, sync: true)
    escaped_value = value.gsub('\\', '\\\\\\\\').gsub("\n", '\\n').gsub("'", "\\\\'")
    editor_selector = if field_name
                        "textarea.code-editor[data-attr-name='#{field_name}']"
                      else
                        'textarea.code-editor'
                      end
    page.execute_script(<<~JS)
      var form = document.getElementById('#{form_id}');
      var editor = form ? form.querySelector("#{editor_selector}") : null;
      if (editor && editor.CodeMirror) {
        editor.CodeMirror.setValue('#{escaped_value}');
        #{'editor.CodeMirror.save();' if sync}
      }
    JS
  end

  # Prepend text to the beginning of a CodeMirror editor's content
  # @param form_id [String] The ID of the form containing the editor
  # @param text [String] The text to prepend
  # @param sync [Boolean] Whether to sync to the underlying textarea (default: false)
  def codemirror_prepend(form_id:, text:, sync: false)
    escaped_text = text.gsub('\\', '\\\\\\\\').gsub("\n", '\\n').gsub("'", "\\\\'")
    page.execute_script(<<~JS)
      var form = document.getElementById('#{form_id}');
      var editor = form ? form.querySelector('textarea.code-editor') : null;
      if (editor && editor.CodeMirror) {
        var currentValue = editor.CodeMirror.getValue();
        editor.CodeMirror.setValue('#{escaped_text}' + currentValue);
        #{'editor.CodeMirror.save();' if sync}
      }
    JS
  end

  # Replace text in a CodeMirror editor using a regex pattern
  # @param form_id [String] The ID of the form containing the editor
  # @param pattern [String] JavaScript regex pattern (without delimiters)
  # @param replacement [String] The replacement text
  # @param flags [String] Regex flags (default: 'gm' for global/multiline)
  # @param sync [Boolean] Whether to sync to the underlying textarea (default: true)
  def codemirror_replace(form_id:, pattern:, replacement:, flags: 'gm', sync: true)
    escaped_replacement = replacement.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'")
    page.execute_script(<<~JS)
      var form = document.getElementById('#{form_id}');
      var editor = form ? form.querySelector('textarea.code-editor') : null;
      if (editor && editor.CodeMirror) {
        var currentValue = editor.CodeMirror.getValue();
        var fixedValue = currentValue.replace(/#{pattern}/#{flags}, '#{escaped_replacement}');
        editor.CodeMirror.setValue(fixedValue);
        #{'editor.CodeMirror.save();' if sync}
      }
    JS
  end

  # Sync the CodeMirror content back to the underlying textarea
  # This is required before form submission to ensure the textarea has current content
  # @param form_id [String] The ID of the form containing the editor
  def codemirror_save(form_id:)
    page.execute_script(<<~JS)
      var form = document.getElementById('#{form_id}');
      var editor = form ? form.querySelector('textarea.code-editor') : null;
      if (editor && editor.CodeMirror) {
        editor.CodeMirror.save();
      }
    JS
  end
end
