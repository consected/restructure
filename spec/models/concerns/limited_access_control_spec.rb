# frozen_string_literal: true

# Item flags must never be usable to scope limited access control, since item_flags is a
# generic flagging mechanism, not a per-master resource with its own assigned-user/disabled state.
# This covers the guard in LimitedAccessControl#join_limit_to_assigned that rejects any
# resource_name ending in _item_flags, regardless of the configured access type.
require 'rails_helper'

RSpec.describe LimitedAccessControl, type: :model do
  include ModelSupport

  before(:example) do
    create_user
  end

  it 'raises rather than joining a limited access control scoped to an item_flags association' do
    uac = double('uac', resource_name: 'player_infos_item_flags', access: 'limited') # rubocop:disable RSpec/VerifiedDoubles

    expect do
      Master.join_limit_to_assigned(uac, @user)
    end.to raise_error(FphsException, /Item flags can not be used/)
  end

  it 'raises for limited_if_none access too' do
    uac = double('uac', resource_name: 'dynamic_model__test_created_by_recs_item_flags', access: 'limited_if_none') # rubocop:disable RSpec/VerifiedDoubles

    expect do
      Master.join_limit_to_assigned(uac, @user)
    end.to raise_error(FphsException, /Item flags can not be used/)
  end

  it 'never lists an item_flags resource as valid for the limited_access resource type' do
    expect(Admin::UserAccessControl.resource_names_for(:limited_access).grep(/_item_flags\z/)).to be_empty
  end
end
