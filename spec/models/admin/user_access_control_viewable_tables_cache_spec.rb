# frozen_string_literal: true

require 'rails_helper'

# Purpose (follow-up to issues #1279 / #1270): demonstrate and verify the fix for
# Admin::UserAccessControl.viewable_tables returning stale results after a user
# switches app type within a single session.
#
# The Rails.cache key for .viewable_tables was built from the user id, the
# current_sign_in_at timestamp and the alt_app_type_id argument only. When
# alt_app_type_id is nil (the normal case for the master record UI), the key did
# NOT include the user's current app_type_id, even though the computed result
# depends on it (access_for_list? falls back to user.app_type_id).
#
# Consequently, when a user switched app type within a session (current_sign_in_at
# unchanged, no access control rows modified), the cached viewable tables of the
# PREVIOUS app type were returned for the new app type. Downstream this fed
# master_viewables and the master panel tab filtering
# (app/views/masters/_search_results_master_tabs.html.erb), producing missing tabs
# and incomplete compiled Handlebars templates.
#
# Before PR #1271 (issue #1270) this was hidden, because every User save (including
# the app type switch itself and Devise trackable sign-in updates) cleared the whole
# Rails cache. Once those whole-cache clears were removed, the under-scoped cache key
# was exposed.
#
# These specs verify that:
# - viewable_tables reflects the user's current app type after an app type switch,
#   even when the result for the previous app type was already cached
# - results for an explicit alt_app_type_id remain correct and independent
RSpec.describe Admin::UserAccessControl, type: :model do
  include ModelSupport

  describe '.viewable_tables cache scoping across app type switches' do
    before :example do
      create_admin
      create_user

      @app_type_a = @user.app_type
      expect(@app_type_a).not_to be nil

      @app_type_b = create_app_type(name: "vt-cache-#{SecureRandom.hex(4)}", label: 'VT Cache Test')
      enable_user_app_access @app_type_b, @user

      # App type A: user can view player_infos (the user is currently on app type A, so
      # setup_access can also validate the access control works)
      setup_access :player_infos, resource_type: :table, access: :read, user: @user, app_type: @app_type_a

      # App type B: user can view addresses but NOT player_infos.
      # Created directly since setup_access validates has_access_to? against the user's
      # *current* app type, which is still A at this point.
      Admin::UserAccessControl.create! app_type: @app_type_b, resource_type: :table, resource_name: 'addresses',
                                       access: :read, user: @user, current_admin: @admin

      @user = User.find(@user.id)
    end

    it 'returns the viewable tables for the new app type after a user switches app type in-session' do
      # Prime the cache while the user is on app type A
      res_a = Admin::UserAccessControl.viewable_tables(@user)
      expect(res_a[:player_infos]).to be_truthy

      # Switch app type within the same session: no sign-in change, no access control change,
      # so previously the cache key remained identical and returned app type A's results
      @user.current_admin = @admin
      @user.app_type = @app_type_b
      @user.save!
      user = User.find(@user.id)
      expect(user.app_type_id).to eq @app_type_b.id

      # App type B has no player_infos access control, so it must not be viewable.
      # With the under-scoped cache key, app type A's cached results were returned instead.
      res_b = Admin::UserAccessControl.viewable_tables(user)
      expect(res_b[:player_infos]).to be_falsey,
                                      'viewable_tables returned stale results for the previous app type ' \
                                      'after an in-session app type switch'
      expect(res_b[:addresses]).to be_truthy

      # And switching back must return app type A's results again
      user.current_admin = @admin
      user.app_type = @app_type_a
      user.save!
      user = User.find(user.id)

      res_a2 = Admin::UserAccessControl.viewable_tables(user)
      expect(res_a2[:player_infos]).to be_truthy
    end

    it 'keeps alt_app_type_id results independent of the current app type cache entries' do
      # Prime the cache for the current app type (A)
      res_a = Admin::UserAccessControl.viewable_tables(@user)
      expect(res_a[:player_infos]).to be_truthy

      res_alt_b = Admin::UserAccessControl.viewable_tables(@user, alt_app_type_id: @app_type_b.id)
      expect(res_alt_b[:addresses]).to be_truthy
      expect(res_alt_b[:player_infos]).to be_falsey

      # The current app type result must not have been affected
      res_a2 = Admin::UserAccessControl.viewable_tables(@user)
      expect(res_a2[:player_infos]).to be_truthy
    end
  end
end
