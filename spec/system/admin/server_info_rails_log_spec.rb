# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Rails Log Viewer', js: true, type: :system do
  include MasterSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    create_admin
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  it 'shows the search, exclude, and context fields and common search links' do
    visit '/admin/server_info/rails_log'
    finish_page_loading

    expect(page).to have_field('search regex')
    expect(page).to have_field('exclude regex (lines NOT containing)')
    expect(page).to have_field('trailing context lines')
    expect(page).to have_button('search')
    expect(page).to have_link('ERROR')
    expect(page).to have_link('FATAL')
    expect(page).to have_link('500 errors')
    expect(page).to have_link('POST requests')
    expect(page).to have_link('200 responses')
  end

  it 'returns log lines matching search and not matching exclude' do
    # Ensure the test log file contains the expected lines
    log_path = Rails.root.join('log', 'test.log')
    log_lines = [
      'Started GET "/test1" for 127.0.0.1 at 2026-01-19 12:00:00 +0000',
      'Processing by TestController#index as HTML',
      'Completed 200 OK in 10ms',
      '',
      'Started POST "/test2" for 127.0.0.1 at 2026-01-19 12:01:00 +0000',
      'Processing by TestController#create as HTML',
      'Completed 500 ERROR',
      '',
      'Started GET "/test3" for 127.0.0.1 at 2026-01-19 12:02:00 +0000',
      'Processing by TestController#show as HTML'
    ]
    File.open(log_path, 'a') { |f| log_lines.each { |l| f.puts l } }

    visit '/admin/server_info/rails_log?search=Started&exclude=POST&trailing_context=2'
    finish_page_loading
    log_text = find('#rails-log-listing', visible: true).text
    raise "Log command failed: #{log_text}" if log_text.include?('log not available:')

    # Should include GET lines that match "Started" and don't contain POST
    expect(log_text).to include('Started GET "/test1"')
    expect(log_text).to include('Started GET "/test3"')
    # Context lines for the GET matches should be included
    expect(log_text).to include('Processing by TestController#index')
    # The "Started POST" line should NOT appear as a primary match
    # (it matches "Started" but is excluded because it contains POST)
    # However, since there's a blank line separating it from GET requests,
    # and trailing_context=2, it should NOT appear
    expect(log_text).not_to include('Started POST')
  end

  it 'shows full width log output with horizontal scroll' do
    visit '/admin/server_info/rails_log?search=ERROR'
    finish_page_loading
    log_pre = find('#rails-log-listing', visible: true)
    # The <pre> should have CSS class for proper width styling with horizontal scroll
    expect(log_pre[:class]).to include('rails-log__listing')
  end

  it 'safely handles regex patterns that could contain injection attempts' do
    # Ensure malicious patterns are treated as literal regex, not executed
    log_path = Rails.root.join('log', 'test.log')
    log_lines = [
      'Normal log line with GET',
      'Another line'
    ]
    File.open(log_path, 'a') { |f| log_lines.each { |l| f.puts l } }

    # Try to inject a command through the search or exclude pattern
    malicious_search = 'GET/ { system("echo HACKED") } /fake'
    visit "/admin/server_info/rails_log?search=#{CGI.escape(malicious_search)}&exclude=POST"
    finish_page_loading
    log_text = find('#rails-log-listing', visible: true).text

    # Should not contain any output from injected command
    expect(log_text).not_to include('HACKED')
    # Should treat the pattern as a literal regex (which won't match anything)
    expect(log_text).not_to include('Normal log line with GET')
  end
end
