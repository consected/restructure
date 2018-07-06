module UserActionsSetup


    def user_logs_in
    #Given "the user has logged in" do
      login unless user_logged_in?
      dismiss_modal
      all('[data-dismiss]').first&.click
      expect(user_logged_in?).to be true
      logged_in_user = find('a[data-do-action="show-user-options"]')
      expect(logged_in_user[:title]).to eq @good_email
    end


    def create_user_for_login
      @user, @good_password  = create_user
      @good_email  = @user.email
    end

    def user_logout
      logout
    end

    def user_logged_in?
      res = all('.nav a[data-do-action="show-user-options"]')
      return res.length > 0
    end

    def select_app app_name
      select app_name, from: 'use_app_type_select'
    end
end
