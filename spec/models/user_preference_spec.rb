require 'rails_helper'

describe UserPreference, type: :model do
  before do
    @user, @good_password = create_user
    @good_email = @user.email
  end

  after do
    # Do nothing
  end

  context 'when user is present' do
    before { subject.user = @user }
    it { is_expected.to be_valid }
  end

  context 'when user is not present' do
    before { subject.user = nil }
    it { is_expected.to_not be_valid }
  end
end
