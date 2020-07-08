# frozen_string_literal: true

require 'rails_helper'

describe User do
  include ModelSupport
  before(:each) do
    @user, @good_password = create_user
    @good_email = @user.email
  end

  it 'creates a user' do
    new_user = User.where email: @good_email
    expect(new_user.first).to be_a User
  end

  it 'allows password change' do
    @user.password = @good_password + '&&!'
    expect(@user.save).to be true
  end

  it 'prevents email address change by a user' do
    # Get the user as if it is a standard user operation
    # The @user is the instance that was created by the admin
    # and therefore still acts like it has admin privileges
    new_user = User.where(email: @good_email).first
    expect(new_user.admin_set?).to be false

    new_user.email = 'testuser-change@testing.com'
    expect(new_user.save).to be false
  end

  it 'allows email address change by an admin' do
    create_admin
    @user.email = 'testuser-change@testing.com'
    @user.current_admin = @admin
    expect(@user.save).to be true
  end

  it 'prevents user disabled from authenticating' do
    create_admin
    @user.disabled = true
    @user.current_admin = @admin
    @user.save!

    expect(@user.active_for_authentication?).to be false
  end

  it 'prevents user changing disabled flag' do
    # Setup the user to be disabled
    @user.disabled = true
    @user.current_admin = @admin
    @user.save!

    # Get the user as if it is a standard user operation
    new_user = User.where(email: @good_email).first
    expect(new_user.admin_set?).to be false
    expect(new_user.disabled).to be true

    new_user.disabled = false
    expect(new_user.save).to be false
  end

  it 'requires admin to create a user' do
    e = "atest-#{@good_email}"

    expect { User.create! email: e }.to raise_error(
      ActiveRecord::RecordInvalid,
      'Validation failed: Admin account must be used to create user, Admin must exist'
    )
  end

  it 'prevents a user from reusing a recent password' do
    create_admin

    # Generate 7 new passwords - 0 to 6
    expect do
      7.times do |n|
        @user.password = "#{@good_password} #{n}"
        @user.save!
      end
    end.not_to raise_error

    @user.password = "#{@good_password} 3"
    expect(@user.save).to be false

    @user.password = "#{@good_password} 1"
    expect(@user.save).to be false

    @user.password = "#{@good_password} 0"
    expect(@user.save).to be true

    @user.password = @good_password.to_s
    expect(@user.save).to be true

    @user.password = "#{@good_password} 1"
    expect(@user.save).to be true

    @user.password = "#{@good_password} 1"
    expect(@user.save).to be false
  end

  it 'expires a password if it is too old' do
    create_admin

    expect(Settings::PasswordAgeLimit).to eq 90

    expect(@user.need_change_password?).to be false

    @user.password_updated_at = DateTime.now - 89.days
    @user.current_admin = @admin
    @user.save

    expect(@user.need_change_password?).to be false

    @user.password_updated_at = DateTime.now - 91.days
    @user.save

    expect(@user.need_change_password?).to be true
  end

  it 'sets a password expiration reminder if the password is reset or changed' do
    Messaging::MessageNotification.delete_all
    expect(Messaging::MessageNotification.layout_template(Users::Reminders.password_expiration_defaults[:layout])).to be_a Admin::MessageTemplate

    create_admin

    @user = User.new email: @user.email + 'dj', current_admin: @admin, first_name: 'fn', last_name: 'ln'

    @user.otp_required_for_login = false

    # Can't just stub the password_updated_at method to test, since the object is reloaded in the delayed_job job
    # So we create an alias, change the method, then use the alias to put the original method back afterwards.
    @user.class.send :alias_method, :orig_password_updated_at, :password_updated_at

    @user.class.send(:define_method, :password_updated_at) do
      Time.now - 87.days
    end
    @user.save!

    expect(Settings::PasswordAgeLimit).to eq 90

    expect(Messaging::MessageNotification.count).to eq 1
    expect(Messaging::MessageNotification.first.user).to eq @user
    expect(Messaging::MessageNotification.first.layout_template_name).to eq Users::Reminders.password_expiration_defaults[:layout]

    @user.password = 'some new password that needs notification'
    @user.save!

    expect(Messaging::MessageNotification.count).to eq 2
    expect(Messaging::MessageNotification.last.user).to eq @user
    expect(Messaging::MessageNotification.last.layout_template_name).to eq Users::Reminders.password_expiration_defaults[:layout]

    @user.password = 'some new password that needs notification 2'

    @user.class.send :alias_method, :password_updated_at, :orig_password_updated_at

    @user.save!
    expect(Messaging::MessageNotification.count).to eq 2
  end

  after :all do
    if User.new.respond_to? :orig_password_updated_at
      User.send :alias_method, :password_updated_at, :orig_password_updated_at
    end
  end
end
