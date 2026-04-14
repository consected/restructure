# Handlebars Server-Side Precompilation Plan

**GitHub Issue:** [#873 - Move handlebars template and partial compilation to the server](https://github.com/consected/restructure/issues/873)

## Overview

Move Handlebars template and partial compilation from client-side JavaScript to server-side precompilation using the `handlebars` CLI. Templates will be precompiled to JavaScript files served as static assets from `public/handlebars/`, significantly reducing browser workload and improving page load performance.

## Current Architecture

### Current Flow

```
Page Load → AJAX fetch templates (/pages/<version>/template)
         → Returns HTML with <script type="text/x-handlebars-template"> tags
         → Client calls _fpa.compile_templates()
         → For each template: Handlebars.compile(source)
         → Store compiled functions in _fpa.templates and _fpa.partials
```

### Current Template Loading

1. **Inline templates:** Some templates embedded directly in main page markup
2. **AJAX-loaded templates:** Most templates fetched via `/pages/<version>/template` endpoint
3. **Client-side compilation:** All templates compiled in browser using `Handlebars.compile()`

## New Architecture

### New Flow

```
Page Load → Include precompiled JS for inline templates (<script src="...">)
         → AJAX fetch template response (contains <script src="..."> tags)
         → Browser loads precompiled JS files
         → Precompiled JS self-registers to Handlebars.templates/partials
         → _fpa.templates = Handlebars.templates (aliased reference)
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Cleanup strategy | Delete ALL files on startup | No value in keeping stale compiled files |
| Fallback behavior | None - fail if CLI unavailable | Consistent behavior, avoid silent degradation |
| Template registry | `_fpa.templates = Handlebars.templates` | Use Handlebars' built-in registries |
| Partial registration | CLI `--partial` flag | Auto-registers to `Handlebars.partials` |
| Minification | Production only (`-m` flag) | Reduce file sizes in production |
| Source maps | Development only | Enable debugging in development |
| Handlebars library | Keep full version | Required for `{{template}}`, `{{compile_template}}` helpers |

## Implementation Components

### 1. New Initializer: `config/initializers/handlebars_precompiler.rb`

Sets up directories, validates CLI availability, and cleans up on startup.

```ruby
# frozen_string_literal: true

module HandlebarsPrecompiler
  HANDLEBARS_CLI = ENV.fetch('HANDLEBARS_CLI', 'handlebars')
  TMP_DIR = Rails.root.join('tmp', 'handlebars')
  PUBLIC_DIR = Rails.root.join('public', 'handlebars')

  class << self
    def cli_available?
      @cli_available ||= system("which #{HANDLEBARS_CLI} > /dev/null 2>&1")
    end

    def cli_path
      @cli_path ||= `which #{HANDLEBARS_CLI}`.strip
    end

    def setup_directories
      FileUtils.mkdir_p(TMP_DIR)
      FileUtils.mkdir_p(PUBLIC_DIR)
    end

    def cleanup_tmp_dir
      FileUtils.rm_rf(Dir.glob(TMP_DIR.join('*')))
    end

    def cleanup_public_dir
      # Delete ALL precompiled files on startup
      FileUtils.rm_rf(Dir.glob(PUBLIC_DIR.join('*.js')))
      FileUtils.rm_rf(Dir.glob(PUBLIC_DIR.join('*.map')))
    end

    def minify?
      Rails.env.production?
    end

    def source_maps?
      !Rails.env.production?
    end
  end
end

Rails.application.config.after_initialize do
  HandlebarsPrecompiler.setup_directories
  HandlebarsPrecompiler.cleanup_tmp_dir
  HandlebarsPrecompiler.cleanup_public_dir

  unless HandlebarsPrecompiler.cli_available?
    msg = "Handlebars CLI not found. Install with: npm install --global handlebars"
    Rails.logger.error msg
    raise msg
  end

  Rails.logger.info "HandlebarsPrecompiler initialized. CLI: #{HandlebarsPrecompiler.cli_path}"
end
```

### 2. New Helper Module: `app/helpers/handlebars_precompiler_helper.rb`

Provides cache key generation, template preprocessing, and compilation logic.

```ruby
# frozen_string_literal: true

module HandlebarsPrecompilerHelper
  extend ActiveSupport::Concern

  # Generate a cache key common to all users
  # Uses server_cache_version and item_updates from dynamic definitions
  def handlebars_cache_key
    @handlebars_cache_key ||= begin
      ver = Application.server_cache_version
      items = handlebars_item_updates_key
      Digest::SHA256.hexdigest("#{ver}-#{items}")[0..12]
    end
  end

  # Extract item_updates logic (refactored from partial_cache_key)
  def handlebars_item_updates_key
    @hbs_item_updates ||= begin
      cs = [Admin::MessageTemplate, DynamicModel, ActivityLog, ExternalIdentifier,
            Admin::ConfigLibrary, Admin::PageLayout, Admin::AppConfiguration]
      cs.map { |c| c.reorder(updated_at: :desc).limit(1).pluck(:updated_at)&.first.to_i.to_s }.join('-')
    end
  end

  # Generate filename for compiled output
  def handlebars_compiled_filename(template_id)
    safe_id = template_id.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
    "#{safe_id}-#{handlebars_cache_key}.js"
  end

  # Preprocess handlebars source (port of _fpa.setup_template_source)
  def preprocess_handlebars_source(source)
    result = source.dup

    # Handle embedded_report and glyphicon patterns
    # {{embedded_report_name}} -> {{embedded_report 'name' true}}
    %w[embedded_report glyphicon].each do |pre|
      result.gsub!(/\{\{#{pre}_([a-zA-Z0-9_]+)\}\}/) do
        "{{#{pre} '#{::Regexp.last_match(1)}' true}}"
      end
    end

    # Handle tag_format patterns
    # {{tag::format::args}} -> {{tag_format tag 'format' 'args'}}
    result.gsub(/\{\{([a-zA-Z0-9_]+)::([0-9a-z:_.]+)\}\}/) do
      tag = ::Regexp.last_match(1)
      parts = ::Regexp.last_match(2).split('::').map { |p| "'#{p}'" }.join(' ')
      "{{tag_format #{tag} #{parts}}}"
    end
  end

  # Compile a single template using handlebars CLI
  # Returns the filename of the compiled JS, or raises on failure
  def compile_handlebars_template(template_id, template_content, is_partial: false)
    filename = handlebars_compiled_filename(template_id)
    output_path = HandlebarsPrecompiler::PUBLIC_DIR.join(filename)

    # Return existing file if already compiled
    return filename if File.exist?(output_path)

    # Preprocess the template content
    processed = preprocess_handlebars_source(template_content)

    # Build CLI command using -i for string input
    cmd_parts = [HandlebarsPrecompiler::HANDLEBARS_CLI]
    cmd_parts << "-i #{Shellwords.escape(processed)}"
    cmd_parts << "-f #{output_path}"
    cmd_parts << "-N #{Shellwords.escape(template_id)}"
    cmd_parts << '--partial' if is_partial
    cmd_parts << '-m' if HandlebarsPrecompiler.minify?

    if HandlebarsPrecompiler.source_maps?
      map_path = output_path.to_s.gsub('.js', '.map')
      cmd_parts << "--map #{map_path}"
    end

    cmd = cmd_parts.join(' ')

    Rails.logger.debug "Compiling Handlebars template: #{template_id}"

    success = system(cmd)
    unless success
      error_msg = "Handlebars compilation failed for #{template_id}. Command: #{cmd}"
      Rails.logger.error error_msg
      raise error_msg
    end

    filename
  end
end
```

### 3. Modify `ApplicationHelper#handlebars_template_tag`

**File:** `app/helpers/application_helper.rb`

Update to emit `<script src="...">` tags instead of inline templates:

```ruby
#
# Generate a precompiled Handlebars template script include
# @param id [String] the template identifier
# @param css_class [String] CSS class indicating template type (default: 'hidden handlebars-template')
# @param block [Block] the Handlebars template content
# @return [String] HTML safe javascript_include_tag for the precompiled template
def handlebars_template_tag(id, css_class: 'hidden handlebars-template', &block)
  content = capture(&block) if block_given?

  is_partial = css_class.include?('handlebars-partial')
  compiled_filename = compile_handlebars_template(id, content, is_partial: is_partial)

  # Include the precompiled JS file
  javascript_include_tag(
    "/handlebars/#{compiled_filename}",
    nonce: true,
    data: {
      handlebars_id: id,
      handlebars_type: is_partial ? 'partial' : 'template'
    }
  )
end
```

### 4. Modify Client-Side `_fpa.compile_templates()`

**File:** `app/assets/javascripts/app/_fpa.js`

Simplify to just alias the Handlebars registries:

```javascript
compile_templates: function () {
  $('body').addClass('status-compiling');

  // Alias Handlebars registries to _fpa for compatibility
  // Precompiled templates auto-register to Handlebars.templates and Handlebars.partials
  _fpa.templates = Handlebars.templates = Handlebars.templates || {};
  _fpa.partials = Handlebars.partials = Handlebars.partials || {};

  // Mark compilation complete - precompiled JS files have already registered themselves
  $('body').removeClass('status-compiling initial-compiling').addClass('status-compiled');
},
```

Also update the initialization at the top of `_fpa`:

```javascript
_fpa = {
  templates: null,  // Will be aliased to Handlebars.templates
  partials: null,   // Will be aliased to Handlebars.partials
  // ... rest of _fpa
```

### 5. Modify AJAX Template Loading

**File:** `app/views/layouts/_setup_app.html.erb`

Handle `<script src="...">` tags in the AJAX response:

```erb
<% if current_user&.app_type_id && !(controller_name == 'app_types' && action_name == 'upload') %>
$.get({ url: '/pages/<%= template_version %>/template', cache: true }).done(function(data) {
  // Create a temporary container to parse the response
  var container = document.createElement('div');
  container.innerHTML = data;
  
  // Find all script tags with src and load them
  var scripts = container.querySelectorAll('script[src]');
  var loadPromises = [];
  
  scripts.forEach(function(script) {
    var promise = new Promise(function(resolve, reject) {
      var newScript = document.createElement('script');
      newScript.src = script.src;
      newScript.onload = resolve;
      newScript.onerror = reject;
      document.head.appendChild(newScript);
    });
    loadPromises.push(promise);
  });
  
  // Also append any inline scripts (non-src) like fpa_state_config
  var inlineScripts = container.querySelectorAll('script:not([src])');
  inlineScripts.forEach(function(script) {
    var newScript = document.createElement('script');
    newScript.textContent = script.textContent;
    newScript.nonce = script.nonce;
    document.body.appendChild(newScript);
  });
  
  // Wait for all precompiled templates to load
  Promise.all(loadPromises).then(function() {
    _fpa.status.loaded_templates = true;
    one_time_setup();
  }).catch(function(err) {
    console.error('Failed to load precompiled templates:', err);
    _fpa.flash_notice('Failed to load page templates. Please refresh.', 'danger');
  });
}).fail(function(jqXHR, textStatus, errorThrown) {
  // ... existing error handling
});
<% end %>
```

### 6. Update `.gitignore`

Add generated directories:

```gitignore
# Handlebars precompilation
/public/handlebars/
/tmp/handlebars/
```

## CLI Command Patterns

### Templates

```bash
handlebars -i "{{content}}" -f public/handlebars/template-id-hash.js -N "template-id" [-m]
```

### Partials

```bash
handlebars -i "{{content}}" -f public/handlebars/partial-id-hash.js -N "partial-id" --partial [-m]
```

### Generated Output Structure

**Template (registers to `Handlebars.templates['template-id']`):**

```javascript
(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  templates['template-id'] = template({/* compiled template function */});
})();
```

**Partial (registers to `Handlebars.partials['partial-id']`):**

```javascript
(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  Handlebars.partials['partial-id'] = template({/* compiled template function */});
})();
```

## Cache Key Generation

The cache key ensures recompilation when configurations change:

```
handlebars_cache_key = SHA256(
  Application.server_cache_version + 
  latest_updated_at(Admin::MessageTemplate) +
  latest_updated_at(DynamicModel) +
  latest_updated_at(ActivityLog) +
  latest_updated_at(ExternalIdentifier) +
  latest_updated_at(Admin::ConfigLibrary) +
  latest_updated_at(Admin::PageLayout) +
  latest_updated_at(Admin::AppConfiguration)
)[0..12]
```

## Directory Structure

```
fphs-restructure/
├── tmp/
│   └── handlebars/           # Temporary files (cleaned on startup)
├── public/
│   └── handlebars/           # Compiled JS files
│       ├── search-results-template-abc123def.js
│       ├── search-results-template-abc123def.map  (dev only)
│       ├── master_main-abc123def.js
│       └── ...
```

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `config/initializers/handlebars_precompiler.rb` | Create | Initialization, directory setup, cleanup |
| `app/helpers/handlebars_precompiler_helper.rb` | Create | Compilation logic, preprocessing |
| `app/helpers/application_helper.rb` | Modify | Include helper, update `handlebars_template_tag` |
| `app/assets/javascripts/app/_fpa.js` | Modify | Simplify `compile_templates()`, alias registries |
| `app/views/layouts/_setup_app.html.erb` | Modify | Handle script-src loading for AJAX templates |
| `.gitignore` | Modify | Add `/public/handlebars/` and `/tmp/handlebars/` |

## Error Handling

| Scenario | Behavior |
|----------|----------|
| CLI not available at startup | Raise fatal error - server won't start |
| Compilation failure | Raise error with details - page won't render |
| File write failure | Raise error with path details |
| Script load failure in browser | Show user-facing error, suggest refresh |

## Deployment Requirements

### Install Handlebars CLI

```bash
npm install --global handlebars
```

### AWS Elastic Beanstalk

Add to `.platform/hooks/predeploy/install_handlebars.sh`:

```bash
#!/bin/bash
npm install --global handlebars
```

### Docker

Add to Dockerfile:

```dockerfile
RUN npm install --global handlebars
```

### Verify Installation

```bash
which handlebars
handlebars --version
```

## Testing Plan

### Model Specs

- Test `handlebars_cache_key` generation consistency
- Test `preprocess_handlebars_source` with all patterns:
  - `{{embedded_report_name}}` → `{{embedded_report 'name' true}}`
  - `{{glyphicon_icon}}` → `{{glyphicon 'icon' true}}`
  - `{{tag::format}}` → `{{tag_format tag 'format'}}`
- Test `compile_handlebars_template` creates correct files

### System Specs

- Test page loads with precompiled templates
- Test AJAX template loading works correctly
- Test template rendering produces correct output
- Compare output with current client-side compilation

### Performance Tests

- Measure page load time improvement
- Measure Time to Interactive improvement
- Compare JavaScript execution time

## Future Optimizations

### 1. Switch to Handlebars Runtime

If `{{template}}`, `{{compile_template}}`, and `{{run_template}}` helpers can be eliminated or refactored:

- Switch from `handlebars/dist/handlebars` (88KB) to `handlebars.runtime.min.js` (28KB)
- ~60KB reduction in JavaScript payload

### 2. Bundle Templates

Instead of one JS file per template, bundle related templates:

```bash
handlebars templates/*.hbs -f public/handlebars/bundle-hash.js
```

Benefits:

- Fewer HTTP requests
- Better compression ratios
- Simpler cache management

### 3. CDN Caching

Configure CDN to cache `/handlebars/*.js` with long TTL since filenames include content hash.

## References

- [Handlebars Precompilation Documentation](https://handlebarsjs.com/installation/precompilation.html)
- [Handlebars CLI Options](https://handlebarsjs.com/api-reference/compilation.html)
- Current template implementation: `app/helpers/application_helper.rb#handlebars_template_tag`
- Current client compilation: `app/assets/javascripts/app/_fpa.js#compile_templates`
