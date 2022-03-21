require 'rails_helper'
require './app-scripts/supporting/admin_setup'

describe Admin do
  include ModelSupport
  before do
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    @admin, @good_password = create_admin 'test-admin'
    @good_email = @admin.email
  end

  it 'creates a admin' do
    new_admin = Admin.find_by email: @good_email
    expect(new_admin).to be_a Admin
  end

  it 'allows password change' do
    @admin.password = @good_password + '&&!'
    expect(@admin.save).to be_truthy
  end

  it 'prevents own email address change by admin' do
    @admin.email = 'testadmin-change@testing.com'
    @admin.current_admin = @admin
    expect(@admin.save).to be_falsy
  end

  it 'prevents admin disabled from authenticating' do
    create_admin
    @admin.current_admin = @admin
    @admin.disable!

    expect(@admin.active_for_authentication?).to be_falsy
  end

  it 'only allows scripts outside of passenger to create admins' do
    ENV['FPHS_ADMIN_SETUP'] = 'no'

    expect { create_admin }.to raise_error(/can only create admins in console/)
  end

  it 'allows only admin setup script to reset password' do
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    res = AdminSetup.setup @good_email

    admin = Admin.find_by_email @good_email
    expect(admin.disable!).to be true
    admin.disabled = false
    expect(admin.save).to be true
    admin.disable!

    # Now simulate re-enabling the user outside of the admin setup script
    ENV['FPHS_ADMIN_SETUP'] = 'no'
    admin.disabled = false
    res = admin.save

    expect(res).to be false
  end

  it 'prevents admin disabled from authenticating' do
    create_admin
    @admin.disable!

    expect(@admin.active_for_authentication?).to be false
  end

  describe 'prevent admin changing disabled flag outside of setup (with the add_admin script in the console), except to disable' do
    subject { @admin }
    %w(yes no).each do |admin_setup|
      context "when fphs_admin_setup is #{admin_setup}" do
        before { ENV['FPHS_ADMIN_SETUP'] = admin_setup }
        context 'when admin is not disabled' do
          [nil, false].each do |disable|
            context "such that disabled is #{ disable.nil? ? 'nil': disable }" do
              before { subject.disabled = disable }
              it { is_expected.to be_valid }
              describe "and after invoking save" do
                before { subject.save }
                it { is_expected.to_not have_changes_to_save }
              end
              describe "#disabled!" do
                it { expect(subject.disable!).to be_truthy }
              end
            end
          end
        end
        context 'when admin is disabled' do
          before { subject.disabled = true }
          it { is_expected.to be_valid }
          describe "and after invoking save" do
            before { subject.save }
            it { is_expected.to_not have_changes_to_save }
          end
        end
      end
    end
    context 'when fphs_admin_setup is yes, and admin is re-enabling another admin' do
      before do
        ENV['FPHS_ADMIN_SETUP'] = 'yes'
        subject.disable!
        subject.disabled = false
      end
      it { is_expected.to be_valid }
      describe "and after invoking save" do
        before { subject.save }
        it { is_expected.to_not have_changes_to_save }
      end
    end

    context 'when fphs_admin_setup is no, and admin is re-enabling another admin' do
      before do
        ENV['FPHS_ADMIN_SETUP'] = 'no'
        subject.disable!
        subject.disabled = false
      end
      it { is_expected.to_not be_valid }
      describe "and after invoking save" do
        before { subject.save }
        it { is_expected.to have_changes_to_save }
      end
    end
  end

  describe '#disabled' do
    subject { @admin }
    context 'when the current admin CAN manage other admins' do
      before do
        stub_const('Settings::AllowAdminsToManageAdmins', true)
        subject.current_admin = create_admin[0] # When an admin is in the web app, the current_admin is set.
      end

      describe 'changing the disabled flag' do
        [nil, false, true].each do |disable|
          context "when disabled is #{ disable.nil? ? 'nil': disable }" do
            before { subject.disabled = disable }
            it { is_expected.to be_valid }
            describe "and after invoking save" do
              before { subject.save }
              it { is_expected.to_not have_changes_to_save }
            end
          end
        end
        context 'when re-enabling an admin' do
          before do
            subject.disable!
            subject.disabled = false
          end
          it { is_expected.to be_valid }
          describe "and after invoking save" do
            before { subject.save }
            it { is_expected.to_not have_changes_to_save }
          end
        end
      end
    end

    context 'when the  current admin CANNOT manage other admins' do
      before do
        stub_const('Settings::AllowAdminsToManageAdmins', false)
        subject.current_admin = create_admin[0] # When an admin is in the web app, the current_admin is set.
      end

      describe 'changing the disabled flag' do
        [nil, false, true].each do |disable|
          context "when disabled is #{ disable.nil? ? 'nil': disable }" do
            before { subject.disabled = disable }
            it { is_expected.to be_valid }
            describe "and after invoking save" do
              before { subject.save }
              it { is_expected.to_not have_changes_to_save }
            end
          end
        end
        context 'when re-enabling an admin' do
          before do
            subject.disabled = true
            subject.save
            subject.disabled = false
          end
          it { is_expected.to_not be_valid }
          describe "and after invoking save" do
            before { subject.save }
            it { is_expected.to have_changes_to_save }
          end
        end
      end
    end
  end

  describe 'creating other admins' do
    describe 'current admin creating another admin in the webapp' do
      before { allow_any_instance_of(Admin).to receive(:current_admin).and_return(@admin) }

      context 'when the current admin CAN manage other admins' do
        before { stub_const('Settings::AllowAdminsToManageAdmins', true) }
        it 'is expected to another an admin' do
          expect { create_admin }.to_not raise_error
          expect(create_admin[0]).to be_a(Admin)
          expect(create_admin[0]).to be_valid
        end
      end

      context 'when the  current admin CANNOT manage other admins' do
        before { stub_const('Settings::AllowAdminsToManageAdmins', false) }
        it 'is expected not to create another admin' do
          expect { create_admin }.to raise_error(/can only create admins in console/)
        end
      end
    end

    describe 'OS-user creates another admin with add_admin script in the console' do
      before { stub_const('Settings::AllowAdminsToManageAdmins', false) }
      context 'when the current admin CAN manage other admins' do
        before { ENV['FPHS_ADMIN_SETUP'] = 'yes' }
        it 'is expected to create another an admin' do
          expect { create_admin }.to_not raise_error
          expect(create_admin[0]).to be_a(Admin)
          expect(create_admin[0]).to be_valid
        end
      end
      context 'when the current admin CANNOT manage other admins' do
        before { ENV['FPHS_ADMIN_SETUP'] = 'no' }
        it 'is expected not to create another admin' do
          expect { create_admin }.to raise_error(/can only create admins in console/)
        end
      end
    end
  end

  describe 'password reset' do

    it 'prevents an admin from reusing a recent password' do

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
  end

  after :all do
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
  end
end
