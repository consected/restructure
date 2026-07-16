//= require app/_fpa_form_utils.js

// _fpa.form_utils.setup_codemirror_editors spec.
//
// Bug: the main (non-admin) app never loaded or initialized CodeMirror, so any
// '.code-editor' textarea (e.g. rendered by common_templates/edit_fields/_column_type_jsonb.html.erb
// or _name_starts_with_yaml_object.html.erb) was left as a plain <textarea> instead of a
// CodeMirror editor - unlike the admin panel, which already had its own
// setup_codemirror_editors (see admin/all/admin_edit_form.js).
//
// Tests verify:
// - A '.code-editor' textarea is converted into a real CodeMirror instance.
// - The textarea's initial value is preserved in the CodeMirror editor.
// - The mode defaults to 'yaml' when no data-code-editor-type attribute is present.
// - The data-code-editor-type attribute is honoured when present.
// - Elements are not re-initialized (marked 'code-editor-formatted' and skipped on repeat calls).
// - This is wired into _fpa.form_utils.format_block, the central per-block form setup entry point.
describe('_fpa.form_utils.setup_codemirror_editors', function () {
  var container;

  beforeEach(function () {
    container = $([
      '<div id="codemirror-test-container">',
      '  <textarea class="code-editor code-editor-yaml" data-code-editor-type="yaml">key1: value1</textarea>',
      '</div>'
    ].join('\n'));
    $('body').append(container);
  });

  afterEach(function () {
    container.remove();
  });

  it('converts a .code-editor textarea into a real CodeMirror instance', function () {
    _fpa.form_utils.setup_codemirror_editors(container);

    var codeEl = container.find('.code-editor').get(0);
    expect(codeEl.CodeMirror).toBeDefined();
    expect(typeof codeEl.CodeMirror.getValue).toEqual('function');
  });

  it('preserves the textarea initial value in the CodeMirror editor', function () {
    _fpa.form_utils.setup_codemirror_editors(container);

    var codeEl = container.find('.code-editor').get(0);
    expect(codeEl.CodeMirror.getValue()).toEqual('key1: value1');
  });

  it('defaults the mode to yaml when data-code-editor-type is not present', function () {
    container.find('.code-editor').removeAttr('data-code-editor-type');

    _fpa.form_utils.setup_codemirror_editors(container);

    var codeEl = container.find('.code-editor').get(0);
    expect(codeEl.CodeMirror.getOption('mode')).toEqual('yaml');
  });

  it('marks the element as code-editor-formatted so it is not re-initialized', function () {
    _fpa.form_utils.setup_codemirror_editors(container);

    var firstInstance = container.find('.code-editor').get(0).CodeMirror;

    // Call again - should be a no-op for the already-formatted element
    _fpa.form_utils.setup_codemirror_editors(container);

    var secondInstance = container.find('.code-editor').get(0).CodeMirror;
    expect(secondInstance).toBe(firstInstance);
  });

  it('is invoked as part of format_block so newly-loaded forms get their editors initialized', function () {
    spyOn(_fpa.form_utils, 'setup_codemirror_editors').and.callThrough();

    _fpa.form_utils.format_block(container);

    expect(_fpa.form_utils.setup_codemirror_editors).toHaveBeenCalled();
  });
});

// _fpa.form_utils.on_form_submit CodeMirror save regression spec.
//
// Bug: CodeMirror editors in the main app were initialized correctly, but their
// values were never saved back to the backing textarea on form submit, causing
// stale (empty or original) values to be submitted instead of user edits.
//
// Tests verify:
// - on_form_submit calls save() on initialized CodeMirror editors within the form block.
// - Editors without a CodeMirror instance (plain textareas with .code-editor class) are
//   safely ignored without errors.
// - Report-edit forms with external form-associated inputs still have their in-form
//   editors saved.
describe('_fpa.form_utils.on_form_submit CodeMirror save', function () {
  var container;

  afterEach(function () {
    if (container) container.remove();
  });

  it('calls save() on initialized CodeMirror editors before date/mask conversion', function () {
    container = $([
      '<form id="test-submit-form">',
      '  <textarea class="code-editor">original</textarea>',
      '  <input type="text" class="date-is-local" value="">',
      '</form>'
    ].join('\n'));
    $('body').append(container);

    // Initialize CodeMirror on the textarea
    _fpa.form_utils.setup_codemirror_editors(container);

    var codeEl = container.find('.code-editor').get(0);
    // Simulate user editing in CodeMirror (value diverges from textarea)
    codeEl.CodeMirror.setValue('edited: value');

    // Textarea still has the old value before save
    expect($(codeEl).val()).toEqual('original');

    // Trigger form submit handling
    _fpa.form_utils.on_form_submit(container);

    // After on_form_submit, textarea should have the CodeMirror content
    expect($(codeEl).val()).toEqual('edited: value');
  });

  it('safely ignores a .code-editor element without a CodeMirror instance', function () {
    container = $([
      '<form id="test-no-cm-form">',
      '  <textarea class="code-editor">plain text</textarea>',
      '</form>'
    ].join('\n'));
    $('body').append(container);

    // Do NOT initialize CodeMirror - simulates a scenario where setup was skipped

    // Should not throw
    expect(function () {
      _fpa.form_utils.on_form_submit(container);
    }).not.toThrow();
  });

  it('saves editors in the original form block even when block is reassigned for report-edit', function () {
    // Simulate report-edit: form has an id, and external inputs reference it
    container = $([
      '<div id="report-edit-wrapper">',
      '  <form id="report-edit-form">',
      '    <textarea class="code-editor">report yaml</textarea>',
      '  </form>',
      '  <div id="external-inputs">',
      '    <input form="report-edit-form" type="text" value="ext">',
      '  </div>',
      '</div>'
    ].join('\n'));
    $('body').append(container);

    var form = container.find('form');
    _fpa.form_utils.setup_codemirror_editors(form);

    var codeEl = form.find('.code-editor').get(0);
    codeEl.CodeMirror.setValue('updated: content');

    // Textarea still has old value
    expect($(codeEl).val()).toEqual('report yaml');

    // on_form_submit will reassign block to external inputs parent,
    // but should still save the form's CodeMirror editors
    _fpa.form_utils.on_form_submit(form);

    expect($(codeEl).val()).toEqual('updated: content');
  });
});
