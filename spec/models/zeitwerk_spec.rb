require 'rails_helper'

RSpec.describe 'Zeitwerk compliance' do
  it 'eager loads all files without errors' do
    # Don't bother to run if CI variable is set, since the eager_load will have already been performed

    expect { Rails.application.eager_load! }.not_to raise_error if ENV['CI'].present?
  end
end
