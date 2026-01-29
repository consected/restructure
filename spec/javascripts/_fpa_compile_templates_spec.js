//= require app/_fpa.js

// _fpa.compile_templates Spec
//
// Tests the client-side template compilation behaviour after server-side precompilation.
// With precompiled templates, compile_templates() should:
// - Alias _fpa.templates to Handlebars.templates
// - Alias _fpa.partials to Handlebars.partials
// - Add status-compiled class to body
// - Remove status-compiling class from body
// - Make precompiled templates available via _fpa.templates
//
// The new architecture eliminates client-side Handlebars.compile() calls since
// templates are precompiled on the server and self-register to Handlebars.templates.

describe('_fpa.compile_templates', function () {
  beforeEach(function () {
    // Reset body classes
    $('body').removeClass('status-compiling status-compiled initial-compiling');
    
    // Clear any existing templates
    _fpa.templates = {};
    _fpa.partials = {};
    Handlebars.templates = {};
    Handlebars.partials = {};
  });

  describe('registry aliasing', function () {
    it('sets _fpa.templates to reference Handlebars.templates', function () {
      _fpa.compile_templates();

      expect(_fpa.templates).toBe(Handlebars.templates);
    });

    it('sets _fpa.partials to reference Handlebars.partials', function () {
      _fpa.compile_templates();

      expect(_fpa.partials).toBe(Handlebars.partials);
    });

    it('preserves existing templates in Handlebars.templates', function () {
      // Simulate a precompiled template that registered itself
      Handlebars.templates['precompiled-template'] = function () { return '<div>test</div>'; };

      _fpa.compile_templates();

      expect(_fpa.templates['precompiled-template']).toBeDefined();
      expect(_fpa.templates['precompiled-template']()).toEqual('<div>test</div>');
    });

    it('preserves existing partials in Handlebars.partials', function () {
      // Simulate a precompiled partial that registered itself
      Handlebars.partials['precompiled-partial'] = function () { return '<span>partial</span>'; };

      _fpa.compile_templates();

      expect(_fpa.partials['precompiled-partial']).toBeDefined();
    });
  });

  describe('body class management', function () {
    it('adds status-compiled class to body', function () {
      _fpa.compile_templates();

      expect($('body').hasClass('status-compiled')).toBe(true);
    });

    it('removes status-compiling class from body', function () {
      $('body').addClass('status-compiling');

      _fpa.compile_templates();

      expect($('body').hasClass('status-compiling')).toBe(false);
    });

    it('removes initial-compiling class from body', function () {
      $('body').addClass('initial-compiling');

      _fpa.compile_templates();

      expect($('body').hasClass('initial-compiling')).toBe(false);
    });
  });

  describe('template availability after compilation', function () {
    beforeEach(function () {
      // Simulate precompiled templates that have self-registered
      Handlebars.templates['search-results-template'] = Handlebars.compile('<div class="search-results">{{query}}</div>');
      Handlebars.templates['master-panel-template'] = Handlebars.compile('<div class="master-panel">{{title}}</div>');
      Handlebars.partials['field_label'] = Handlebars.compile('<label>{{label}}</label>');
    });

    it('makes templates accessible via _fpa.templates', function () {
      _fpa.compile_templates();

      expect(_fpa.templates['search-results-template']).toBeDefined();
      expect(_fpa.templates['master-panel-template']).toBeDefined();
    });

    it('makes partials accessible via _fpa.partials', function () {
      _fpa.compile_templates();

      expect(_fpa.partials['field_label']).toBeDefined();
    });

    it('templates render correctly with data', function () {
      _fpa.compile_templates();

      var result = _fpa.templates['search-results-template']({ query: 'test search' });

      expect(result).toContain('test search');
      expect(result).toContain('search-results');
    });
  });
});

describe('_fpa.setup_template_source', function () {
  // Tests for the preprocessing function that should match server-side behaviour
  
  describe('embedded_report shorthand', function () {
    it('converts embedded_report_name to helper syntax', function () {
      var source = '{{embedded_report_my_report}}';
      var result = _fpa.setup_template_source(source);

      expect(result).toEqual("{{embedded_report 'my_report' true}}");
    });
  });

  describe('glyphicon shorthand', function () {
    it('converts glyphicon_name to helper syntax', function () {
      var source = '{{glyphicon_pencil}}';
      var result = _fpa.setup_template_source(source);

      expect(result).toEqual("{{glyphicon 'pencil' true}}");
    });
  });

  describe('tag_format shorthand', function () {
    it('converts tag::format to tag_format helper', function () {
      var source = '{{name::uppercase}}';
      var result = _fpa.setup_template_source(source);

      expect(result).toEqual("{{tag_format name 'uppercase'}}");
    });

    it('converts tag::format::args to tag_format helper with multiple args', function () {
      var source = '{{value::format::1::2}}';
      var result = _fpa.setup_template_source(source);

      expect(result).toEqual("{{tag_format value 'format' '1' '2'}}");
    });
  });

  describe('mixed content', function () {
    it('transforms multiple patterns in one source', function () {
      var source = '<div>{{glyphicon_edit}} {{name::uppercase}}</div>';
      var result = _fpa.setup_template_source(source);

      expect(result).toContain("{{glyphicon 'edit' true}}");
      expect(result).toContain("{{tag_format name 'uppercase'}}");
    });
  });

  describe('standard syntax preservation', function () {
    it('preserves regular variables', function () {
      var source = '{{name}}';
      var result = _fpa.setup_template_source(source);

      expect(result).toEqual('{{name}}');
    });

    it('preserves block helpers', function () {
      var source = '{{#if test}}content{{/if}}';
      var result = _fpa.setup_template_source(source);

      expect(result).toEqual('{{#if test}}content{{/if}}');
    });
  });
});
