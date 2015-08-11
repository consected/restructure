require 'rails_helper'

describe User do
  include ModelSupport
  before(:each) do
    @user, @good_password  = create_user
    @good_email  = @user.email
    
  end

  it "creates a user" do
    new_user = User.where email: @good_email
    expect(new_user.first).to be_a User
  end
  
  it "allows password change" do
    @user.password = @good_password + '&&!'
    expect(@user.save).to be true
  end
  
  it "prevents email address change by a user" do
    # Get the user as if it is a standard user operation
    # The @user is the instance that was created by the admin 
    # and therefore still acts like it has admin privileges
    new_user = User.where(email: @good_email).first
    expect(new_user.admin_set?).to be false
    
    new_user.email  = "testuser-change@testing.com"
    expect(new_user.save).to be false
  end
  
  it "allows email address change by an admin" do
    create_admin
    @user.email  = "testuser-change@testing.com"
    @user.current_admin = @admin
    expect(@user.save).to be true
  end
  
  
  it "prevents user disabled from authenticating" do
    create_admin
    @user.disabled = true
    @user.current_admin = @admin
    @user.save!
    
    expect(@user.active_for_authentication?).to be false
  end
  
  it "prevents user changing disabled flag" do
    
    #Get the user as if it is a standard user operation
    new_user = User.where(email: @good_email).first
    expect(new_user.admin_set?).to be false
    
    new_user.disabled = false    
    expect(new_user.save).to be false
  end
  
  
end

