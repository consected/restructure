require 'rails_helper'

describe Admin do
  include ModelSupport
  before(:each) do
    @good_email = 'testadmin-model@testing.com'
    @good_password = Devise.friendly_token.first(12)
    @admin = Admin.create email: @good_email, password: @good_password  
  end

  it "creates a admin" do
    new_admin = Admin.where email: @good_email
    expect(new_admin.first).to be_a Admin
  end
  
  it "allows password change" do
    @admin.password = @good_password + '&&!'
    expect(@admin.save).to be true
  end
  
  it "prevents email address change by a admin" do
    @admin.email  = "testadmin-change@testing.com"
    expect(@admin.save).to be false
  end
  
  
  
  it "prevents admin disabled from authenticating" do
    create_admin
    @admin.disabled = true
    
    @admin.save!
    
    expect(@admin.active_for_authentication?).to be false
  end
  
  it "prevents admin changing disabled flag" do
    @admin.disabled = false        
    expect(@admin.save).to be false
  end
  
  
end

