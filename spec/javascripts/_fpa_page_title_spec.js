//= require app/_fpa.js

/**
 * Tests for the _fpa.page_title module.
 * This module manages the browser tab title to reflect the current UI context.
 * 
 * Issue: #871 - Change page title to be more descriptive of current state
 * Requirements:
 * - Masters search pages: show selected search tab name
 * - Report page: show report name  
 * - Admin page: show admin page name
 * - Page showing "view" page layout: show the Page title
 */
describe('page_title', function () {
  
  var originalTitle;
  
  beforeEach(function () {
    // Store and reset original title before each test
    originalTitle = document.title;
    _fpa.page_title.original_title = null;
    _fpa.env_name = 'Test Env';
  });
  
  afterEach(function () {
    // Restore original title after each test
    document.title = originalTitle;
  });

  describe('init', function () {
    it('stores the original page title on first call', function () {
      document.title = 'Initial Page Title';
      _fpa.page_title.init();
      
      expect(_fpa.page_title.original_title).toBe('Initial Page Title');
    });
    
    it('does not overwrite original title on subsequent calls', function () {
      document.title = 'First Title';
      _fpa.page_title.init();
      
      document.title = 'Changed Title';
      _fpa.page_title.init();
      
      expect(_fpa.page_title.original_title).toBe('First Title');
    });
  });

  describe('update', function () {
    it('sets document title with context and environment name', function () {
      _fpa.page_title.update('Simple Search');
      
      expect(document.title).toBe('Simple Search - Test Env');
    });
    
    it('trims whitespace from context title', function () {
      _fpa.page_title.update('  Advanced Search  ');
      
      expect(document.title).toBe('Advanced Search - Test Env');
    });
    
    it('does not update title when context is empty', function () {
      document.title = 'Original';
      _fpa.page_title.update('');
      
      expect(document.title).toBe('Original');
    });
    
    it('does not update title when context is whitespace only', function () {
      document.title = 'Original';
      _fpa.page_title.update('   ');
      
      expect(document.title).toBe('Original');
    });
    
    it('does not update title when context is null', function () {
      document.title = 'Original';
      _fpa.page_title.update(null);
      
      expect(document.title).toBe('Original');
    });
    
    it('does not update title when context is undefined', function () {
      document.title = 'Original';
      _fpa.page_title.update(undefined);
      
      expect(document.title).toBe('Original');
    });
  });

  describe('reset', function () {
    it('restores document title to original value', function () {
      document.title = 'Original Title';
      _fpa.page_title.init();
      
      _fpa.page_title.update('Some Context');
      expect(document.title).toBe('Some Context - Test Env');
      
      _fpa.page_title.reset();
      expect(document.title).toBe('Original Title');
    });
    
    it('initializes original title if not already set', function () {
      document.title = 'Current Title';
      _fpa.page_title.original_title = null;
      
      _fpa.page_title.reset();
      
      expect(_fpa.page_title.original_title).toBe('Current Title');
    });
  });

  describe('for_search_results', function () {
    it('sets title with search type when provided', function () {
      _fpa.page_title.for_search_results('Simple Search');
      
      expect(document.title).toBe('Simple Search results - Test Env');
    });
    
    it('sets generic results title when search type is not provided', function () {
      _fpa.page_title.for_search_results(null);
      
      expect(document.title).toBe('results - Test Env');
    });
    
    it('sets generic results title when search type is empty', function () {
      _fpa.page_title.for_search_results('');
      
      expect(document.title).toBe('results - Test Env');
    });
  });

  describe('for_report', function () {
    it('sets title with report name', function () {
      _fpa.page_title.for_report('User Activity Report');
      
      expect(document.title).toBe('User Activity Report - Test Env');
    });
    
    it('does not update title when report name is empty', function () {
      document.title = 'Original';
      _fpa.page_title.for_report('');
      
      expect(document.title).toBe('Original');
    });
    
    it('does not update title when report name is null', function () {
      document.title = 'Original';
      _fpa.page_title.for_report(null);
      
      expect(document.title).toBe('Original');
    });
  });

  describe('for_admin', function () {
    it('sets title with Admin prefix and page name', function () {
      _fpa.page_title.for_admin('User Access Controls');
      
      expect(document.title).toBe('Admin: User Access Controls - Test Env');
    });
    
    it('does not update title when admin page name is empty', function () {
      document.title = 'Original';
      _fpa.page_title.for_admin('');
      
      expect(document.title).toBe('Original');
    });
    
    it('does not update title when admin page name is null', function () {
      document.title = 'Original';
      _fpa.page_title.for_admin(null);
      
      expect(document.title).toBe('Original');
    });
  });

  describe('for_page_layout', function () {
    it('sets title with page layout label', function () {
      _fpa.page_title.for_page_layout('Dashboard Overview');
      
      expect(document.title).toBe('Dashboard Overview - Test Env');
    });
    
    it('does not update title when page label is empty', function () {
      document.title = 'Original';
      _fpa.page_title.for_page_layout('');
      
      expect(document.title).toBe('Original');
    });
    
    it('does not update title when page label is null', function () {
      document.title = 'Original';
      _fpa.page_title.for_page_layout(null);
      
      expect(document.title).toBe('Original');
    });
  });

  describe('bind_search_tabs', function () {
    it('is a function that can be called without error', function () {
      expect(typeof _fpa.page_title.bind_search_tabs).toBe('function');
      
      // Should not throw when called
      expect(function () {
        _fpa.page_title.bind_search_tabs();
      }).not.toThrow();
    });
  });

  describe('separator', function () {
    it('uses configured separator in title format', function () {
      _fpa.page_title.separator = ' | ';
      _fpa.page_title.update('Test Context');
      
      expect(document.title).toBe('Test Context | Test Env');
      
      // Reset separator
      _fpa.page_title.separator = ' - ';
    });
  });

});
