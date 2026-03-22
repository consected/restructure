//= require app/masters.js

/**
 * Tests for _fpa.masters switchable ID functionality
 * These tests verify that the participant header correctly switches to show
 * the first non-"(none)" ID when multiple alternative IDs are configured.
 * See issue #872: Switchable ID on participant header should show the first not "(none)" ID
 */
describe('masters', function () {
  describe('init_switchable_ids', function () {
    var container;

    beforeEach(function () {
      // Create a test container in the document
      container = $('<div id="test-container"></div>');
      $('body').append(container);
    });

    afterEach(function () {
      // Clean up
      container.remove();
    });

    it("shows the first non-none ID when first ID is (none)", function () {
      // Set up HTML structure with first ID as (none)
      var html = `
        <div class="result-refs">
          <a href="#" class="switch_id glyphicon glyphicon-random" title="switch to Second ID"></a>
          <span class="alt-id-item first_id" data-id-label="First ID">(none)</span>
          <span class="alt-id-item second_id" data-id-label="Second ID" style="display: none">ID-12345</span>
          <span class="alt-id-item third_id" data-id-label="Third ID" style="display: none">(none)</span>
        </div>
      `;
      container.html(html);

      // Call the initialization function
      _fpa.masters.init_switchable_ids(container);

      // Verify the second ID is now visible (it's the first non-none)
      expect(container.find('.alt-id-item.first_id').is(':visible')).toBe(false);
      expect(container.find('.alt-id-item.second_id').is(':visible')).toBe(true);
      expect(container.find('.alt-id-item.third_id').is(':visible')).toBe(false);

      // Verify the switch button title is updated to the next ID
      expect(container.find('.switch_id').attr('title')).toBe('switch to Third ID');
    });

    it("keeps first ID visible when it has a value", function () {
      // Set up HTML structure with first ID having a value
      var html = `
        <div class="result-refs">
          <a href="#" class="switch_id glyphicon glyphicon-random" title="switch to Second ID"></a>
          <span class="alt-id-item first_id" data-id-label="First ID">ID-FIRST</span>
          <span class="alt-id-item second_id" data-id-label="Second ID" style="display: none">ID-12345</span>
          <span class="alt-id-item third_id" data-id-label="Third ID" style="display: none">(none)</span>
        </div>
      `;
      container.html(html);

      // Call the initialization function
      _fpa.masters.init_switchable_ids(container);

      // Verify the first ID remains visible
      expect(container.find('.alt-id-item.first_id').is(':visible')).toBe(true);
      expect(container.find('.alt-id-item.second_id').is(':visible')).toBe(false);
      expect(container.find('.alt-id-item.third_id').is(':visible')).toBe(false);
    });

    it("keeps first ID visible when all IDs are (none)", function () {
      // Set up HTML structure with all IDs as (none)
      var html = `
        <div class="result-refs">
          <a href="#" class="switch_id glyphicon glyphicon-random" title="switch to Second ID"></a>
          <span class="alt-id-item first_id" data-id-label="First ID">(none)</span>
          <span class="alt-id-item second_id" data-id-label="Second ID" style="display: none">(none)</span>
          <span class="alt-id-item third_id" data-id-label="Third ID" style="display: none">(none)</span>
        </div>
      `;
      container.html(html);

      // Call the initialization function
      _fpa.masters.init_switchable_ids(container);

      // Verify the first ID remains visible (fallback behavior)
      expect(container.find('.alt-id-item.first_id').is(':visible')).toBe(true);
      expect(container.find('.alt-id-item.second_id').is(':visible')).toBe(false);
      expect(container.find('.alt-id-item.third_id').is(':visible')).toBe(false);
    });

    it("skips multiple (none) IDs to find the first valid one", function () {
      // Set up HTML structure with first two IDs as (none)
      var html = `
        <div class="result-refs">
          <a href="#" class="switch_id glyphicon glyphicon-random" title="switch to Second ID"></a>
          <span class="alt-id-item first_id" data-id-label="First ID">(none)</span>
          <span class="alt-id-item second_id" data-id-label="Second ID" style="display: none">(none)</span>
          <span class="alt-id-item third_id" data-id-label="Third ID" style="display: none">ID-THIRD</span>
        </div>
      `;
      container.html(html);

      // Call the initialization function
      _fpa.masters.init_switchable_ids(container);

      // Verify the third ID is now visible (first non-none)
      expect(container.find('.alt-id-item.first_id').is(':visible')).toBe(false);
      expect(container.find('.alt-id-item.second_id').is(':visible')).toBe(false);
      expect(container.find('.alt-id-item.third_id').is(':visible')).toBe(true);

      // Verify the switch button title wraps around to the first ID
      expect(container.find('.switch_id').attr('title')).toBe('switch to First ID');
    });

    it("does not reinitialize already initialized containers", function () {
      // Set up HTML structure
      var html = `
        <div class="result-refs">
          <a href="#" class="switch_id glyphicon glyphicon-random" title="switch to Second ID"></a>
          <span class="alt-id-item first_id" data-id-label="First ID">(none)</span>
          <span class="alt-id-item second_id" data-id-label="Second ID" style="display: none">ID-12345</span>
        </div>
      `;
      container.html(html);

      // Call initialization twice
      _fpa.masters.init_switchable_ids(container);
      
      // Manually change visibility to simulate user interaction
      container.find('.alt-id-item.second_id').hide();
      container.find('.alt-id-item.first_id').show();
      
      // Call initialization again
      _fpa.masters.init_switchable_ids(container);

      // Verify the first ID remains visible (not re-initialized)
      expect(container.find('.alt-id-item.first_id').is(':visible')).toBe(true);
      expect(container.find('.alt-id-item.second_id').is(':visible')).toBe(false);
    });

    it("handles single ID without switching", function () {
      // Set up HTML structure with only one ID
      var html = `
        <div class="result-refs">
          <span class="alt-id-item first_id alt_id" data-id-label="First ID">ID-ONLY</span>
        </div>
      `;
      container.html(html);

      // Call the initialization function
      _fpa.masters.init_switchable_ids(container);

      // Verify the single ID remains visible
      expect(container.find('.alt-id-item.first_id').is(':visible')).toBe(true);
    });
  });
});
