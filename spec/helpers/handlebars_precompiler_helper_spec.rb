# frozen_string_literal: true

# HandlebarsPrecompilerHelper Spec
#
# Tests helper methods for server-side Handlebars template precompilation.
# This helper provides cache key generation, template preprocessing, and CLI compilation.
#
# Test Coverage:
# - #preprocess_handlebars_source: Converts shorthand Handlebars syntax to CLI-compatible format
#   - Transforms {{embedded_report_name}} → {{embedded_report 'name' true}}
#   - Transforms {{glyphicon_icon}} → {{glyphicon 'icon' true}}
#   - Transforms {{tag::format::args}} → {{tag_format tag 'format' 'args'}}
#   - Preserves standard Handlebars syntax unchanged
#
# - #handlebars_cache_key: Generates consistent cache keys for template versioning
#   - Uses server_cache_version and dynamic definition updated_at timestamps
#   - Returns 13-character hex string (truncated SHA256)
#
# - #handlebars_compiled_filename: Generates safe filenames for compiled output
#   - Sanitizes template IDs to alphanumeric, underscore, hyphen
#   - Appends cache key suffix
#
# - #write_handlebars_template: Writes preprocessed templates to temp files
#   - Writes to partials or templates directory based on is_partial flag
#   - Returns relative URL path to compiled file
#   - Skips if temp file already exists (deduplication)
#
# - #compile_handlebars_templates: Batch compiles all templates from temp directories
#   - Runs single CLI call per type (templates and partials)
#   - Splits combined output into individual JS files
#   - Creates compiled files in public directory
#
# - Issue #1279 follow-up (per-user scoping): handlebars_cache_key must incorporate the
#   current user/admin id, not just app_type_id, because partials such as master_tabs
#   render differently per user (individual role/access-control grants), so two users in
#   the same app_type must never share a compiled file. The resolved user/admin's class
#   name is also folded in so a User and an Admin sharing the same id can never collide.
#
# - Issue #1362 (Stage 1): #split_compiled_output and #write_multiple_handlebars_templates
#   must write atomically (temp file + rename) so a concurrent reader is never handed a
#   partially-written compiled template or multi bundle, and a failed write never
#   corrupts an existing good file already on disk.

require 'rails_helper'

