# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPreference, type: :model do
  include ModelSupport

  before do
    @user, @good_password = create_user
    @good_email = @user.email
    @user_preference = @user.user_preference
    @user_preference.current_user = @user
  end

  subject { @user_preference }

  after do
    # Do nothing
  end

  describe 'associations' do

    it { is_expected.to belong_to(:user).inverse_of(:user_preference).without_validating_presence }

    context 'when current user is present' do
      before { subject.current_user = @user }
      it { is_expected.to be_valid }
    end

    context 'when setting the user to nil' do
      it { expect{ subject.user = nil }.to raise_error(RuntimeError, 'can not set user=') }
    end
  end

  describe 'validations' do

    it { is_expected.to validate_presence_of(:timezone) }
    it { is_expected.to validate_presence_of(:date_format) }
    it { is_expected.to validate_presence_of(:date_time_format) }
    it { is_expected.to validate_presence_of(:time_format) }

    describe 'user cannot be set directly' do
      it { expect{ subject.user = @user }.to raise_error(RuntimeError, 'can not set user=') }
    end

  end
end
