# frozen_string_literal: true

# HandlebarsPrecompiler Module
#
# Provides server-side Handlebars template precompilation using the handlebars CLI.
# Sets up directories, validates CLI availability, and cleans up compiled files on startup.
module HandlebarsPrecompiler
  HANDLEBARS_CLI = ENV.fetch('HANDLEBARS_CLI', 'npx handlebars')

  # Environment-specific directory naming for test isolation
  # In test mode with parallel execution, TEST_ENV_NUMBER provides isolation
  HANDLEBARS_DIR_NAME = begin
    base_name = "handlebars-#{Rails.env}"
    test_suffix = ENV['TEST_ENV_NUMBER'].to_s.strip
    test_suffix.empty? ? base_name : "#{base_name}-#{test_suffix}"
  end

  TMP_DIR = Rails.root.join('tmp', HANDLEBARS_DIR_NAME)
  TEMPLATES_TMP_DIR = TMP_DIR.join('templates')
  PARTIALS_TMP_DIR = TMP_DIR.join('partials')
  PUBLIC_DIR = Rails.root.join('public', HANDLEBARS_DIR_NAME)
  TEMPLATES_PUBLIC_DIR = PUBLIC_DIR.join('templates')
  PARTIALS_PUBLIC_DIR = PUBLIC_DIR.join('partials')
  MULTI_PUBLIC_DIR = PUBLIC_DIR.join('multi')

  URL_RELATIVE_PATH = "/#{HANDLEBARS_DIR_NAME}/"

  class << self
    def cli_available?
      @cli_available ||= system("#{HANDLEBARS_CLI} --version > /dev/null 2>&1")
    end

    def cli_path
      # For npx, just return the command itself since it's not a direct path
      @cli_path ||= if HANDLEBARS_CLI.start_with?('npx')
                      HANDLEBARS_CLI
                    else
                      `which #{HANDLEBARS_CLI}`.strip
                    end
    end

    def setup_directories
      FileUtils.mkdir_p(TMP_DIR)
      FileUtils.mkdir_p(TEMPLATES_TMP_DIR)
      FileUtils.mkdir_p(PARTIALS_TMP_DIR)
      FileUtils.mkdir_p(PUBLIC_DIR)
      FileUtils.mkdir_p(TEMPLATES_PUBLIC_DIR)
      FileUtils.mkdir_p(PARTIALS_PUBLIC_DIR)
      FileUtils.mkdir_p(MULTI_PUBLIC_DIR)
    end

    def cleanup_tmp_dir
      FileUtils.rm_rf(Dir.glob(TEMPLATES_TMP_DIR.join('*')))
      FileUtils.rm_rf(Dir.glob(PARTIALS_TMP_DIR.join('*')))
    end

    # Delete ALL precompiled files on startup
    def cleanup_public_dir
      FileUtils.rm_rf(Dir.glob(TEMPLATES_PUBLIC_DIR.join('*.js')))
      FileUtils.rm_rf(Dir.glob(PARTIALS_PUBLIC_DIR.join('*.js')))
      FileUtils.rm_rf(Dir.glob(MULTI_PUBLIC_DIR.join('*.js')))
    end
  end
end

# Initialize on Rails startup (but not during asset precompilation or rake tasks)
Rails.application.config.after_initialize do
  next if defined?(Rake) && Rake.application.top_level_tasks.any? { |t| t.start_with?('assets:') }

  HandlebarsPrecompiler.setup_directories
  HandlebarsPrecompiler.cleanup_tmp_dir
  HandlebarsPrecompiler.cleanup_public_dir

  unless HandlebarsPrecompiler.cli_available?
    msg = 'Handlebars CLI not found. Install with: npm install --global handlebars'
    Rails.logger.error msg
    # Don't raise in test environment to allow tests to run
    raise msg unless Rails.env.test?
  end

  Rails.logger.info "HandlebarsPrecompiler initialized. CLI: #{HandlebarsPrecompiler.cli_path}"
end
