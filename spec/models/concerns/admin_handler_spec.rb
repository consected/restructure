# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminHandler, type: :model do
  include ModelSupport

  before :example do
    create_admin
  end

  it 'Checks if an admin item is already present' do
    a = Admin::AppType.new(name: 'zeus', label: 'Zeus')
    expect(a.already_taken(:name)).to be true
    expect(a.already_taken(:name, :label)).to be true

    a = Admin::AppType.new(name: 'zeus', label: 'Not Taken')
    expect(a.already_taken(:name)).to be true
    expect(a.already_taken(:name, :label)).to be false

    a = Admin::AppType.new(name: 'not taken', label: 'Not Taken')
    expect(a.already_taken(:name)).to be false
    expect(a.already_taken(:name, :label)).to be false
  end

  it 'checks if a general selection item is already present' do
    g = Classification::GeneralSelection.new item_type: 'player_contacts_type', name: 'Email', value: 'email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be true

    g = Classification::GeneralSelection.new item_type: 'player_contacts_type', name: 'Not Email', value: 'not email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be false

    g.save!
    expect(g.already_taken(:item_type, :value)).to be false
  end

  # Regression coverage for issue #1302 (config.active_support.to_time_preserves_timezone).
  # `latest_update` calls `updated_at.to_time`, whose result is used both in string
  # interpolation (cache keys, e.g. Admin::UserAccessControl.cache_key_for_access_for) and
  # in arithmetic (e.g. Dynamic::DefHandler#up_to_date? does `(lu - @prev_latest_update).abs`).
  # Both usages must keep working whether `to_time` returns a plain Time (:offset) or an
  # ActiveSupport::TimeWithZone (:zone).
  it 'returns a latest_update value usable in string interpolation and arithmetic' do
    Admin::AppType.reset_latest_update
    lu = Admin::AppType.latest_update(force: true)

    expect(lu).not_to be_nil
    expect { "key-#{lu}" }.not_to raise_error
    expect((lu - (lu - 5.seconds)).abs).to be_within(0.01).of(5)
  end
end

