# frozen_string_literal: true

module UserActionsSetup
  def user_logs_in
    # Given "the user has logged in" do
    login unless user_logged_in?
    dismiss_modal
    all('[data-dismiss]', wait: false).first&.click
    expect(user_logged_in?).to be true
    logged_in_user = find('a[data-do-action="show-user-options"]')
    expect(logged_in_user[:title]).to eq @good_email
  end

  def create_user_for_login
    @user, @good_password = create_user
    @good_email = @user.email
  end

  def ensure_user_matches_login_email
    nil unless @user.email != @good_email
  end

  def user_logout
    logout
  end

  def user_logged_in?
    # Visit home page first to ensure page is loaded and check session validity
    # This is important because Warden.test_reset! may have cleared server session
    if current_url == 'about:blank' || current_url.nil? || current_url.empty?
      visit '/'
      begin
        finish_page_loading
      rescue StandardError
        nil
      end
    end
    res = all('.nav a[data-do-action="show-user-options"]', wait: 1)
    !res.empty?
  end

  def select_app(app_name)
    select app_name, from: 'use_app_type_select' if has_css?('#use_app_type_select')
  end
end
