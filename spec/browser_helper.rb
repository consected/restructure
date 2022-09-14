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

    unless ENV['NOT_HEADLESS'] == 'true'

      rfbport = 5911 #+ ENV['TEST_ENV_NUMBER'].to_i
      displaynum = 99 #+ ENV['TEST_ENV_NUMBER'].to_i
      puts 'To disable headless mode, run rspec with environment variable `NOT_HEADLESS=true rspec`'
      ENV['DISPLAY'] = ":#{displaynum}"
      if `pgrep Xvfb`.blank?
        xvfb_cmd = ['Xvfb', '+extension', 'RANDR', ":#{displaynum}", '-screen', '0', '1600x1000x16']
        puts "Start new Xvfb headless X server with DISPLAY #{ENV['DISPLAY']}"
        puts 'if this blocks, run directly as:'
        puts xvfb_cmd.join(' ').to_s
        # Run the framebuffer and immediately return, then detach since we don't want this to eventually block
        pid = spawn(*xvfb_cmd)
        Process.detach pid
        puts 'New Xvfb headless X server is running'
        `ps -p #{pid}`
      end
      if `pgrep x11vnc`.blank?
        puts "New x11vnc server will start on port #{rfbport} with display #{ENV['DISPLAY']} in 5 seconds"
        `sleep 5; x11vnc -display $DISPLAY -bg -nopw -listen localhost -xkb  -rfbport #{rfbport}`
      end
      puts 'Xvfb headless X server and x11vnc have been started'
    end

    cb = Capybara
    cb.server = :webrick

    cb.register_driver :app_firefox_driver do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile['browser.download.dir'] = '~/Downloads'
      profile['browser.download.folderList'] = 2
      profile['browser.helperApps.alwaysAsk.force'] = false
      profile['browser.download.manager.showWhenStarting'] = false
      profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv'
      profile['csvjs.disabled'] = true
      Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile)
    end

    cb.current_driver = :app_firefox_driver
    cb.default_max_wait_time = 25

    puts '--> Done setup browser'
  end
end
