# frozen_string_literal: true

require 'rails_helper'

# Purpose (issue #1565): the master record banner (.player-info-header) must show the same
# date of birth as the player info record, whatever timezone the browser is in, for a user whose
# user preference timezone is 'Eastern Time (US & Canada)' and date format is mm/dd/yyyy.
#
# The browser inherits ENV['TZ'] and the locale variables from the process when it is launched, so each
# example quits the current browser, sets them, and lets Capybara launch a fresh browser. The browser's real
# UTC offset and locale are asserted before checking the banner, so a failure to apply them cannot give a false pass.
# Dates either side of DST changes (and on a day boundary) are covered for zones west of, at and east of UTC.
describe 'master banner date of birth across browser timezones', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  # Browser timezone => browser locale. Europe/London uses en_GB, matching the production browser in the report
  browser_zones = {
    'GMT' => 'en_GB',
    'Europe/London' => 'en_GB',
    'US/Eastern' => 'en_US',
    'Pacific/Auckland' => 'en_US'
  }.freeze
  locale_env_keys = %w[LANGUAGE LANG LC_ALL LC_TIME LC_NAME LC_LANG].freeze
  birth_dates = [Date.new(1980, 5, 3), Date.new(1980, 1, 1), Date.new(1980, 3, 9), Date.new(1980, 11, 2)].freeze

  before(:all) do
    # Captured first so after(:all) can always restore the environment, even if setup fails
    @original_env = (locale_env_keys + ['TZ']).index_with { |k| ENV.fetch(k, nil) }

    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    @admin, = create_admin
    @user, @good_password = create_user(create_master: true)
    @good_email = @user.email

    @user.user_preference.update!(timezone: 'Eastern Time (US & Canada)', date_format: 'mm/dd/yyyy')

    setup_access :player_infos, user: @user
    setup_access :create_master, resource_type: :general, access: :read, user: @user
    add_app_config(@user.app_type, 'create master with', 'player_info')
  end

  after(:all) do
    @original_env.each { |k, v| ENV[k] = v }
    quit_browser
  end

  def quit_browser
    driver = Capybara.current_session.driver
    driver.quit if driver.respond_to?(:quit)
  end

  def create_master_with_birth_date(birth_date)
    master = Master.create!(current_user: @user)
    PlayerInfo.create!(master:, first_name: 'Dobtest', last_name: 'Banner', birth_date:, rank: 10,
                       source: 'nflpa', current_user: @user)
    master
  end

  # Minutes ahead of UTC that the browser applies on the given date (reflects its timezone and DST)
  def browser_utc_offset_minutes(date)
    -page.evaluate_script("new Date(#{date.year}, #{date.month - 1}, #{date.day}, 12).getTimezoneOffset()")
  end

  def expected_utc_offset_minutes(zone, date)
    TZInfo::Timezone.get(zone).period_for_utc(Time.utc(date.year, date.month, date.day, 12)).utc_total_offset / 60
  end

  def expected_text(birth_date)
    birth_date.strftime('%m/%d/%Y')
  end

  browser_zones.each do |zone, locale|
    birth_dates.each do |birth_date|
      it "shows #{birth_date} in the banner and the player info for a #{zone} / #{locale} browser" do
        quit_browser
        ENV['TZ'] = zone
        ENV['LANGUAGE'] = "#{locale}:#{locale.split('_').first}"
        locale_env_keys.excluding('LANGUAGE').each { |k| ENV[k] = "#{locale}.UTF-8" }

        master = create_master_with_birth_date(birth_date)
        login
        navigate_to_master(master.id)

        expect(browser_utc_offset_minutes(birth_date)).to eq(expected_utc_offset_minutes(zone, birth_date))
        expect(page.evaluate_script('navigator.language')).to start_with(locale.tr('_', '-'))

        banner = find("#master-#{master.id} .player-info-header", match: :first)
        expect(banner).to have_text("DOB #{expected_text(birth_date)}")

        record_dob = find("#player-info-#{master.id}-#{master.player_infos.first.id} .player-info-birth_date strong")
        expect(record_dob.text).to match(%r{0?#{birth_date.month}/0?#{birth_date.day}/#{birth_date.year}})
      end
    end
  end
end
