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

  describe '#disabled' do
    subject { @admin }
    context 'when the current admin CAN manage other admins' do
      before do
        stub_const('Settings::AllowAdminsToManageAdmins', true)
        subject.current_admin = create_admin[0] # When an admin is in the web app, the current_admin is set.
      end

      describe 'changing the disabled flag' do
        [false, true]. each do |disable|
          context "when disabled is #{disable}" do
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
          it { is_expected.to be_valid }
          describe "and after invoking save" do
            before { subject.save }
            it { is_expected.to_not have_changes_to_save  }
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
        [false, true]. each do |disable|
          context "when disabled is #{disable}" do
            before { subject.disabled = disable }
            it { is_expected.to be_valid }
            describe "and after invoking save" do
              before { subject.save }
              it { is_expected.to_not have_changes_to_save  }
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

  describe 'current admin creating another admin in the webapp' do
    before { allow_any_instance_of(Admin).to receive(:current_admin).and_return(@admin) }

    context 'when admins are allowed to manage admins' do
      before { stub_const('Settings::AllowAdminsToManageAdmins', true) }
      it 'expects to create an admin' do
        expect { create_admin }.to_not raise_error
        expect(create_admin[0]).to be_a(Admin)
        expect(create_admin[0]).to be_valid
      end
    end

    context 'when admins are NOT allowed to manage admins' do
      before { stub_const('Settings::AllowAdminsToManageAdmins', false) }
      it 'expects not to create an admin' do
        expect { create_admin }.to raise_error(/can only create admins in console/)
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
