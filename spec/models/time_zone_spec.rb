require 'rails_helper'

describe TimeZone, type: :model do

  describe 'validations' do
    it { is_expected.to validate_presence_of(:abbreviation) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:utc_offset) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:user_preference) }
  end

end
