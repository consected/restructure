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
#   codemirror_set_value(form_id: 'edit_dynamic_model_123', value: 'new content')
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
  # @param value [String] The new content to set
  # @param sync [Boolean] Whether to sync to the underlying textarea (default: true)
  def codemirror_set_value(form_id:, value:, sync: true)
    escaped_value = value.gsub('\\', '\\\\\\\\').gsub("\n", '\\n').gsub("'", "\\\\'")
    page.execute_script(<<~JS)
      var form = document.getElementById('#{form_id}');
      var editor = form ? form.querySelector('textarea.code-editor') : null;
      if (editor && editor.CodeMirror) {
        editor.CodeMirror.setValue('#{escaped_value}');
        #{sync ? 'editor.CodeMirror.save();' : ''}
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
        #{sync ? 'editor.CodeMirror.save();' : ''}
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
        #{sync ? 'editor.CodeMirror.save();' : ''}
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
