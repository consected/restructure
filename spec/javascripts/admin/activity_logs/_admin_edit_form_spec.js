//= require admin/activity_logs/admin_edit_form.js

/**
 * Tests for _fpa_admin.activity_logs.admin_edit_form
 *
 * Issue #990: Javascript error in activity log admin panel
 *
 * The bug: in setup_find_activity(), the click handler calls
 * $(this).stopPropagation() which throws:
 *   "Uncaught TypeError: $(...).stopPropagation is not a function"
 * because stopPropagation() is a method on native Event objects,
 * not on jQuery-wrapped elements.
 *
 * The fix should change the handler to accept the event parameter
 * and call event.stopPropagation() instead.
 *
 * These tests verify that clicking an li.activity-list-name element
 * calls stopPropagation() on the event object, not on $(this).
 */
describe('admin_edit_form', function () {
  describe('setup_find_activity', function () {
    var container, mockCodeMirror, mockCursor;

    beforeEach(function () {
      // Ensure the _fpa_admin namespace exists
      if (typeof _fpa_admin === 'undefined') {
        window._fpa_admin = {};
      }
      if (!_fpa_admin.activity_logs) {
        _fpa_admin.activity_logs = {};
      }

      // Mock CodeMirror cursor
      mockCursor = {
        findNext: jasmine.createSpy('findNext'),
        from: jasmine.createSpy('from').and.returnValue({ line: 5, ch: 0 }),
        to: jasmine.createSpy('to').and.returnValue({ line: 5, ch: 15 })
      };

      // Mock CodeMirror instance
      mockCodeMirror = {
        getSearchCursor: jasmine.createSpy('getSearchCursor').and.returnValue(mockCursor),
        scrollIntoView: jasmine.createSpy('scrollIntoView'),
        setSelection: jasmine.createSpy('setSelection'),
        lastLine: jasmine.createSpy('lastLine').and.returnValue(100)
      };

      // Build the DOM structure that setup_find_activity expects
      container = $([
        '<div id="test-admin-edit-form">',
        '  <ul>',
        '    <li class="activity-list-name" data-al-elt-block="#block-1">',
        '      initial_review',
        '    </li>',
        '  </ul>',
        '  <div class="code-editor"></div>',
        '  <div id="block-1" class="activity-list-item-block in"></div>',
        '  <input id="extra_log_type" />',
        '</div>'
      ].join('\n'));
      $('body').append(container);

      // Attach the mock CodeMirror instance to the .code-editor DOM element
      container.find('.code-editor').get(0).CodeMirror = mockCodeMirror;

      // Stub Bootstrap collapse if not available
      if (!$.fn.collapse) {
        $.fn.collapse = jasmine.createSpy('collapse');
      }
    });

    afterEach(function () {
      container.remove();
    });

    it('calls stopPropagation on the event object when an activity list name is clicked - Issue #990', function () {
      // Arrange: set up the admin edit form which binds the click handler
      _fpa_admin.activity_logs.admin_edit_form.setup(container, {});

      // Create a jQuery event and spy on its stopPropagation method
      var clickEvent = $.Event('click');
      spyOn(clickEvent, 'stopPropagation');

      var $li = container.find('li.activity-list-name');

      // Act: trigger the click; catch any TypeError from the buggy code
      // so we can still assert cleanly below
      try {
        $li.trigger(clickEvent);
      } catch (e) {
        // The buggy code throws:
        //   TypeError: $(...).stopPropagation is not a function
        // We catch it here so the expectation below produces a clear failure
        // message instead of an unhandled exception.
      }

      // Assert: stopPropagation should have been called on the event object.
      // With the bug, $(this).stopPropagation() throws before reaching this,
      // and the spy on clickEvent.stopPropagation is never invoked => FAILS.
      expect(clickEvent.stopPropagation).toHaveBeenCalled();
    });
  });
});
