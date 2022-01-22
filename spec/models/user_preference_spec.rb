# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPreference, type: :model do
  before do
    @user, @good_password = create_user
    @good_email = @user.email
  end

  after do
    # Do nothing
  end

  describe 'associations' do

    it { is_expected.to belong_to(:user) }

    it { is_expected.to have_one(:user) }
    context 'when user is present' do
      before { subject.user = @user }
      it { is_expected.to be_valid }
    end

    context 'when user is not present' do
      before { subject.user = nil }
      it { is_expected.to_not be_valid }
    end
  end

  describe 'validations' do

    it { is_expected.to validate_presense_of(:user) }
    it { is_expected.to validate_presense_of(:date_format) }
    it { is_expected.to validate_presense_of(:pattern_for_date_format) }
    it { is_expected.to validate_presense_of(:pattern_for_date_time_format) }
    it { is_expected.to validate_presense_of(:pattern_for_time_format) }

  end
end
