require 'rails_helper'

RSpec.describe "users control", type: :controller do
  before_each_login_user
  
  it "sign in through Devise user" do
    expects(@user.email).to equal @good_email
  end
end

