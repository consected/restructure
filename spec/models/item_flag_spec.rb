# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemFlag, type: :model do
  include ModelSupport
  include ItemFlagSupport
  before(:example) do
    # seed_database
    create_user

    create_items
  end
end
