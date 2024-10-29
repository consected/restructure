# frozen_string_literal: true

module BrowserHelper
  @@running = false

  def setup_browser
    return if @@running

    puts '--> Setup browser'

    # Support parallel tests
    Capybara.configure do |config|
      config.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i
    end

    @@running = true

    ENV['LANGUAGE'] = 'en_US:en'
    ENV['LC_TIME'] = 'en_US.UTF-8'
    ENV['LC_NAME'] = 'en_US.UTF-8'
    ENV['LC_LANG'] = 'en_US.UTF-8'
    ENV['LANG'] = 'en_US.UTF-8'
    ENV['TZ'] = 'US/Eastern'

    browser_args = []
    browser_args << '--devtools' if ENV['DEBUG_JS'] == 'true'
    browser_args << '--headless' unless ENV['NOT_HEADLESS'] == 'true'
    # browser_args << '--new-instance'

    cb = Capybara
    cb.server = :puma
    # cb.threadsafe = true
    cb.reuse_server = false
    service = nil
    cb.register_driver :app_firefox_driver do |app|
      options = Selenium::WebDriver::Firefox::Options.new(args: browser_args)
      service = Selenium::WebDriver::Firefox::Service.new

      exe = ENV['GECKO_PATH']
      exe = if exe.blank?
              alt_exe = ['/snap/bin/firefox.geckodriver', '/usr/local/bin/geckodriver']
              exe = alt_exe.select { |p| File.exist?(p) }.first
            end

      service.executable_path = exe
      if ENV['DEBUG_JS'] == 'true'
        # service.log = $stdout
        options.add_preference('browser.logging_prefs', 'ALL')
        options.add_preference('devtools.console.stdout.content', true)
      end
      options.add_preference('browser.download.dir', '~/Downloads')
      options.add_preference('browser.download.folderList', 2)
      options.add_preference('browser.helperApps.alwaysAsk.force', false)
      options.add_preference('browser.download.manager.showWhenStarting', false)
      options.add_preference('browser.helperApps.neverAsk.saveToDisk', 'text/csv')
      options.add_preference('csvjs.disabled', true)

      Capybara::Selenium::Driver.new(
        app,
        browser: :firefox,
        options:,
        service:
      )
    end

    cb.current_driver = :app_firefox_driver
    cb.default_max_wait_time = 2.5

    puts '--> Done setup browser'
  end
end
