require 'rails_helper'
require './app-scripts/supporting/admin_setup'

describe Admin do
  include ModelSupport
  before(:each) do
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    @admin, @good_password = create_admin 'test-admin'
    @good_email = @admin.email
  end

  it 'creates a admin' do
    new_admin = Admin.where email: @good_email
    expect(new_admin.first).to be_a Admin
  end

  it 'allows password change' do
    @admin.password = @good_password + '&&!'
    expect(@admin.save).to be true
  end

  it 'prevents own email address change by admin' do
    @admin.email = 'testadmin-change@testing.com'
    @admin.current_admin = @admin
    expect(@admin.save).to be false
  end

  it 'prevents admin disabled from authenticating' do
    create_admin
    @admin.disable!

    expect(@admin.active_for_authentication?).to be false
  end

  it 'prevent admin changing disabled flag outside of setup, except to disable' do
    ENV['FPHS_ADMIN_SETUP'] = 'no'
    expect(@admin.disabled).to eq false

    # Can change nil or to false or vice versa
    @admin.disabled = nil

    expect(@admin.save).to be true
    @admin.disabled = true
    expect(@admin.save).to be true
    @admin.disabled = false
    expect(@admin.save).to be false
  end

  describe 'allow admin to reset password' do

    context 'when admin is allowed to execute a setup script' do
      it 'allows only admin setup script to reset password' do
        ENV['FPHS_ADMIN_SETUP'] = 'yes'
        res = AdminSetup.setup @good_email

        admin = Admin.find_by_email @good_email
        expect(admin.disable!).to be_truthy #TODO separate expectations into their own block.
        admin.disabled = false
        expect(admin.save).to be_truthy
      end
    end

    context 'when admin is NOT allowed to execute a setup script' do
      # Now simulate re-enabling the user outside of the admin setup script
      res = AdminSetup.setup @good_email

      admin = Admin.find_by_email @good_email
      admin.disable!
      ENV['FPHS_ADMIN_SETUP'] = 'no'
      admin.disabled = false
      res = admin.save

      expect(res).to be_falsy
    end

    context 'when admins are allowed to manage admins' do
      # TODO
    end

    context 'when admins are NOT allowed to manage admins' do
      # TODO
    end
  end

  it 'only allows scripts outside of passenger to create admins' do
    ENV['FPHS_ADMIN_SETUP'] = 'no'

    expect { create_admin }.to raise_error(/can only create admins in console/)
  end

  it 'prevents an admin from reusing a recent password' do
    ENV['FPHS_ADMIN_SETUP'] = 'yes'

    create_admin

    # Generate 7 new passwords - 0 to 6
    expect do
      7.times do |n|
        @admin.password = "#{@good_password} #{n}"
        @admin.save!
      end
    end.not_to raise_error

    @admin.password = "#{@good_password} 3"
    expect(@admin.save).to be false

    @admin.password = "#{@good_password} 1"
    expect(@admin.save).to be false

    @admin.password = "#{@good_password} 0"
    expect(@admin.save).to be true

    @admin.password = @good_password.to_s
    expect(@admin.save).to be true

    @admin.password = "#{@good_password} 1"
    expect(@admin.save).to be true

    @admin.password = "#{@good_password} 1"
    expect(@admin.save).to be false
  end

  after :all do
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
  end
end
