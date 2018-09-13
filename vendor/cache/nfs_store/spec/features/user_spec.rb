require 'rails_helper'

describe "user sign in process", js: true, driver: :app_firefox_driver do

  include ModelSupport

  before(:all) do

    create_user
    create_user_role "#{NfsStore::Manage::Group::RoleNamePrefix} 600"

  end

  it "should sign in" do

    user = User.where(email: @good_email).first
    expect(user).to be_a User
    expect(user.id).to equal @user.id

    #login_as @user, scope: :user

    visit "/users/sign_in"
    within '#new_user' do
      fill_in "Email", with: @good_email
      fill_in "Password", with: @good_password
      click_button "Log in"
    end

    expect(page).to have_css ".flash .alert", text: "× Signed in successfully"

  end
end
