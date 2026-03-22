# frozen_string_literal: true

module BrowserHelper
  BASE_BROWSER_PORT = 9887
  @@running = {}
  $browser_driver = nil

  def setup_browser
    test_num = ENV['TEST_ENV_NUMBER'].to_i
    return if @@running[test_num]

    # Support parallel tests
    @@running[test_num] = true

    puts '--> Setup browser'

    is_not_in_use = false
    portnum = nil
    100.times do
      portnum = BASE_BROWSER_PORT + test_num
      # Try binding the port directly — more reliable than lsof which may not
      # be in PATH or may miss sockets in certain states (TIME_WAIT, etc.)
      begin
        server = TCPServer.new('127.0.0.1', portnum)
        server.close
        is_not_in_use = true
        break
      rescue Errno::EADDRINUSE
        test_num += 1
      end
    end

    if is_not_in_use
      puts "Using port #{portnum}"
    else
      puts 'All ports are in use - exit'
      exit 1
    end

    Capybara.configure do |config|
      config.server_port = portnum
    end

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
    # cb.server = :puma
    # cb.reuse_server = false
    service = nil

    if ENV['BROWSER'] == 'firefox'
      $browser_driver = :app_firefox_driver
      puts '--> Using Firefox browser for tests'
      cb.register_driver $browser_driver do |app|
        set_up_firefox_driver(app, browser_args)
      end
    else
      $browser_driver = :app_chrome_driver
      puts '--> Using Chrome browser for tests'
      cb.register_driver $browser_driver do |app|
        set_up_chrome_driver(app, browser_args)
      end
    end

    cb.current_driver = $browser_driver
    cb.default_max_wait_time = 2.5

    Selenium::WebDriver.logger.ignore(:clear_local_storage, :clear_session_storage)

    puts '--> Done setup browser'
  end

  def set_up_chrome_driver(app, browser_args)
    options = Selenium::WebDriver::Chrome::Options.new(args: browser_args)
    service = Selenium::WebDriver::Chrome::Service.new
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
      browser: :chrome,
      options:,
      service:
    )
  end

  def set_up_firefox_driver(app, browser_args)
    options = Selenium::WebDriver::Firefox::Options.new(args: browser_args)
    service = Selenium::WebDriver::Firefox::Service.new

    exe = ENV.fetch('GECKO_PATH', nil)
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
end
