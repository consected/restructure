# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for issue #1181 — when navigating an admin page, the
# main template should be loaded in the background and the admin UI must not
# be blocked by the "loading..." splash guard. The Javascript state must
# expose `_fpa.state.is_admin_page === true` for admin controllers so the
# front-end can take the non-blocking code path.

describe 'admin pages do not block on main template load', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    Admin.transaction do
      make_an_admin
    end
  end

  it 'exposes _fpa.state.is_admin_page = true and reaches status-compiled on the admin index' do
    admin_sign_in_with_2fa

    visit '/admin/app_types'

    using_wait_time(30) { expect(page).to have_css('body.status-compiled') }

    is_admin_page = page.evaluate_script('window._fpa && _fpa.state && _fpa.state.is_admin_page === true')
    expect(is_admin_page).to be true
  end

  it 'exposes _fpa.state.is_admin_page = true on the admin landing page (pages#index via admin layout)' do
    admin_sign_in_with_2fa

    # After sign-in, the admin lands on `pages#index` rendered with the
    # admin_application layout. This is not an `Admin::*` controller, so
    # detection must rely on the admin-page indicator rather than the
    # controller namespace alone.
    visit '/'

    using_wait_time(30) { expect(page).to have_css('body.status-compiled') }

    is_admin_page = page.evaluate_script('window._fpa && _fpa.state && _fpa.state.is_admin_page === true')
    expect(is_admin_page).to be true
  end
end
