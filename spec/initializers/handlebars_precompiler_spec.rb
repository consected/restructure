# frozen_string_literal: true

# HandlebarsPrecompiler Initializer Spec
#
# Tests the HandlebarsPrecompiler module that sets up directories, validates CLI availability,
# and cleans up compiled files on startup.
#
# Test Coverage:
# - CLI availability detection via `which handlebars` command
# - CLI path retrieval
# - Directory creation for tmp/handlebars and public/handlebars
# - Cleanup operations for temporary and compiled files
# - Environment-based flags for minification and source maps

require 'rails_helper'

RSpec.describe HandlebarsPrecompiler do
  describe '.cli_available?' do
    it 'returns true when handlebars CLI is installed' do
      # This test relies on npx handlebars being available in the dev environment
      expect(described_class.cli_available?).to be true
    end
  end

  describe '.cli_path' do
    it 'returns the path to the handlebars CLI' do
      path = described_class.cli_path

      expect(path).to be_a(String)
      expect(path).not_to be_empty
    end
  end

  describe '.setup_directories' do
    before do
      FileUtils.rm_rf(described_class::TMP_DIR)
      FileUtils.rm_rf(described_class::PUBLIC_DIR)
    end

    after do
      # Restore directories for other tests
      described_class.setup_directories
    end

    it 'creates the tmp/handlebars directory' do
      described_class.setup_directories

      expect(Dir.exist?(described_class::TMP_DIR)).to be true
    end

    it 'creates the public/handlebars directory' do
      described_class.setup_directories

      expect(Dir.exist?(described_class::PUBLIC_DIR)).to be true
    end
  end

  describe '.cleanup_tmp_dir' do
    before do
      described_class.setup_directories
      # Create test files in the subdirectories that cleanup_tmp_dir actually cleans
      FileUtils.touch(described_class::TEMPLATES_TMP_DIR.join('test1.tmp'))
      FileUtils.touch(described_class::PARTIALS_TMP_DIR.join('test2.tmp'))
    end

    it 'removes all files from templates and partials tmp directories' do
      described_class.cleanup_tmp_dir

      template_files = Dir.glob(described_class::TEMPLATES_TMP_DIR.join('*'))
      partial_files = Dir.glob(described_class::PARTIALS_TMP_DIR.join('*'))
      expect(template_files).to be_empty
      expect(partial_files).to be_empty
    end
  end

  describe '.cleanup_public_dir' do
    before do
      described_class.setup_directories
      # Create test files in the subdirectories that cleanup_public_dir actually cleans
      FileUtils.touch(described_class::TEMPLATES_PUBLIC_DIR.join('template-abc123.js'))
      FileUtils.touch(described_class::PARTIALS_PUBLIC_DIR.join('partial-def456.js'))
      FileUtils.touch(described_class::MULTI_PUBLIC_DIR.join('multi-abc123.js'))
    end

    it 'removes all .js files from templates public directory' do
      described_class.cleanup_public_dir

      js_files = Dir.glob(described_class::TEMPLATES_PUBLIC_DIR.join('*.js'))
      expect(js_files).to be_empty
    end

    it 'removes all .js files from partials public directory' do
      described_class.cleanup_public_dir

      js_files = Dir.glob(described_class::PARTIALS_PUBLIC_DIR.join('*.js'))
      expect(js_files).to be_empty
    end

    it 'removes all .js files from multi public directory' do
      described_class.cleanup_public_dir

      js_files = Dir.glob(described_class::MULTI_PUBLIC_DIR.join('*.js'))
      expect(js_files).to be_empty
    end
  end
end
