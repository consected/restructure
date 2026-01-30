/**
 * Page title management class.
 * Updates the browser tab title to reflect the current UI context.
 *
 * Issue: #871 - Change page title to be more descriptive of current state
 * Requirements:
 * - Masters search pages: show selected search tab name
 * - Report page: show report name
 * - Admin page: show admin page name
 * - Page showing "view" page layout: show the Page title
 */
_fpa.page_title = class {
  // Store the original page title for reset purposes
  static original_title = null;
  static separator = ' - ';
  static _search_tabs_bound = false;

  /**
   * Initialize the page title module by storing the original title.
   * Called once during page load.
   */
  static init() {
    if (!_fpa.page_title.original_title) {
      _fpa.page_title.original_title = document.title;
    }
  }

  /**
   * Update the browser tab title with context-specific information.
   * Format: "{context_title} - {env_name}"
   * @param {string} context_title - The contextual title to display (e.g., "Simple Search", "My Report")
   */
  static update(context_title) {
    _fpa.page_title.init();
    if (context_title && context_title.trim()) {
      document.title = context_title.trim() + _fpa.page_title.separator + _fpa.env_name;
    }
  }

  /**
   * Reset the browser tab title to the original page title.
   */
  static reset() {
    _fpa.page_title.init();
    document.title = _fpa.page_title.original_title;
  }

  /**
   * Update title for search results context.
   * @param {string} search_type - Optional search type descriptor (e.g., "Simple Search", "Advanced Search")
   */
  static for_search_results(search_type) {
    var title = search_type ? search_type + ' results' : 'results';
    _fpa.page_title.update(title);
  }

  /**
   * Update title for a report page.
   * @param {string} report_name - The name of the report being viewed
   */
  static for_report(report_name) {
    if (report_name) {
      _fpa.page_title.update(report_name);
    }
  }

  /**
   * Update title for an admin page.
   * @param {string} admin_page_name - The name of the admin page being viewed
   */
  static for_admin(admin_page_name) {
    if (admin_page_name) {
      _fpa.page_title.update('Admin: ' + admin_page_name);
    }
  }

  /**
   * Update title for a page layout (view/standalone page).
   * @param {string} page_label - The label of the page layout
   */
  static for_page_layout(page_label) {
    if (page_label) {
      _fpa.page_title.update(page_label);
    }
  }

  /**
   * Bind event handlers for search tab clicks to update page title dynamically.
   * Uses namespaced events and a guard to prevent multiple bindings.
   */
  static bind_search_tabs() {
    // Prevent multiple bindings
    if (_fpa.page_title._search_tabs_bound) {
      return;
    }
    _fpa.page_title._search_tabs_bound = true;

    // Handle search selector buttons (Simple Search, Advanced Search, Report tabs)
    // Use namespaced event to allow for clean unbinding if needed
    $(document).on('click.fpa_page_title', '.search-selector-btn', function () {
      var tab_text = $(this).text().trim();
      if (tab_text) {
        _fpa.page_title.update(tab_text);
      }
    });

    // Handle Bootstrap collapse events for search forms
    $(document).on('show.bs.collapse.fpa_page_title', '#master-search-accordion .panel-collapse', function () {
      var panel_id = $(this).attr('id');
      var btn = $('[data-target="#' + panel_id + '"]');
      if (btn.length) {
        var tab_text = btn.text().trim();
        if (tab_text) {
          _fpa.page_title.update(tab_text);
        }
      }
    });
  }
};
