require 'rails_helper'

describe "no logging in production" do

  it "should log if the environment variable is set" do
    ENV['FPHS_USE_LOGGER']='TRUE'

    d = DateTime.now
    s = "This is a test of the logger at #{d}"
    Rails.logger.info s
    log = Rails.root.join('log/test.log')
    n = `tail -n 1 #{log}`
    n.gsub!("\n",'')
    expect(n).to match(s)
  end

  it "should not log if the environment variable is not set" do
    ENV['FPHS_USE_LOGGER']=nil

    d = DateTime.now
    s = "This is a test of the logger at #{d}"
    Rails.logger.info s
    log = Rails.root.join('log/test.log')
    n = `tail -n 1 #{log}`
    n.gsub!("\n",'')
    expect(n).not_to match(/#{s}/)
  end

end
