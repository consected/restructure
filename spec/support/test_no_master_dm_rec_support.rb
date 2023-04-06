# frozen_string_literal: true

module TestNoMasterDmRecSupport
  def setup_test_no_master_dm_rec_dynamic_model
    dm = DynamicModel.create! current_admin: @admin, name: 'Test No Master Dm Rec', table_name: 'test_no_master_dm_recs', primary_key_name: :id, foreign_key_name: nil, category: :test
    dm.current_admin = @admin
    dm.update_tracker_events

    expect(dm).to be_a ::DynamicModel

    setup_access :dynamic_model__test_no_master_dm_recs, user: @user
    setup_access :dynamic_model__test_no_master_dm_recs, user: @user0
    dm
  end

  def sample_test_no_master_dm_rec_attrs
    {
      alt_id: 500,
      data: '(500)123-7612 500',
      info: 'Info 500'
    }
  end

  def create_test_no_master_dm_rec(att)
    att = att.dup
    att[:current_user] = @user
    DynamicModel::TestNoMasterDmRec.create! att
  rescue StandardError => e
    puts "attr for failure: #{att}"
    raise e
  end
end