RSpec.describe HandlebarsPrecompilerHelper, type: :helper do
  describe '#preprocess_handlebars_source' do
    context 'with embedded_report shorthand' do
      it 'converts embedded_report shorthand to full helper syntax' do
        source = '{{embedded_report_my_report_name}}'
        expected = "{{embedded_report 'my_report_name' true}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end

      it 'handles embedded_report with underscores in name' do
        source = '{{embedded_report_my_complex_report_name}}'
        expected = "{{embedded_report 'my_complex_report_name' true}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end
    end

    context 'with glyphicon shorthand' do
      it 'converts glyphicon shorthand to full helper syntax' do
        source = '{{glyphicon_pencil}}'
        expected = "{{glyphicon 'pencil' true}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end

      it 'handles glyphicon with underscores in name' do
        source = '{{glyphicon_triangle_right}}'
        expected = "{{glyphicon 'triangle_right' true}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end
    end

    context 'with tag_format shorthand (double colon syntax)' do
      it 'converts simple tag::format to tag_format helper' do
        source = '{{name::uppercase}}'
        expected = "{{tag_format name 'uppercase'}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end

      it 'converts tag::format::arg to tag_format helper with multiple args' do
        source = '{{name::uppercase::3}}'
        expected = "{{tag_format name 'uppercase' '3'}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end

      it 'converts tag with multiple format arguments' do
        source = '{{date_time::date_time_show_zone}}'
        expected = "{{tag_format date_time 'date_time_show_zone'}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end

      it 'handles numeric format arguments' do
        source = '{{value::format::1::2::3}}'
        expected = "{{tag_format value 'format' '1' '2' '3'}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end
    end

    context 'with multiple transformations' do
      it 'transforms multiple patterns in one source' do
        source = '<div>{{glyphicon_edit}} Report: {{embedded_report_summary}} Value: {{amount::currency}}</div>'
        expected = "<div>{{glyphicon 'edit' true}} Report: {{embedded_report 'summary' true}} Value: {{tag_format amount 'currency'}}</div>"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq(expected)
      end
    end

    context 'with standard Handlebars syntax' do
      it 'preserves standard variable expressions' do
        source = '{{name}}'

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq('{{name}}')
      end

      it 'preserves standard helper expressions' do
        source = '{{#if condition}}content{{/if}}'

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq('{{#if condition}}content{{/if}}')
      end

      it 'preserves helper expressions with arguments' do
        source = "{{some_helper 'arg1' 'arg2'}}"

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq("{{some_helper 'arg1' 'arg2'}}")
      end

      it 'preserves partial expressions' do
        source = '{{> my_partial}}'

        result = helper.preprocess_handlebars_source(source)

        expect(result).to eq('{{> my_partial}}')
      end
    end
  end

  describe '#handlebars_cache_key' do
    it 'returns a 13-character hex string' do
      result = helper.handlebars_cache_key

      expect(result).to match(/\A[a-f0-9]{13}\z/)
    end

    it 'returns consistent value on multiple calls' do
      first_call = helper.handlebars_cache_key
      second_call = helper.handlebars_cache_key

      expect(first_call).to eq(second_call)
    end

    it 'changes when dynamic model updated_at changes' do
      first_key = helper.handlebars_cache_key

      # Clear memoization (variable name matches rubocop-corrected implementation)
      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      # Simulate a configuration change by touching a dynamic model
      dm = DynamicModel.first
      if dm
        dm.touch
        second_key = helper.handlebars_cache_key
        expect(second_key).not_to eq(first_key)
      else
        skip 'No DynamicModel records available for this test'
      end
    end
  end

  describe '#handlebars_compiled_filename' do
    before do
      # Stub cache key for predictable filenames
      allow(helper).to receive(:handlebars_cache_key).and_return('abc123def4567')
    end

    it 'generates filename with template id and cache key' do
      result = helper.handlebars_compiled_filename('my-template')

      expect(result).to eq('my-template-abc123def4567.js')
    end

    it 'sanitizes special characters in template id' do
      result = helper.handlebars_compiled_filename('template.with/special:chars')

      expect(result).to eq('template_with_special_chars-abc123def4567.js')
    end

    it 'preserves underscores and hyphens' do
      result = helper.handlebars_compiled_filename('my_template-name')

      expect(result).to eq('my_template-name-abc123def4567.js')
    end
  end

  # Issue #1362 (Stage 1) - content-addressed naming. Compiled filenames are keyed on a
  # digest of the actual preprocessed SOURCE (when given), not on who asked for it, so
  # identical content compiled by different users/app_types shares one file, while
  # differing content never collides - regardless of why it differs. Every template id is
  # content-addressed when a source is given (issue #1362 S4) - see
  # content_addressing_safety_spec.rb / the option-3 fix in
  # _search_results_resources_panel.html.erb for why this is safe even for
  # master_main_inner. The digest is 32 hex chars (issue #1362 S5), not truncated to 13.
  describe '#handlebars_compiled_filename content addressing (issue #1362)' do
    it 'produces the SAME filename for the SAME source regardless of handlebars_cache_key' do
      allow(helper).to receive(:handlebars_cache_key).and_return('user-one-key-12')
      filename_one = helper.handlebars_compiled_filename('some-template', '<div>{{a}}</div>')

      allow(helper).to receive(:handlebars_cache_key).and_return('user-two-key-99')
      filename_two = helper.handlebars_compiled_filename('some-template', '<div>{{a}}</div>')

      expect(filename_one).to eq(filename_two)
    end

    it 'produces DIFFERENT filenames for different source, same id and same handlebars_cache_key' do
      allow(helper).to receive(:handlebars_cache_key).and_return('same-key-123456')

      filename_a = helper.handlebars_compiled_filename('some-template', '<div>{{a}}</div>')
      filename_b = helper.handlebars_compiled_filename('some-template', '<div>{{b}}</div>')

      expect(filename_a).not_to eq(filename_b)
    end

    it 'still includes the sanitized template id as a prefix' do
      result = helper.handlebars_compiled_filename('template.with/chars', '<div>{{a}}</div>')

      expect(result).to start_with('template_with_chars-')
    end

    it 'falls back to handlebars_cache_key when no source is given (backward compatible)' do
      allow(helper).to receive(:handlebars_cache_key).and_return('fallback-key12')

      result = helper.handlebars_compiled_filename('some-template')

      expect(result).to eq('some-template-fallback-key12.js')
    end

    it 'uses a 32-character digest, not the old truncated 13-character one' do
      result = helper.handlebars_compiled_filename('some-template', '<div>{{a}}</div>')

      digest = result.delete_prefix('some-template-').delete_suffix('.js')
      expect(digest.length).to eq(32)
      expect(digest).to eq(Digest::SHA256.hexdigest('<div>{{a}}</div>')[0..31])
    end

    it 'content-addresses master_main_inner too, now that the substitution risk is closed at its source' do
      filename_a = helper.handlebars_compiled_filename('master_main_inner', '<div>{{a}}</div>')
      filename_b = helper.handlebars_compiled_filename('master_main_inner', '<div>{{b}}</div>')
      filename_same = helper.handlebars_compiled_filename('master_main_inner', '<div>{{a}}</div>')

      expect(filename_a).not_to eq(filename_b)
      expect(filename_a).to eq(filename_same)
    end
  end

  describe '#write_handlebars_template' do
    let(:template_id) { 'test-template' }
    let(:template_content) { '<div>{{name}}</div>' }
    let(:cache_key) { 'abc123def4567' }
    # content-addressed (issue #1362): the compiled filename is derived from the
    # preprocessed source (32 hex chars - issue #1362 S5), not handlebars_cache_key.
    # template_content has no preprocess_handlebars_source shorthand, so preprocessed == raw.
    let(:expected_filename) { "#{template_id}-#{Digest::SHA256.hexdigest(template_content)[0..31]}.js" }

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      # Ensure clean state and directories exist
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PARTIALS_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.partials_compiled_dir.join('*')))
    end

    context 'when temp file does not exist' do
      it 'writes preprocessed content to temp templates directory' do
        helper.write_handlebars_template(template_id, template_content)

        # Files are now in request-specific subdirectories
        request_dir = helper.handlebars_temp_dir(is_partial: false)
        temp_file = request_dir.join("#{template_id}.handlebars")
        expect(File.exist?(temp_file)).to be true
        expect(File.read(temp_file)).to eq(template_content)
      end

      it 'writes to partials directory when is_partial is true' do
        helper.write_handlebars_template(template_id, template_content, is_partial: true)

        request_dir = helper.handlebars_temp_dir(is_partial: true)
        temp_file = request_dir.join("#{template_id}.handlebars")
        expect(File.exist?(temp_file)).to be true
      end

      it 'returns URL path to compiled file location' do
        result = helper.write_handlebars_template(template_id, template_content)

        expect(result).to eq("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{expected_filename}")
      end

      it 'preprocesses content before writing to temp file' do
        source_with_shorthand = '{{embedded_report_summary}}'

        helper.write_handlebars_template(template_id, source_with_shorthand)

        request_dir = helper.handlebars_temp_dir(is_partial: false)
        temp_file = request_dir.join("#{template_id}.handlebars")
        content = File.read(temp_file)
        expect(content).to include("embedded_report 'summary' true")
      end
    end

    context 'when temp file already exists' do
      before do
        # Create the request-specific directory and file
        request_dir = helper.handlebars_temp_dir(is_partial: false)
        FileUtils.mkdir_p(request_dir)
        temp_file = request_dir.join("#{template_id}.handlebars")
        File.write(temp_file, 'existing content')
      end

      it 'does not overwrite existing temp file (deduplication within request)' do
        helper.write_handlebars_template(template_id, template_content)

        request_dir = helper.handlebars_temp_dir(is_partial: false)
        temp_file = request_dir.join("#{template_id}.handlebars")
        expect(File.read(temp_file)).to eq('existing content')
      end

      it 'still returns correct URL path' do
        result = helper.write_handlebars_template(template_id, template_content)

        expect(result).to eq("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{expected_filename}")
      end
    end

    context 'when compiled file already exists in public directory' do
      before do
        FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
        compiled_file = HandlebarsPrecompiler.templates_compiled_dir.join(expected_filename)
        File.write(compiled_file, '// already compiled')
      end

      it 'does not write temp file (avoids recompilation)' do
        helper.write_handlebars_template(template_id, template_content)

        temp_file = HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join("#{template_id}.handlebars")
        expect(File.exist?(temp_file)).to be false
      end

      it 'returns correct URL path to existing compiled file' do
        result = helper.write_handlebars_template(template_id, template_content)

        expect(result).to eq("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{expected_filename}")
      end
    end
  end

  # Issue #1362 (Stage 1) - the actual sharing/isolation guarantee content addressing is
  # for: two DIFFERENT users with IDENTICAL rendered content share one compiled file (no
  # redundant compile); two calls with DIFFERING content (whatever the reason) are always
  # isolated. master_main_inner is no longer excluded (issue #1362 S4) - see
  # content_addressing_safety_spec.rb / the option-3 fix in
  # _search_results_resources_panel.html.erb for the safety investigation and fix behind
  # why it can now be content-addressed like every other template.
  describe '#write_handlebars_template content addressing sharing/isolation (issue #1362)' do
    let(:template_id) { 'shared-template' }
    let(:identical_content) { '<div>{{field}}</div>' }

    before do
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PARTIALS_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.partials_compiled_dir.join('*')))
    end

    it 'returns the SAME compiled path for two different users rendering IDENTICAL content' do
      allow(helper).to receive(:handlebars_cache_key).and_return('user-one-key-12')
      path_one = helper.write_handlebars_template(template_id, identical_content)

      helper.instance_variable_set(:@handlebars_request_id, nil)
      allow(helper).to receive(:handlebars_cache_key).and_return('user-two-key-99')
      path_two = helper.write_handlebars_template(template_id, identical_content)

      expect(path_two).to eq(path_one)
    end

    it 'writes the temp file only once for two different users rendering IDENTICAL content' do
      allow(helper).to receive(:handlebars_cache_key).and_return('user-one-key-12')
      helper.write_handlebars_template(template_id, identical_content)

      # Simulate the FIRST user's compile having already completed and been written
      # to the public dir at the path just returned, so the second (different) user's
      # call should skip re-writing a temp file entirely.
      compiled_filename = helper.handlebars_compiled_filename(template_id, identical_content)
      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      File.write(HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename), '// compiled')

      helper.instance_variable_set(:@handlebars_request_id, nil)
      allow(helper).to receive(:handlebars_cache_key).and_return('user-two-key-99')
      helper.write_handlebars_template(template_id, identical_content)

      temp_file = helper.handlebars_temp_dir(is_partial: false).join("#{template_id}.handlebars")
      expect(File.exist?(temp_file)).to be false
    end

    it 'returns DIFFERENT compiled paths for the SAME user rendering DIFFERENT content' do
      allow(helper).to receive(:handlebars_cache_key).and_return('same-user-key1')

      path_a = helper.write_handlebars_template(template_id, '<div>{{a}}</div>')

      helper.instance_variable_set(:@handlebars_request_id, nil)
      path_b = helper.write_handlebars_template(template_id, '<div>{{b}}</div>')

      expect(path_b).not_to eq(path_a)
    end

    it 'shares master_main_inner across users too, now that the substitution risk is closed at its source' do
      allow(helper).to receive(:handlebars_cache_key).and_return('user-one-key-12')
      path_one = helper.write_handlebars_template('master_main_inner', identical_content, is_partial: true)

      helper.instance_variable_set(:@handlebars_request_id, nil)
      allow(helper).to receive(:handlebars_cache_key).and_return('user-two-key-99')
      path_two = helper.write_handlebars_template('master_main_inner', identical_content, is_partial: true)

      expect(path_two).to eq(path_one)
    end
  end

  # Issue #1362 (Stage 1) - the opportunistic sweep trigger: no cron/background thread
  # exists in Stage 1, so a request notices a rotation itself (its generation's directory
  # doesn't exist yet) and sweeps old generations as a side effect, at most once per request.
  describe '#write_handlebars_template opportunistic generation sweep (issue #1362)' do
    before do
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TMP_DIR.join('gen-*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('gen-*')))
    end

    it 'triggers a sweep the first time this request sees the current generation is missing' do
      expect(HandlebarsPrecompiler).to receive(:sweep_old_generations)

      helper.write_handlebars_template('trigger-test', '<div>{{a}}</div>')
    end

    it 'only checks/triggers once per request even across many write_handlebars_template calls' do
      expect(HandlebarsPrecompiler).to receive(:sweep_old_generations).once

      helper.write_handlebars_template('trigger-test-a', '<div>{{a}}</div>')
      helper.write_handlebars_template('trigger-test-b', '<div>{{b}}</div>')
      helper.write_handlebars_template('trigger-test-c', '<div>{{c}}</div>')
    end

    it 'does not trigger a sweep at all once the current generation directory already exists' do
      FileUtils.mkdir_p(HandlebarsPrecompiler.tmp_generation_dir)

      expect(HandlebarsPrecompiler).not_to receive(:sweep_old_generations)

      helper.write_handlebars_template('trigger-test', '<div>{{a}}</div>')
    end

    it 'skips the sweep without raising if the sweep lock is already held elsewhere' do
      allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).with('generation-sweep', wait: 0, on_contention: :skip)
      expect(HandlebarsPrecompiler).not_to receive(:sweep_old_generations)

      expect { helper.write_handlebars_template('trigger-test', '<div>{{a}}</div>') }.not_to raise_error
    end
  end

  describe '#compile_handlebars_templates' do
    let(:cache_key) { 'batch123456789' }

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      # Ensure clean state and directories exist
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PARTIALS_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.partials_compiled_dir.join('*')))
    end

    context 'when no templates have been written' do
      it 'does nothing when temp directories are empty' do
        expect(Utilities::ProcessPipes).not_to receive(:pipe_in_out)

        helper.compile_handlebars_templates
      end
    end

    context 'when templates have been written' do
      before do
        # Write templates using the helper (creates request-specific directory)
        helper.write_handlebars_template('template-one', '<div>{{one}}</div>')
        helper.write_handlebars_template('template-two', '<div>{{two}}</div>')
      end

      it 'calls Handlebars CLI with template file paths' do
        allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_return('')

        helper.compile_handlebars_templates

        expect(Utilities::ProcessPipes).to have_received(:pipe_in_out) do |_stdin, cmd|
          # The command should include file paths within the templates directory
          expect(cmd.any? { |arg| arg.include?('template-one.handlebars') }).to be true
        end
      end

      it 'cleans up temp files after compilation' do
        allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_return('')

        helper.compile_handlebars_templates

        # Request-specific directory should be removed
        request_dir = helper.handlebars_temp_dir(is_partial: false)
        expect(Dir.exist?(request_dir)).to be false
      end
    end

    context 'when partials have been written' do
      before do
        # Write partials using the helper
        helper.write_handlebars_template('partial-one', '<span>{{item}}</span>', is_partial: true)
      end

      it 'includes --partial flag for partials directory' do
        allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_return('')

        helper.compile_handlebars_templates

        expect(Utilities::ProcessPipes).to have_received(:pipe_in_out) do |_stdin, cmd|
          expect(cmd).to include('--partial')
        end
      end
    end

    context 'when both templates and partials exist' do
      before do
        helper.write_handlebars_template('template', '<div>{{t}}</div>')
        helper.write_handlebars_template('partial', '<span>{{p}}</span>', is_partial: true)
      end

      it 'compiles both templates and partials with separate CLI calls' do
        allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_return('')

        helper.compile_handlebars_templates

        # Should call CLI twice (once for templates, once for partials)
        expect(Utilities::ProcessPipes).to have_received(:pipe_in_out).twice
      end
    end

    context 'with real CLI integration', :cli_integration do
      before do
        allow(helper).to receive(:handlebars_cache_key).and_call_original
      end

      it 'creates compiled JavaScript files' do
        skip 'Handlebars CLI not available' unless system('which npx > /dev/null 2>&1')

        # Write template using the helper
        helper.write_handlebars_template('integration-test', '<div>{{name}}</div>')

        helper.compile_handlebars_templates

        # Should have created compiled file in templates public subdirectory
        compiled_files = Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('integration-test-*.js'))
        expect(compiled_files).not_to be_empty

        content = File.read(compiled_files.first)
        expect(content).to include('Handlebars.template')
      end
    end

    context 'error handling' do
      before do
        # Write template using the helper
        helper.write_handlebars_template('test', '<div>{{x}}</div>')
        allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_raise(FphsException.new('CLI error'))
      end

      it 'raises error when CLI compilation fails' do
        expect do
          helper.compile_handlebars_templates
        end.to raise_error(/Handlebars batch compilation failed/)
      end

      it 'logs error to Rails.logger on compilation failure' do
        expect(Rails.logger).to receive(:error).with(/Handlebars batch compilation failed/).at_least(:once)
        allow(Rails.logger).to receive(:error).with(any_args)

        expect do
          helper.compile_handlebars_templates
        end.to raise_error(RuntimeError)
      end
    end
  end

  # Issue #1362 (Stage 1) - duplicate-compile avoidance around the CLI batch compile step.
  # The FileLock primitive's own concurrency guarantees are proven in file_lock_spec.rb;
  # these specs prove compile_handlebars_templates_for_type USES it correctly (right
  # trigger, right re-check timing), using deterministic scenarios rather than real threads.
  describe '#compile_handlebars_templates duplicate-compile avoidance (issue #1362)' do
    context 'when the content-addressed output already exists before compiling' do
      it 'never invokes the CLI at all (cheap pre-filter, no lock needed)' do
        content = '<div>{{already_done}}</div>'
        helper.write_handlebars_template('already-compiled', content)

        compiled_filename = helper.handlebars_compiled_filename('already-compiled', content)
        FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
        File.write(HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename), '// already compiled')

        expect(Utilities::ProcessPipes).not_to receive(:pipe_in_out)

        helper.compile_handlebars_templates
      end

      it 'still cleans up the request-specific temp directory' do
        content = '<div>{{already_done}}</div>'
        helper.write_handlebars_template('already-compiled', content)

        compiled_filename = helper.handlebars_compiled_filename('already-compiled', content)
        FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
        File.write(HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename), '// already compiled')

        helper.compile_handlebars_templates

        request_dir = helper.handlebars_temp_dir(is_partial: false)
        expect(Dir.exist?(request_dir)).to be false
      end
    end

    context 'when only SOME of the pending templates are already compiled' do
      it 'invokes the CLI only for the templates still missing' do
        pending_content = '<div>{{pending}}</div>'
        done_content = '<div>{{done}}</div>'
        helper.write_handlebars_template('pending-one', pending_content)
        helper.write_handlebars_template('done-one', done_content)

        done_filename = helper.handlebars_compiled_filename('done-one', done_content)
        FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
        File.write(HandlebarsPrecompiler.templates_compiled_dir.join(done_filename), '// already compiled')

        allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_return('')

        helper.compile_handlebars_templates

        expect(Utilities::ProcessPipes).to have_received(:pipe_in_out) do |_stdin, cmd|
          expect(cmd.any? { |arg| arg.to_s.include?('pending-one.handlebars') }).to be true
          expect(cmd.any? { |arg| arg.to_s.include?('done-one.handlebars') }).to be false
        end
      end
    end

    context 'when the lock is contended by another process' do
      it 'still runs the CLI unlocked rather than waiting or skipping (on_contention: :proceed)' do
        helper.write_handlebars_template('contended-one', '<div>{{x}}</div>')

        allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_wrap_original do |original, name, **opts, &block|
          expect(opts[:wait]).to eq(Settings::HandlebarsLockWaitSeconds)
          original.call(name, **opts, &block)
        end
        allow(Utilities::ProcessPipes).to receive(:pipe_in_out).and_return('')

        helper.compile_handlebars_templates

        expect(Utilities::ProcessPipes).to have_received(:pipe_in_out)
      end

      it 'skips the CLI if the other process finishes DURING the lock wait (double-checked re-filter)' do
        content = '<div>{{race}}</div>'
        helper.write_handlebars_template('race-one', content)
        compiled_filename = helper.handlebars_compiled_filename('race-one', content)
        compiled_path = HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename)

        # Simulate another process finishing the compile WHILE this one was
        # attempting/waiting for the lock, by writing the output just before
        # the lock block is allowed to run.
        allow(HandlebarsPrecompiler::FileLock).to receive(:acquire) do |_name, **_opts, &block|
          FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
          File.write(compiled_path, '// finished by the other process')
          block.call
        end

        expect(Utilities::ProcessPipes).not_to receive(:pipe_in_out)

        helper.compile_handlebars_templates
      end
    end
  end

  # Issue #1362 (Stage 1) - split_compiled_output must never leave a partially-written
  # compiled file visible to a concurrent reader. Calls #split_compiled_output directly
  # with fake CLI-style output (bypassing the real CLI) so the write behaviour can be
  # exercised in isolation.
  describe '#split_compiled_output atomic writes (issue #1362)' do
    let(:cache_key) { 'atomicsplit1234' }
    let(:template_source) { '<div>{{hi}}</div>' }
    let(:cli_output_file) { HandlebarsPrecompiler::TMP_DIR.join('fake_cli_output.js') }
    let(:cli_output_content) do
      <<~JS
        (function() {
          var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
        templates['atomic-template'] = template({"1":function(){return "hi";}});
        })();
      JS
    end

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('*')))
      File.write(cli_output_file, cli_output_content)

      # split_compiled_output re-reads the preprocessed source from the request-specific
      # temp dir (content-addressed naming, issue #1362) - normally written earlier by
      # #write_handlebars_template, recreated here since this spec calls
      # split_compiled_output directly with fake CLI output.
      temp_dir = helper.handlebars_temp_dir(is_partial: false)
      FileUtils.mkdir_p(temp_dir)
      File.write(temp_dir.join('atomic-template.handlebars'), template_source)
    end

    after do
      FileUtils.rm_f(cli_output_file)
    end

    def compiled_file
      compiled_filename = helper.handlebars_compiled_filename('atomic-template', template_source)
      HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename)
    end

    it 'writes the complete compiled file when no error occurs (regression)' do
      helper.send(:split_compiled_output, cli_output_file, is_partial: false)

      expect(File.exist?(compiled_file)).to be true
      expect(File.read(compiled_file)).to include('Handlebars.template')
    end

    it 'never leaves a partially-written target file if the write is interrupted' do
      # Simulate a crash partway through writing the destination content: the first
      # File.write call (to the atomic temp file) writes truncated bytes then raises.
      call_count = 0
      allow(File).to receive(:write).and_wrap_original do |original, path, content|
        call_count += 1
        if call_count == 1
          original.call(path, content[0..2])
          raise IOError, 'simulated crash mid-write'
        else
          original.call(path, content)
        end
      end

      expect do
        helper.send(:split_compiled_output, cli_output_file, is_partial: false)
      end.to raise_error(IOError)

      expect(File.exist?(compiled_file)).to be false
    end

    it 'does not leave a stray .tmp file behind after a failed write' do
      allow(File).to receive(:write).and_raise(IOError, 'simulated crash')

      expect do
        helper.send(:split_compiled_output, cli_output_file, is_partial: false)
      end.to raise_error(IOError)

      leftover_tmp_files = Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('*.tmp'))
      expect(leftover_tmp_files).to be_empty
    end

    it 'does not overwrite an existing compiled file with partial content on failure' do
      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      File.write(compiled_file, '// previous good content')

      allow(File).to receive(:write).and_raise(IOError, 'simulated crash')

      expect do
        helper.send(:split_compiled_output, cli_output_file, is_partial: false)
      end.to raise_error(IOError)

      expect(File.read(compiled_file)).to eq('// previous good content')
    end
  end

  # Issue #1362 should-fix - a per-request temp source file can vanish (cleanup racing
  # ahead, or a non-web process wiping tmp dirs) between the CLI batch-compiling it and
  # split_compiled_output re-reading it to compute the compiled filename. Must skip that
  # one entry rather than raise Errno::ENOENT and fail the WHOLE batch (including other,
  # unrelated templates compiled in the same CLI call).
  describe '#split_compiled_output missing source file (issue #1362 should-fix)' do
    let(:cache_key) { 'missingsrc123456' }
    let(:present_source) { '<div>{{hi}}</div>' }
    let(:cli_output_file) { HandlebarsPrecompiler::TMP_DIR.join('fake_cli_output_missing_src.js') }
    let(:cli_output_content) do
      <<~JS
        (function() {
          var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
        templates['vanished-template'] = template({"1":function(){return "gone";}});
        templates['present-template'] = template({"1":function(){return "hi";}});
        })();
      JS
    end

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('*')))
      File.write(cli_output_file, cli_output_content)

      temp_dir = helper.handlebars_temp_dir(is_partial: false)
      FileUtils.mkdir_p(temp_dir)
      # 'vanished-template.handlebars' is deliberately NOT created, simulating the race.
      File.write(temp_dir.join('present-template.handlebars'), present_source)
    end

    after do
      FileUtils.rm_f(cli_output_file)
    end

    it 'does not raise when a template\'s source file is missing' do
      expect { helper.send(:split_compiled_output, cli_output_file, is_partial: false) }.not_to raise_error
    end

    it 'logs a warning naming the missing source file' do
      warnings = []
      allow(Rails.logger).to receive(:warn) { |msg| warnings << msg }

      helper.send(:split_compiled_output, cli_output_file, is_partial: false)

      expect(warnings).to include(a_string_matching(/vanished-template.*source file missing/))
    end

    it 'still compiles the OTHER template whose source file is present' do
      helper.send(:split_compiled_output, cli_output_file, is_partial: false)

      compiled_filename = helper.handlebars_compiled_filename('present-template', present_source)
      expect(File.exist?(HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename))).to be true
    end
  end

  describe '#write_multiple_handlebars_templates' do
    let(:cache_key) { 'multi123456789' }

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      allow(helper).to receive(:current_user).and_return(Struct.new(:id, :current_sign_in_at, :app_type_id).new(1, Time.at(1_000_000), 2))
      allow(helper).to receive(:current_admin).and_return(nil)

      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js')))
    end

    it 'generates multi file URL without double slashes' do
      # Create a compiled template file so it can be read via its compiled_file_path
      source = '<div>{{x}}</div>'
      compiled_filename = helper.handlebars_compiled_filename('test_template', source)
      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      compiled_file = HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename)
      File.write(compiled_file, '(function() { var template = Handlebars.template; })();')

      templates = [{ id: 'test_template', is_partial: false,
                     compiled_file_path: "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{compiled_filename}" }]
      url, = helper.write_multiple_handlebars_templates(templates)

      expect(url).not_to include('//')
      expect(url).to start_with(HandlebarsPrecompiler::URL_RELATIVE_PATH)
      expect(url).to include('/multi/')
    end
  end

  # Issue #1362 S6 fix - a generation can be swept, or a delayed_job restart can wipe the
  # tmp dirs, in the narrow window between write_handlebars_template confirming a compiled
  # file exists and write_multiple_handlebars_templates reading it back. Must degrade
  # (omit that one template) rather than raise and fail the whole bundle/page - the
  # front-end already tolerates a missing template (see _fpa.js's "Template not found"
  # console.log guard).
  describe '#write_multiple_handlebars_templates missing compiled file (issue #1362 S6 fix)' do
    let(:missing_template_path) do
      "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/does-not-exist-abc123.js"
    end

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return('missingfile123456')
      allow(helper).to receive(:current_user).and_return(Struct.new(:id, :current_sign_in_at, :app_type_id).new(1, Time.at(1_000_000), 2))
      allow(helper).to receive(:current_admin).and_return(nil)

      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js')))
    end

    it 'omits a template whose compiled file is missing instead of raising' do
      templates = [{ id: 'missing_template', is_partial: false, compiled_file_path: missing_template_path }]

      expect { helper.write_multiple_handlebars_templates(templates) }.not_to raise_error
    end

    it 'logs a warning naming the missing file' do
      templates = [{ id: 'missing_template', is_partial: false, compiled_file_path: missing_template_path }]

      # Also logs a separate "skipping multi-file assembly" warning (issue #1362
      # should-fix) - collect all warnings rather than a strict single-call expectation.
      warnings = []
      allow(Rails.logger).to receive(:warn) { |msg| warnings << msg }

      helper.write_multiple_handlebars_templates(templates)

      expect(warnings).to include(a_string_matching(/missing at read time/))
    end

    it 'does NOT persist the multi bundle when a requested template is missing (avoids permanently caching a degraded bundle)' do
      good_source = '<div>{{ok}}</div>'
      good_filename = helper.handlebars_compiled_filename('present_template', good_source)
      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      File.write(HandlebarsPrecompiler.templates_compiled_dir.join(good_filename),
                 '(function() { templates["present_template"] = 1; })();')

      templates = [
        { id: 'missing_template', is_partial: false, compiled_file_path: missing_template_path },
        { id: 'present_template', is_partial: false,
          compiled_file_path: "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{good_filename}" }
      ]

      url, = helper.write_multiple_handlebars_templates(templates)
      multi_file = HandlebarsPrecompiler.multi_dir.join(url.split('/').last)

      expect(File.exist?(multi_file)).to be false
    end

    it 'assembles and persists the bundle on a LATER request once the missing template becomes available' do
      good_source = '<div>{{ok}}</div>'
      good_filename = helper.handlebars_compiled_filename('present_template', good_source)
      recovered_source = '<div>{{later}}</div>'
      recovered_filename = helper.handlebars_compiled_filename('missing_template', recovered_source)
      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      File.write(HandlebarsPrecompiler.templates_compiled_dir.join(good_filename),
                 '(function() { templates["present_template"] = 1; })();')
      File.write(HandlebarsPrecompiler.templates_compiled_dir.join(recovered_filename),
                 '(function() { templates["missing_template"] = 1; })();')

      templates = [
        { id: 'missing_template', is_partial: false,
          compiled_file_path: "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{recovered_filename}" },
        { id: 'present_template', is_partial: false,
          compiled_file_path: "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{good_filename}" }
      ]

      url, = helper.write_multiple_handlebars_templates(templates)
      multi_file = HandlebarsPrecompiler.multi_dir.join(url.split('/').last)

      expect(File.exist?(multi_file)).to be true
      content = File.read(multi_file)
      expect(content).to include('present_template')
      expect(content).to include('missing_template')
    end
  end

  # Issue #1362 S11 fix - the template name is parsed out of the Handlebars CLI's own
  # output, not generated by us, so it must be sanitized the same way every other path
  # built from a template id in this file already is, before being interpolated into a
  # filesystem path.
  describe '#split_compiled_output template name sanitization (issue #1362 S11 fix)' do
    let(:malicious_name) { '../../etc/passwd' }
    let(:malicious_source) { '<div>{{danger}}</div>' }
    let(:cli_output_file) { HandlebarsPrecompiler::TMP_DIR.join('fake_cli_output_sanitize.js') }
    let(:cli_output_content) do
      <<~JS
        (function() {
          var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
        templates['#{malicious_name}'] = template({"1":function(){return "danger";}});
        })();
      JS
    end

    before do
      HandlebarsPrecompiler.setup_directories
      File.write(cli_output_file, cli_output_content)

      # Written at the SANITIZED path, exactly as #write_handlebars_template would have
      # written it (it sanitizes the id before ever touching the filesystem).
      safe_name = malicious_name.gsub(/[^a-zA-Z0-9_-]/, '_')
      temp_dir = helper.handlebars_temp_dir(is_partial: false)
      FileUtils.mkdir_p(temp_dir)
      File.write(temp_dir.join("#{safe_name}.handlebars"), malicious_source)
    end

    after do
      FileUtils.rm_f(cli_output_file)
    end

    it 'reads the source from the sanitized path rather than the raw CLI-provided name' do
      expect { helper.send(:split_compiled_output, cli_output_file, is_partial: false) }.not_to raise_error

      compiled_filename = helper.handlebars_compiled_filename(malicious_name, malicious_source)
      expect(File.exist?(HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename))).to be true
    end
  end

  # Issue #1362 (Stage 1) - write_multiple_handlebars_templates must never leave a
  # partially-written multi bundle visible to a concurrent reader.
  describe '#write_multiple_handlebars_templates atomic writes (issue #1362)' do
    let(:cache_key) { 'atomicmulti1234' }
    let(:user) { Struct.new(:id, :current_sign_in_at, :app_type_id).new(99, Time.at(1_000_000), 3) }
    let(:template_source) { '<div>{{x}}</div>' }
    let(:compiled_filename) { helper.handlebars_compiled_filename('atomic_multi_tpl', template_source) }
    let(:templates) do
      [{ id: 'atomic_multi_tpl', is_partial: false,
         compiled_file_path: "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{compiled_filename}" }]
    end

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_admin).and_return(nil)

      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*')))

      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      File.write(HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename),
                 '(function() { var t = Handlebars.template; })();')
    end

    def multi_file_path
      req_digest = Digest::SHA256.hexdigest([%w[atomic_multi_tpl], []].join(','))
      access_control_version = helper.access_control_version
      HandlebarsPrecompiler.multi_dir.join(
        "requested-templates-#{user.id}-#{user.app_type_id}-#{req_digest}-#{access_control_version}.js"
      )
    end

    it 'never leaves a partially-written multi bundle if the write is interrupted' do
      allow(File).to receive(:write).and_raise(IOError, 'simulated crash mid-write')

      expect do
        helper.write_multiple_handlebars_templates(templates)
      end.to raise_error(IOError)

      expect(File.exist?(multi_file_path)).to be false
    end

    it 'does not leave a stray .tmp file behind after a failed write' do
      allow(File).to receive(:write).and_raise(IOError, 'simulated crash')

      expect do
        helper.write_multiple_handlebars_templates(templates)
      end.to raise_error(IOError)

      leftover_tmp_files = Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.tmp'))
      expect(leftover_tmp_files).to be_empty
    end

    it 'does not overwrite an existing multi bundle with partial content on failure' do
      # Prime a good file first
      helper.write_multiple_handlebars_templates(templates)
      good_content = File.read(multi_file_path)

      # Force a re-write by deleting the marker the code uses to decide freshness is not
      # applicable here (File.exist? check) — instead simulate an external forced rebuild
      # by stubbing File.exist? for the multi file to false so it re-enters the write path.
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(multi_file_path).and_return(false)
      allow(File).to receive(:write).and_raise(IOError, 'simulated crash')

      expect do
        helper.write_multiple_handlebars_templates(templates)
      end.to raise_error(IOError)

      expect(File.read(multi_file_path)).to eq(good_content)
    end
  end

  # Issue #1362 (Stage 1) - duplicate-assembly avoidance around the multi-bundle write.
  describe '#write_multiple_handlebars_templates duplicate-write avoidance (issue #1362)' do
    let(:cache_key) { 'lockmulti123456' }
    let(:user) { Struct.new(:id, :current_sign_in_at, :app_type_id).new(7, Time.at(1_000_000), 4) }
    let(:template_source) { '<div>{{lock}}</div>' }
    let(:compiled_filename) { helper.handlebars_compiled_filename('lock_multi_tpl', template_source) }
    let(:templates) do
      [{ id: 'lock_multi_tpl', is_partial: false,
         compiled_file_path: "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{compiled_filename}" }]
    end

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_admin).and_return(nil)

      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*')))
      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      File.write(HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename),
                 '(function() { var t = Handlebars.template; })();')
    end

    it 'acquires the lock with the configured wait before assembling a new bundle' do
      allow(HandlebarsPrecompiler::FileLock).to receive(:acquire).and_wrap_original do |original, name, **opts, &block|
        expect(opts[:wait]).to eq(Settings::HandlebarsLockWaitSeconds)
        original.call(name, **opts, &block)
      end

      helper.write_multiple_handlebars_templates(templates)

      expect(HandlebarsPrecompiler::FileLock).to have_received(:acquire)
    end

    it 'skips assembling the bundle if another process finishes DURING the lock wait' do
      req_digest = Digest::SHA256.hexdigest([%w[lock_multi_tpl], []].join(','))
      multi_file = HandlebarsPrecompiler.multi_dir.join(
        "requested-templates-#{user.id}-#{user.app_type_id}-#{req_digest}-#{helper.access_control_version}.js"
      )

      # Simulate another process finishing the bundle WHILE this one was attempting/
      # waiting for the lock.
      allow(HandlebarsPrecompiler::FileLock).to receive(:acquire) do |_name, **_opts, &block|
        FileUtils.mkdir_p(HandlebarsPrecompiler.multi_dir)
        File.write(multi_file, '// finished by the other process')
        block.call
      end

      expect(File).not_to receive(:read).with(a_string_including('lock_multi_tpl'))

      helper.write_multiple_handlebars_templates(templates)
    end

    it 'does not attempt to acquire a lock when the bundle already exists up front' do
      req_digest = Digest::SHA256.hexdigest([%w[lock_multi_tpl], []].join(','))
      multi_file = HandlebarsPrecompiler.multi_dir.join(
        "requested-templates-#{user.id}-#{user.app_type_id}-#{req_digest}-#{helper.access_control_version}.js"
      )
      FileUtils.mkdir_p(HandlebarsPrecompiler.multi_dir)
      File.write(multi_file, '// already there')

      expect(HandlebarsPrecompiler::FileLock).not_to receive(:acquire)

      helper.write_multiple_handlebars_templates(templates)
    end
  end

  # Multi-file caching specs for issue #1004
  #
  # Tests that write_multiple_handlebars_templates:
  # - AC1: Skips I/O when the multi file already exists on disk
  # - AC2: Does NOT include current_sign_in_at in the filename (stable across logins)
  # - AC3: Includes user_id in the filename (templates are user-specific)
  # - AC5: Filename changes when user roles/access controls change
  # - AC6: Filename changes when handlebars_cache_key changes (template content change)
  # - AC2: Filename includes an access_control_version derived from userrole, uac, and handlebars_cache_key
  describe '#write_multiple_handlebars_templates multi-file caching (issue #1004)' do
    let(:cache_key) { 'cachekey123456' }
    let(:sign_in_time) { Time.at(1_000_000) }
    let(:user) { Struct.new(:id, :current_sign_in_at, :app_type_id).new(42, sign_in_time, 7) }
    let(:template_source) { '<div>{{alpha}}</div>' }
    let(:compiled_filename) { helper.handlebars_compiled_filename('tpl_alpha', template_source) }
    let(:templates) do
      [{ id: 'tpl_alpha', is_partial: false,
         compiled_file_path: "#{HandlebarsPrecompiler::URL_RELATIVE_PATH}gen-#{HandlebarsPrecompiler.generation_key}/templates/#{compiled_filename}" }]
    end

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_admin).and_return(nil)

      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js')))

      # Create the compiled template file so it can be read via its compiled_file_path
      FileUtils.mkdir_p(HandlebarsPrecompiler.templates_compiled_dir)
      compiled_file = HandlebarsPrecompiler.templates_compiled_dir.join(compiled_filename)
      File.write(compiled_file, '(function() { var t = Handlebars.template; })();')
    end

    # AC1: Skip all I/O if the multi file already exists
    context 'when the multi file already exists on disk' do
      it 'returns the correct URL path without re-reading individual compiled templates' do
        # First call creates the file
        url_first, = helper.write_multiple_handlebars_templates(templates)

        # Spy on File.read to ensure it is not called again for individual templates
        expect(File).not_to receive(:read).with(a_string_including('tpl_alpha'))

        url_second, = helper.write_multiple_handlebars_templates(templates)

        expect(url_second).to eq(url_first)
      end

      it 'does not call File.write on the second invocation' do
        # First call writes the file
        helper.write_multiple_handlebars_templates(templates)

        # Second call should skip writing entirely
        expect(File).not_to receive(:write)

        helper.write_multiple_handlebars_templates(templates)
      end
    end

    # AC1: Calling twice with same inputs only writes the file once
    context 'write count' do
      it 'calls File.write exactly once for two identical invocations' do
        write_count = 0
        allow(File).to receive(:write).and_wrap_original do |original, *args|
          # Only count writes to the multi dir
          write_count += 1 if args.first.to_s.include?('multi/')
          original.call(*args)
        end

        helper.write_multiple_handlebars_templates(templates)
        helper.write_multiple_handlebars_templates(templates)

        expect(write_count).to eq(1)
      end
    end

    # AC2: Filename does NOT contain current_sign_in_at
    context 'filename composition' do
      it 'does not include current_sign_in_at in the filename' do
        url, = helper.write_multiple_handlebars_templates(templates)
        filename = File.basename(url)

        # current_sign_in_at.to_i for Time.at(1_000_000) is "1000000"
        expect(filename).not_to include(sign_in_time.to_i.to_s)
      end

      # AC2: Filename does NOT change across different current_sign_in_at values
      it 'produces the same filename regardless of current_sign_in_at changes' do
        url_before, = helper.write_multiple_handlebars_templates(templates)

        # Simulate a new login with different sign_in_at
        new_user = Struct.new(:id, :current_sign_in_at, :app_type_id).new(42, Time.at(9_999_999), 7)
        allow(helper).to receive(:current_user).and_return(new_user)

        # Clean multi dir to force fresh write
        FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js')))

        url_after, = helper.write_multiple_handlebars_templates(templates)

        expect(File.basename(url_after)).to eq(File.basename(url_before))
      end

      # AC3: Filename contains user_id
      it 'includes the user_id in the filename' do
        url, = helper.write_multiple_handlebars_templates(templates)
        filename = File.basename(url)

        expect(filename).to include("-#{user.id}-")
      end

      # AC2: Filename includes access_control_version hash derived from userrole, uac, handlebars_cache_key
      it 'includes an access_control_version segment in the filename' do
        url, = helper.write_multiple_handlebars_templates(templates)
        filename = File.basename(url)

        # The filename should follow the pattern:
        # requested-templates-{user_id}-{app_type_id}-{req_digest}-{access_control_version}.js
        # access_control_version is a 13-char hex substring
        parts = filename.delete_suffix('.js').split('-')

        # Last segment should be a hex hash (access_control_version)
        last_segment = parts.last
        expect(last_segment).to match(/\A[a-f0-9]{13}\z/),
                                "Expected last filename segment '#{last_segment}' to be a 13-char hex access_control_version"
      end
    end

    # AC5: Filename changes when user roles/access controls change
    context 'when user roles or access controls change' do
      before do
        # Stub partial_cache_key related queries for access control version
        allow(Admin::UserRole).to receive_message_chain(:where, :reorder, :limit, :pluck).and_return([Time.at(2_000_000)])
        allow(Admin::UserAccessControl).to receive_message_chain(:where, :reorder, :limit, :pluck).and_return([Time.at(3_000_000)])
      end

      it 'produces a different filename when userrole timestamps change' do
        url_before, = helper.write_multiple_handlebars_templates(templates)

        # Clean multi dir and change userrole timestamp
        FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js')))
        allow(Admin::UserRole).to receive_message_chain(:where, :reorder, :limit, :pluck).and_return([Time.at(5_000_000)])

        # Clear any memoization
        helper.instance_variable_set(:@access_control_version, nil)

        url_after, = helper.write_multiple_handlebars_templates(templates)

        expect(File.basename(url_after)).not_to eq(File.basename(url_before))
      end

      it 'produces a different filename when user access control timestamps change' do
        url_before, = helper.write_multiple_handlebars_templates(templates)

        # Clean multi dir and change uac timestamp
        FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js')))
        allow(Admin::UserAccessControl).to receive_message_chain(:where, :reorder, :limit, :pluck).and_return([Time.at(8_000_000)])

        # Clear any memoization
        helper.instance_variable_set(:@access_control_version, nil)

        url_after, = helper.write_multiple_handlebars_templates(templates)

        expect(File.basename(url_after)).not_to eq(File.basename(url_before))
      end
    end

    # AC6: Filename changes when handlebars_cache_key changes (template content change)
    context 'when template content changes (handlebars_cache_key changes)' do
      it 'produces a different filename when handlebars_cache_key changes' do
        url_before, = helper.write_multiple_handlebars_templates(templates)

        # Simulate template content change: new cache key and new compiled file
        new_cache_key = 'newcachekey1234'
        allow(helper).to receive(:handlebars_cache_key).and_return(new_cache_key)

        new_compiled = HandlebarsPrecompiler.templates_compiled_dir.join("tpl_alpha-#{new_cache_key}.js")
        File.write(new_compiled, '(function() { var t = Handlebars.template; })();')

        # Clean multi dir to force fresh write
        FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.multi_dir.join('*.js')))

        # Clear any memoization
        helper.instance_variable_set(:@access_control_version, nil)

        url_after, = helper.write_multiple_handlebars_templates(templates)

        expect(File.basename(url_after)).not_to eq(File.basename(url_before))
      end
    end
  end

  # Issue #1279 - handlebars_cache_key / handlebars_compiled_filename not app_type-aware
  #
  # Proves that the single-template cache path (write_handlebars_template) uses a cache key
  # that does NOT incorporate app_type_id or per-app_type access control timestamps.
  # This causes cross-app_type cache poisoning: the first app_type context to compile a
  # template permanently "poisons" the on-disk file for all other app_type contexts.
  #
  # These tests fail against the CURRENT code (demonstrating the bug) and will pass
  # once handlebars_cache_key/handlebars_compiled_filename become app_type-aware,
  # mirroring the access_control_version pattern already used by write_multiple_handlebars_templates.
  describe '#handlebars_cache_key app_type scope (issue #1279)' do
    let(:user_app_type_1) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(10, 1, Time.current)
    end
    let(:user_app_type_2) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(20, 2, Time.current)
    end

    before do
      # Ensure distinct access control timestamps exist per app_type so the
      # cache key SHOULD differ between app_type contexts
      allow(Admin::UserRole).to receive(:where).and_call_original
      allow(Admin::UserAccessControl).to receive(:where).and_call_original

      role_rel_app1 = double('role_rel_app1')
      allow(role_rel_app1).to receive(:reorder).and_return(role_rel_app1)
      allow(role_rel_app1).to receive(:limit).and_return(role_rel_app1)
      allow(role_rel_app1).to receive(:pluck).and_return([Time.at(1_000_000)])

      role_rel_app2 = double('role_rel_app2')
      allow(role_rel_app2).to receive(:reorder).and_return(role_rel_app2)
      allow(role_rel_app2).to receive(:limit).and_return(role_rel_app2)
      allow(role_rel_app2).to receive(:pluck).and_return([Time.at(2_000_000)])

      uac_rel_app1 = double('uac_rel_app1')
      allow(uac_rel_app1).to receive(:reorder).and_return(uac_rel_app1)
      allow(uac_rel_app1).to receive(:limit).and_return(uac_rel_app1)
      allow(uac_rel_app1).to receive(:pluck).and_return([Time.at(3_000_000)])

      uac_rel_app2 = double('uac_rel_app2')
      allow(uac_rel_app2).to receive(:reorder).and_return(uac_rel_app2)
      allow(uac_rel_app2).to receive(:limit).and_return(uac_rel_app2)
      allow(uac_rel_app2).to receive(:pluck).and_return([Time.at(4_000_000)])

      allow(Admin::UserRole).to receive(:where).with(app_type_id: [1, nil]).and_return(role_rel_app1)
      allow(Admin::UserRole).to receive(:where).with(app_type_id: [2, nil]).and_return(role_rel_app2)
      allow(Admin::UserAccessControl).to receive(:where).with(app_type_id: [1, nil]).and_return(uac_rel_app1)
      allow(Admin::UserAccessControl).to receive(:where).with(app_type_id: [2, nil]).and_return(uac_rel_app2)
    end

    it 'produces different cache keys for different app_type contexts' do
      # Simulate first user context (app_type 1)
      allow(helper).to receive(:current_user).and_return(user_app_type_1)
      allow(helper).to receive(:current_admin).and_return(nil)
      key_app1 = helper.handlebars_cache_key

      # Clear memoization to simulate a separate request context
      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      # Simulate second user context (app_type 2)
      allow(helper).to receive(:current_user).and_return(user_app_type_2)
      key_app2 = helper.handlebars_cache_key

      # BUG: Currently both keys are identical because handlebars_cache_key
      # does not incorporate app_type_id or per-app_type access control timestamps.
      # This expectation will FAIL against current code, proving the bug.
      expect(key_app1).not_to eq(key_app2),
                              'Expected handlebars_cache_key to differ between app_type 1 and app_type 2, ' \
                              "but both returned '#{key_app1}'. The cache key is not app_type-aware (issue #1279)."
    end

    it 'produces different compiled filenames for different app_type contexts' do
      template_id = 'master_tabs'

      allow(helper).to receive(:current_user).and_return(user_app_type_1)
      allow(helper).to receive(:current_admin).and_return(nil)
      filename_app1 = helper.handlebars_compiled_filename(template_id)

      # Clear memoization
      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      allow(helper).to receive(:current_user).and_return(user_app_type_2)
      filename_app2 = helper.handlebars_compiled_filename(template_id)

      # BUG: Currently both filenames are identical.
      # This expectation will FAIL against current code, proving the bug.
      expect(filename_app1).not_to eq(filename_app2),
                                   "Expected handlebars_compiled_filename('#{template_id}') to differ between " \
                                   "app_type 1 and app_type 2, but both returned '#{filename_app1}'. " \
                                   'The compiled filename is not app_type-aware (issue #1279).'
    end
  end

  # Issue #1279 follow-up - app_type_id must be embedded directly in the digest
  #
  # handlebars_cache_key must never collide between app_type contexts, even when their
  # UserRole/UserAccessControl timestamps happen to be identical (e.g. both empty/nil,
  # such as for two brand new app types with no role/access-control rows yet). Relying
  # solely on the derived timestamps is not sufficient on its own.
  describe '#handlebars_cache_key app_type_id collision safety (issue #1279 follow-up)' do
    let(:user_app_type_1) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(10, 1, Time.current)
    end
    let(:user_app_type_2) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(20, 2, Time.current)
    end

    it 'differs between app_type contexts even when role/access-control timestamps are identical' do
      empty_rel = double('empty_rel')
      allow(empty_rel).to receive(:reorder).and_return(empty_rel)
      allow(empty_rel).to receive(:limit).and_return(empty_rel)
      allow(empty_rel).to receive(:pluck).and_return([])

      allow(Admin::UserRole).to receive(:where).with(app_type_id: [1, nil]).and_return(empty_rel)
      allow(Admin::UserRole).to receive(:where).with(app_type_id: [2, nil]).and_return(empty_rel)
      allow(Admin::UserAccessControl).to receive(:where).with(app_type_id: [1, nil]).and_return(empty_rel)
      allow(Admin::UserAccessControl).to receive(:where).with(app_type_id: [2, nil]).and_return(empty_rel)

      allow(helper).to receive(:current_user).and_return(user_app_type_1)
      allow(helper).to receive(:current_admin).and_return(nil)
      key_app1 = helper.handlebars_cache_key

      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      allow(helper).to receive(:current_user).and_return(user_app_type_2)
      key_app2 = helper.handlebars_cache_key

      expect(key_app1).not_to eq(key_app2),
                              'Expected handlebars_cache_key to differ between app_type 1 and app_type 2 even ' \
                              'when their role/access-control timestamps are identical (both empty), but both ' \
                              "returned '#{key_app1}'. app_type_id itself must be part of the digest (issue #1279)."
    end

    it 'differs between app_type contexts for the SAME user id, isolating the app_type_id contribution' do
      # user_app_type_1 and user_app_type_2 above vary both id and app_type_id together, which would
      # mask a regression that dropped app_type_id from the digest once user_id was added (issue #1279
      # follow-up: per-user scoping). This test holds the user id constant and only varies app_type_id.
      same_id_app_type_1 = Struct.new(:id, :app_type_id, :current_sign_in_at).new(99, 1, Time.current)
      same_id_app_type_2 = Struct.new(:id, :app_type_id, :current_sign_in_at).new(99, 2, Time.current)

      empty_rel = double('empty_rel')
      allow(empty_rel).to receive(:reorder).and_return(empty_rel)
      allow(empty_rel).to receive(:limit).and_return(empty_rel)
      allow(empty_rel).to receive(:pluck).and_return([])

      allow(Admin::UserRole).to receive(:where).with(app_type_id: [1, nil]).and_return(empty_rel)
      allow(Admin::UserRole).to receive(:where).with(app_type_id: [2, nil]).and_return(empty_rel)
      allow(Admin::UserAccessControl).to receive(:where).with(app_type_id: [1, nil]).and_return(empty_rel)
      allow(Admin::UserAccessControl).to receive(:where).with(app_type_id: [2, nil]).and_return(empty_rel)

      allow(helper).to receive(:current_user).and_return(same_id_app_type_1)
      allow(helper).to receive(:current_admin).and_return(nil)
      key_app1 = helper.handlebars_cache_key

      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      allow(helper).to receive(:current_user).and_return(same_id_app_type_2)
      key_app2 = helper.handlebars_cache_key

      expect(key_app1).not_to eq(key_app2),
                              'Expected handlebars_cache_key to differ between app_type 1 and app_type 2 for the ' \
                              "same user id (99), but both returned '#{key_app1}'. app_type_id must remain part " \
                              'of the digest even now that user id is also included (issue #1279 follow-up).'
    end
  end

  # Issue #1279 follow-up - per-user scoping
  #
  # Proves that handlebars_cache_key / handlebars_compiled_filename incorporate the current
  # user/admin id, so two different users within the SAME app_type never share a compiled
  # file. This matters because partials such as master_tabs render differently per user
  # based on individual role/access-control grants (see master_viewables, has_access_to?),
  # not just app_type. Without user scoping, the first user to compile the partial
  # permanently "poisons" the shared on-disk file for every other user in that app_type.
  describe '#handlebars_cache_key user scope (issue #1279 follow-up - per-user)' do
    let(:user_one) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(11, 1, Time.current)
    end
    let(:user_two) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(12, 1, Time.current)
    end

    before do
      allow(helper).to receive(:current_admin).and_return(nil)
    end

    it 'produces different cache keys for different users within the same app_type' do
      allow(helper).to receive(:current_user).and_return(user_one)
      key_user_one = helper.handlebars_cache_key

      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      allow(helper).to receive(:current_user).and_return(user_two)
      key_user_two = helper.handlebars_cache_key

      expect(key_user_one).not_to eq(key_user_two),
                                  'Expected handlebars_cache_key to differ between user 11 and user 12, both in ' \
                                  "app_type 1, but both returned '#{key_user_one}'. The cache key is not " \
                                  'per-user (issue #1279 follow-up).'
    end

    it 'produces different compiled filenames for different users within the same app_type' do
      template_id = 'master_tabs'

      allow(helper).to receive(:current_user).and_return(user_one)
      filename_user_one = helper.handlebars_compiled_filename(template_id)

      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      allow(helper).to receive(:current_user).and_return(user_two)
      filename_user_two = helper.handlebars_compiled_filename(template_id)

      expect(filename_user_one).not_to eq(filename_user_two),
                                       "Expected handlebars_compiled_filename('#{template_id}') to differ " \
                                       "between user 11 and user 12, but both returned '#{filename_user_one}'. " \
                                       'The compiled filename is not per-user (issue #1279 follow-up).'
    end

    it 'produces a stable cache key for the same user across separate request-like calls' do
      allow(helper).to receive(:current_user).and_return(user_one)
      key_first_call = helper.handlebars_cache_key

      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      key_second_call = helper.handlebars_cache_key

      expect(key_second_call).to eq(key_first_call),
                                 'Expected handlebars_cache_key to be stable for the same user across separate ' \
                                 "calls, but got '#{key_first_call}' then '#{key_second_call}'."
    end
  end

  # Issue #1279 follow-up - User/Admin id collision safety
  #
  # current_user_or_admin&.id alone can't distinguish a User with id N from an Admin with
  # id N. If both happened to resolve to the same app_type_id (Admin has no app_type_id
  # column at all, so it is always nil; a User with app_type_id: nil would match), the
  # digest would collide even though they are different accounts. handlebars_cache_key
  # must also fold in the resolved object's class name to eliminate this collision.
  # Uses real (unsaved) User/Admin instances rather than doubles so `.class.name` reflects
  # actual model class names.
  describe '#handlebars_cache_key User/Admin id collision safety (issue #1279 follow-up)' do
    it 'differs between a User and an Admin that share the same id and app_type_id' do
      user = User.new(id: 42, app_type_id: nil)
      admin = Admin.new(id: 42)

      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_admin).and_return(nil)
      key_for_user = helper.handlebars_cache_key

      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      allow(helper).to receive(:current_user).and_return(nil)
      allow(helper).to receive(:current_admin).and_return(admin)
      key_for_admin = helper.handlebars_cache_key

      expect(key_for_user).not_to eq(key_for_admin),
                                  'Expected handlebars_cache_key to differ between a User(id: 42) and an ' \
                                  "Admin(id: 42), but both returned '#{key_for_user}'. The user/admin class " \
                                  'name must be part of the digest to prevent id collisions (issue #1279 ' \
                                  'follow-up).'
    end
  end

  # Issue #1362 S9 fix: the former "#write_handlebars_template cross-user cache
  # poisoning within same app_type (issue #1279 follow-up)" spec block was removed here -
  # under content addressing it only proved that DIFFERENT content produces different
  # paths (true for any two users, tautological, and already covered more directly by
  # "content addressing sharing/isolation" above), and its "does not skip writing" example
  # built its fixture at the non-addressed handlebars_cache_key path, which
  # write_handlebars_template no longer checks for a content-addressed template id. The
  # actual #1279 guarantee (handlebars_cache_key/handlebars_compiled_filename differ per
  # user) is still directly tested by "#handlebars_cache_key user scope (issue #1279
  # follow-up - per-user)" below.

  # Issue #1279 follow-up - global (app_type_id: nil) role/access-control changes must
  # invalidate the cache key too.
  #
  # Admin::UserRole/Admin::UserAccessControl rows with app_type_id: nil apply across ALL
  # app types (matched by role_name, see UserAndRoles#where_user_and_role). If the cache
  # key query only matched the exact app_type_id, a change to a global/shared role or
  # access control would never be reflected in any app_type's cache key, serving stale
  # compiled content.
  describe '#handlebars_cache_key global (app_type_id: nil) scope (issue #1279 follow-up)' do
    let(:user_app_type_1) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(10, 1, Time.current)
    end

    it 'changes when a global (app_type_id: nil) UserRole updated_at changes' do
      allow(helper).to receive(:current_user).and_return(user_app_type_1)
      allow(helper).to receive(:current_admin).and_return(nil)

      rel_before = double('rel_before')
      allow(rel_before).to receive(:reorder).and_return(rel_before)
      allow(rel_before).to receive(:limit).and_return(rel_before)
      allow(rel_before).to receive(:pluck).and_return([Time.at(1_000_000)])
      allow(Admin::UserRole).to receive(:where).with(app_type_id: [1, nil]).and_return(rel_before)
      allow(Admin::UserAccessControl).to receive(:where).and_call_original

      key_before = helper.handlebars_cache_key

      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)

      rel_after = double('rel_after')
      allow(rel_after).to receive(:reorder).and_return(rel_after)
      allow(rel_after).to receive(:limit).and_return(rel_after)
      allow(rel_after).to receive(:pluck).and_return([Time.at(2_000_000)])
      allow(Admin::UserRole).to receive(:where).with(app_type_id: [1, nil]).and_return(rel_after)

      key_after = helper.handlebars_cache_key

      expect(key_after).not_to eq(key_before),
                               'Expected handlebars_cache_key to change when the global-scoped UserRole updated_at ' \
                               'timestamp changes (issue #1279 follow-up).'
    end
  end

  # Issue #1279 - write_handlebars_template cross-context cache poisoning
  #
  # Proves that write_handlebars_template, when called with the same template_id
  # but different current_user app_type contexts whose template content differs,
  # writes/reuses a SINGLE compiled file for both contexts. The first context to
  # compile "poisons" the cache for subsequent contexts.
  describe '#write_handlebars_template cross-context cache poisoning (issue #1279)' do
    let(:user_app_type_1) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(10, 1, Time.current)
    end
    let(:user_app_type_2) do
      Struct.new(:id, :app_type_id, :current_sign_in_at).new(20, 2, Time.current)
    end
    let(:template_id) { 'master_tabs' }
    let(:content_app1) { '<div class="panel-app1">{{panel_one}}</div>' }
    let(:content_app2) { '<div class="panel-app2">{{panel_two}}{{panel_three}}</div>' }

    before do
      allow(helper).to receive(:current_admin).and_return(nil)
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PARTIALS_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.templates_compiled_dir.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler.partials_compiled_dir.join('*')))
    end

    it 'writes separate temp files for different app_type contexts with the same template_id' do
      # First request: app_type 1 writes the template
      allow(helper).to receive(:current_user).and_return(user_app_type_1)
      path_app1 = helper.write_handlebars_template(template_id, content_app1, is_partial: true)

      # Clear memoization to simulate separate request from different app_type
      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)
      helper.instance_variable_set(:@handlebars_request_id, nil)

      # Second request: app_type 2 writes DIFFERENT content for the same template_id
      allow(helper).to receive(:current_user).and_return(user_app_type_2)
      path_app2 = helper.write_handlebars_template(template_id, content_app2, is_partial: true)

      # BUG: Currently both paths are identical because the compiled filename
      # does not vary by app_type. The second call would short-circuit if the
      # first call's compiled file already exists, "poisoning" the result.
      # This expectation will FAIL against current code, proving the bug.
      expect(path_app1).not_to eq(path_app2),
                               'Expected write_handlebars_template to produce different compiled file paths for ' \
                               "different app_type contexts (app_type 1 vs 2), but both returned '#{path_app1}'. " \
                               'Cross-context cache poisoning: first app_type to compile wins (issue #1279).'
    end

    it 'does not skip writing when a compiled file exists from a different app_type context' do
      # Simulate app_type 1 having already compiled the template
      allow(helper).to receive(:current_user).and_return(user_app_type_1)
      compiled_filename = helper.handlebars_compiled_filename(template_id)
      public_dir = helper.handlebars_public_dir(is_partial: true)
      FileUtils.mkdir_p(public_dir)
      compiled_file = public_dir.join(compiled_filename)
      File.write(compiled_file, "// compiled for app_type 1: #{content_app1}")

      # Clear memoization to simulate separate request from different app_type
      helper.instance_variable_set(:@handlebars_cache_key, nil)
      helper.instance_variable_set(:@handlebars_item_updates_key, nil)
      helper.instance_variable_set(:@handlebars_request_id, nil)

      # Now app_type 2 calls write_handlebars_template with DIFFERENT content
      allow(helper).to receive(:current_user).and_return(user_app_type_2)
      helper.write_handlebars_template(template_id, content_app2, is_partial: true)

      # Check that the temp file was written (i.e. the template was NOT skipped)
      request_dir = helper.handlebars_temp_dir(is_partial: true)
      temp_file = request_dir.join("#{template_id}.handlebars")

      # BUG: Currently the method returns early because it finds the compiled file
      # from app_type 1 (same filename), so the temp file is never written.
      # This expectation will FAIL against current code, proving the bug.
      expect(File.exist?(temp_file)).to be(true),
                                        'Expected write_handlebars_template to write a temp file for app_type 2, ' \
                                        'but it skipped because a compiled file from app_type 1 already exists at ' \
                                        "'#{compiled_file}'. Cross-context cache poisoning (issue #1279)."
    end
  end
end
