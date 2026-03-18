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

  describe '#write_handlebars_template' do
    let(:template_id) { 'test-template' }
    let(:template_content) { '<div>{{name}}</div>' }
    let(:cache_key) { 'abc123def4567' }
    let(:expected_filename) { "#{template_id}-#{cache_key}.js" }

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      # Ensure clean state and directories exist
      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PARTIALS_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::PUBLIC_DIR.join('*')))
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

        expect(result).to eq("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}templates/#{expected_filename}")
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

        expect(result).to eq("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}templates/#{expected_filename}")
      end
    end

    context 'when compiled file already exists in public directory' do
      before do
        FileUtils.mkdir_p(HandlebarsPrecompiler::TEMPLATES_PUBLIC_DIR)
        compiled_file = HandlebarsPrecompiler::TEMPLATES_PUBLIC_DIR.join(expected_filename)
        File.write(compiled_file, '// already compiled')
      end

      it 'does not write temp file (avoids recompilation)' do
        helper.write_handlebars_template(template_id, template_content)

        temp_file = HandlebarsPrecompiler::TEMPLATES_TMP_DIR.join("#{template_id}.handlebars")
        expect(File.exist?(temp_file)).to be false
      end

      it 'returns correct URL path to existing compiled file' do
        result = helper.write_handlebars_template(template_id, template_content)

        expect(result).to eq("#{HandlebarsPrecompiler::URL_RELATIVE_PATH}templates/#{expected_filename}")
      end
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
        compiled_files = Dir.glob(HandlebarsPrecompiler::TEMPLATES_PUBLIC_DIR.join('integration-test-*.js'))
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

  describe '#write_multiple_handlebars_templates' do
    let(:cache_key) { 'multi123456789' }

    before do
      allow(helper).to receive(:handlebars_cache_key).and_return(cache_key)
      allow(helper).to receive(:current_user).and_return(Struct.new(:id, :current_sign_in_at, :app_type_id).new(1, Time.at(1000000), 2))
      allow(helper).to receive(:current_admin).and_return(nil)

      HandlebarsPrecompiler.setup_directories
      FileUtils.rm_rf(Dir.glob(HandlebarsPrecompiler::MULTI_PUBLIC_DIR.join('*.js')))
    end

    it 'generates multi file URL without double slashes' do
      # Create a compiled template file so read_handlebars_template can find it
      FileUtils.mkdir_p(HandlebarsPrecompiler::TEMPLATES_PUBLIC_DIR)
      compiled_file = HandlebarsPrecompiler::TEMPLATES_PUBLIC_DIR.join("test_template-#{cache_key}.js")
      File.write(compiled_file, '(function() { var template = Handlebars.template; })();')

      templates = [{ id: 'test_template', is_partial: false, compiled_file_path: 'irrelevant' }]
      url, = helper.write_multiple_handlebars_templates(templates)

      expect(url).not_to include('//')
      expect(url).to start_with(HandlebarsPrecompiler::URL_RELATIVE_PATH)
      expect(url).to include('/multi/')
    end
  end
end
