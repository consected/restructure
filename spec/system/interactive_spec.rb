### Used for interactive debugging and development of feature specs.
# Run with `app-scripts/interactive-capybara.sh``
# Allow the test to pause and enter an interactive debugging session.
# Issue a `sleep 1` command in the debugger to allow the server to process requests.
# Or use `finish_form_formatting`, `finish_page_loading` or similar Capybara methods
# to wait for the requests to complete.
require 'rails_helper'

RSpec.describe 'Interactive', type: :system, js: true, skip: !ENV['INTERACTIVE'] do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:each) do
    create_user_for_login
    puts "Created test user for login: #{@user.email} / #{@good_password}"
  end

  it 'renders the interactive page' do
    visit '/'
    interactive_debug_session
  end
end
