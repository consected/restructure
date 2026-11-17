# frozen_string_literal: true

require 'rails_helper'

# Purpose (follow-up to issues #1279 / #1270 / #1287): verify that
# Admin::AppType.all_ids_available_to does not serve stale cached results after the
# access controls it depends on change.
#
# The cache key was previously scoped by user id only ("all_app_type_ids_available_to::<id>").
# In current production behaviour this under-scoping is masked, because saving an
# Admin::UserAccessControl still clears the whole Rails cache (AdminHandler#invalidate_cache).
# However, issue #1270 established the direction of removing whole-cache clears on routine
# saves, so relying on that masking is fragile: if/when those clears are scoped down, a user
# granted access to a new app type would never see it (and a revoked app type would remain
# listed) until a server restart.
#
# These specs disable the whole-cache clear (simulating the future state) and verify the
# cache key itself correctly reflects access control changes.
RSpec.describe Admin::AppType, type: :model do
  include ModelSupport

  describe '.all_ids_available_to cache scoping' do
    before :example do
      create_admin
      create_user
      @app_type_a = @user.app_type
      expect(@app_type_a).not_to be nil

      @app_type_b = create_app_type(name: "aia-cache-#{SecureRandom.hex(4)}", label: 'AIA Cache Test')
    end

    it 'reflects a newly granted app type without relying on whole-cache clears' do
      # Prime the cache: only app type A available
      ids_before = Admin::AppType.all_ids_available_to(@user)
      expect(ids_before).to include(@app_type_a.id)
      expect(ids_before).not_to include(@app_type_b.id)

      # Simulate the future state where routine access control saves no longer clear
      # the whole Rails cache, so only correct cache key scoping keeps results fresh
      allow_any_instance_of(Admin::UserAccessControl).to receive(:clear_rails_cache_on_save?).and_return(false)

      # Grant access to app type B directly (the enable_user_app_access helper creates
      # a new admin via auto_admin, whose save clears the whole cache and would defeat
      # this simulation). The explicit updated_at avoids same-second latest_update
      # timestamp collisions, which interpolate at second granularity in cache keys.
      Admin::UserAccessControl.create! app_type: @app_type_b, resource_type: :general,
                                       resource_name: :app_type, access: :read,
                                       user: @user, current_admin: @admin,
                                       created_at: 2.seconds.from_now, updated_at: 2.seconds.from_now

      ids_after = Admin::AppType.all_ids_available_to(User.find(@user.id))
      expect(ids_after).to include(@app_type_b.id),
                           'all_ids_available_to returned stale results after an app type access grant'
    end
  end
end
