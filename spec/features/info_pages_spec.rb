# frozen_string_literal: true

require 'rails_helper'

describe 'public info pages', js: true, driver: :app_firefox_driver do
  include UserSupport

  before :all do
    @page_name = 'test-page-123'
    @page_name_not_public = 'test-page-123-not-public'

    create_admin

    t = <<~END_TEXT
      # Welcome

      This is a test
    END_TEXT
    Admin::MessageTemplate.create! name: @page_name, message_type: :dialog, template_type: :content, category: 'public',
                                   template: t, current_admin: @admin

    Admin::MessageTemplate.create! name: @page_name_not_public, message_type: :dialog, template_type: :content, category: 'test',
                                   template: t, current_admin: @admin
  end

  it 'shows a not found message if the message template name does not exist' do
    visit 'info_pages/no-page'
    expect(page).to have_content 'Page Not Found'
  end

  it 'shows a not found message if the message template does not have the category=public' do
    visit "info_pages/#{@page_name_not_public}"
    expect(page).to have_content 'Page Not Found'
  end

  it 'shows a content page even when not signed in' do
    visit "info_pages/#{@page_name}"
    expect(page).to have_content 'Welcome'
  end
end
