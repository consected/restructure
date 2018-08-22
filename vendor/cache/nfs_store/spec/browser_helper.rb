module BrowserHelper

  @@running = false

  def setup_browser

    return if @@running

    puts "--> Setup browser"

    @@running = true

    ENV['LANGUAGE']='en_US:en'
    ENV['LC_TIME']='en_US.UTF-8'
    ENV['LC_NAME']='en_US.UTF-8'
    ENV['LC_LANG']='en_US.UTF-8'
    ENV['LANG']='en_US.UTF-8'

    unless ENV['NOT_HEADLESS']=='true'
      puts "To disable headless mode, run rspec with environment variable `NOT_HEADLESS=true rspec`"
      ENV['DISPLAY']=':99'
      if `pgrep Xvfb`.blank?
        puts "Running new Xvfb headless X server"
        `Xvfb +extension RANDR :99 -screen 0 1600x1000x16 &`
      end
      if `pgrep x11vnc`.blank?
        puts "New x11vnc server will start on port 5901 with display #{ENV['DISPLAY']} in 5 seconds"
        `sleep 5; x11vnc -display $DISPLAY -bg -nopw -listen localhost -xkb  -rfbport 5901`
      end
      puts "Xvfb headless X server and x11vnc have been started"
    end

    cb = Capybara

    cb.register_driver :app_firefox_driver do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile['browser.download.dir'] = "~/Downloads"
      profile['browser.download.folderList'] = 2
      profile['browser.helperApps.alwaysAsk.force'] = false
      profile['browser.download.manager.showWhenStarting'] = false
      profile['browser.helperApps.neverAsk.saveToDisk'] = "text/csv"
      profile['csvjs.disabled'] = true
      Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
    end

    cb.current_driver = :app_firefox_driver
    cb.default_max_wait_time = 25
  end
end
