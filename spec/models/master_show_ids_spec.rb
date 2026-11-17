# frozen_string_literal: true

# Covers access filtering for IDs configured in master search results.
require 'rails_helper'

RSpec.describe Master, type: :model do
  include ModelSupport
  include MasterSupport

  before(:example) do
    create_user
    ExternalIdentifier.where(name: %w[scantrons sage_assignments]).update_all(disabled: false)
    Master.reset_external_id_matching_fields!
    @scantron_access = setup_access :scantrons
    @sage_access = setup_access :sage_assignments
    @master = create_master(@user, msid: 987_654_321)
    @scantron = @master.scantrons.create!(scantron_id: rand(100_000..900_000))
    @sage_id = rand(1_000_000_000..9_000_000_000).to_s
    SageAssignment.insert!({ master_id: @master.id,
                             sage_id: @sage_id,
                             user_id: @user.id,
                             created_at: Time.current,
                             updated_at: Time.current })
    @master.current_user = @user
  end

  def configure_result_ids(ids)
    add_app_config(@user.app_type, 'show ids in master result', ids)
    Admin::AppConfiguration.clear_memo!
    Master.reset_external_id_matching_fields!
  end

  it 'omits inaccessible external IDs from the configured list and JSON' do
    configure_result_ids('scantron_id,sage_id')
    @sage_access.update!(access: nil)
    Master.reset_external_id_matching_fields!

    expect(@user.has_access_to?(:access, :table, 'sage_assignments')).to be_falsey
    expect(@master.show_ids_in_results).to include(:scantron_id)
    expect(@master.show_ids_in_results).not_to include(:sage_id)

    result = @master.as_json(current_user: @user, filtered_search_results: true)

    expect(result['scantron_id']).to eq(@scantron.scantron_id)
    expect(result).not_to have_key('sage_id')
  end

  it 'returns an external ID value when the user has access' do
    configure_result_ids('scantron_id,sage_id')

    expect(@master.sage_id).to eq(@sage_id)
    result = @master.as_json(current_user: @user, filtered_search_results: true)
    expect(result['sage_id']).to eq(@sage_id)
  end

  it 'still raises when the generated ID method is called without access' do
    @sage_access.update!(access: nil)
    Master.reset_external_id_matching_fields!

    expect { @master.sage_id }.to raise_error(FphsException)
  end
end
