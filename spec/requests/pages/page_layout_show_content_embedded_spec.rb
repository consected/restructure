# frozen_string_literal: true

# Regression spec for GitHub Issue #1252.
#
# PageLayoutsController#show_content renders page_layouts/_sidebar_show.erb for
# non-HTML (AJAX) requests. That partial renders help/show_embedded, which previously
# raised NameError because `library`, `section` and `subsection` are only defined as
# helper_methods in HelpController. When the partial is rendered from
# PageLayoutsController those methods are absent.
#
# The fix adds `unless defined?` guards to _show_embedded.html.erb so that nil
# defaults are used when the partial is called outside HelpController.
#
# This spec exercises the full show_content path to ensure:
#   - No NameError is raised
#   - The embedded help wrapper div (from _show_embedded) is present in the response
#   - The response status is 200

require 'rails_helper'

RSpec.describe 'PageLayouts show_content embedded view', type: :request do
  include ModelSupport

  before(:each) do
    @admin, = create_admin
    @user, = create_user
    @app_type = @user.app_type

    # The user needs view_pages access to pass PageLayoutsController#show_authorized?
    # can?(:view_pages) maps to has_access_to?(:access, :general, :view_pages)
    # which resolves via the combo level :access => [:read] for :general resources.
    setup_access :view_pages, resource_type: :general, access: :read, user: @user

    # A minimal standalone page layout in the user's app type.
    # layout_name must be 'standalone' or 'view' (the :showable scope) so that
    # active_layouts (app_show_layouts) returns it for the show_content before_action.
    @page_layout = Admin::PageLayout.create!(
      layout_name: 'standalone',
      panel_name: 'regression_1252_embedded_view',
      panel_label: 'Regression 1252 Embedded View',
      app_type: @app_type,
      current_admin: @admin,
      options: "container:\n  rows:\n"
    )

    # Sign in as the regular user
    sign_out :user
    @user.confirmed_at ||= Time.now
    @user.current_admin ||= @admin
    @user.save
    get '/users/sign_in'
    sign_in @user
  end

  it 'renders without NameError and includes the help wrapper when hit via AJAX' do
    # Non-HTML Accept header triggers the non-html branch in show_content:
    #   render(partial: 'page_layouts/sidebar_show', ...)
    # which renders help/_show_embedded, which renders help/_in_new_tab_link.
    #
    # display_as=embedded makes display_embedded? return true, so _in_new_tab_link
    # enters the branch that calls `library`, `section` and `subsection`. Those are
    # helper_methods defined only in HelpController; from PageLayoutsController they
    # are undefined and raise NameError. The fix wraps that block in
    # begin…rescue StandardError so the render completes instead of returning 500.
    #
    # Without the rescue the response would be 500; with it the partial is skipped
    # gracefully and the surrounding help-view-doc wrapper is still rendered.
    #
    # master_id=0 → Master.find_with returns nil → set_page_filters returns early;
    # the render still proceeds.
    get "/content/#{@page_layout.id}/0/none",
        params: { display_as: 'embedded' },
        headers: { 'Accept' => 'text/javascript' }

    expect(response).to have_http_status(:ok)
    # The help-view-doc div comes from help/_show_embedded.html.erb and confirms
    # the partial was rendered without raising an error.
    expect(response.body).to include('help-view-doc')
  end
end
