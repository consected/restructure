# frozen_string_literal: true

require 'rails_helper'

# Tests for the AdminHandler concern (mixed into Admin::AppType, Admin::UserAccessControl,
# Admin::UserRole, Classification::GeneralSelection, and other admin-configured resources).
# Covers `already_taken` uniqueness checks and `latest_update` memoization, including the
# issue #1302 regression coverage below (config.active_support.to_time_preserves_timezone).
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
  # `latest_update` calls `updated_at.to_time` (or `created_at.to_time` as a fallback), whose
  # result is used both in cache-key string interpolation
  # (Admin::UserAccessControl.cache_key_for_access_for / .access_control_version_token, which
  # depend on second-granularity formatting - see issue #1287) and in memoized equality
  # comparisons that gate memo invalidation (UserAccessHandler#user_access_controls_updated?
  # and #user_roles_updated? do `@latest_user_access_control != Admin::UserAccessControl.latest_update`).
  # Both usages must keep working whether `to_time` returns a plain Time (:offset) or an
  # ActiveSupport::TimeWithZone (:zone).
  it 'returns a latest_update value usable as a stable cache-key component and in equality comparisons' do
    Admin::AppType.reset_latest_update
    lu = Admin::AppType.latest_update(force: true)

    expect(lu).not_to be_nil
    # Locks the second-granularity string format that cache_key_for_access_for and
    # access_control_version_token depend on (issue #1287), regardless of :offset vs :zone.
    expect(lu.to_s).to match(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)

    # The value must remain equal to itself across repeated (unforced) memo reads, and
    # correctly detect a genuine change - mirroring the != comparisons UserAccessHandler
    # performs against a previously memoized value.
    expect(Admin::AppType.latest_update).to eq(lu)

    Admin::AppType.create!(name: "tz-audit-#{SecureRandom.hex(4)}", label: 'TZ Audit', current_admin: @admin)
    new_lu = Admin::AppType.latest_update(force: true)
    expect(new_lu).not_to eq(lu)
  end
end

