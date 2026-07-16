# frozen_string_literal: true

require 'rails_helper'

# Purpose: demonstrate and verify the fix for issue #1270 - User and Admin
# records are saved on almost every request (Devise trackable sign-in
# tracking, lockable failed-attempt counters, app type switching), but
# AdminHandler#invalidate_cache previously called Rails.cache.clear on every
# save regardless of what changed. That wiped the shared template/fragment
# cache (and Application.server_cache_version) on routine sign-ins, causing
# browsers to refetch /pages/<token>/template within the same session even
# though no admin configuration had changed.
#
# These specs verify that:
# - User and Admin only trigger Rails.cache.clear when their `disabled` flag
#   actually changes (via the new #clear_rails_cache_on_save? override).
# - Other AdminHandler-including models retain the original behaviour of
#   clearing the cache on every save.
RSpec.describe AdminHandler, type: :model do
  include ModelSupport

  before :example do
    create_admin
  end

  describe 'User' do
    it 'does not clear the Rails cache when saved without a disabled change' do
      user, = create_user
      expect(Rails.cache).not_to receive(:clear)
      user.update!(first_name: 'Changed')
    end

    it 'does not clear the Rails cache on an app type change' do
      user, = create_user
      other_app_type = Admin::AppType.active.where.not(id: user.app_type_id).first
      skip 'No second active app type available for this test' unless other_app_type

      expect(Rails.cache).not_to receive(:clear)
      user.current_admin = @admin
      user.update!(app_type: other_app_type)
    end

    it 'clears the Rails cache when the disabled flag changes' do
      user, = create_user
      user.current_admin = @admin
      expect(Rails.cache).to receive(:clear).at_least(:once)
      user.update!(disabled: true)
    end
  end

  describe 'Admin' do
    it 'does not clear the Rails cache when saved without a disabled change' do
      admin, = UserSupport.create_admin
      expect(Rails.cache).not_to receive(:clear)
      admin.update!(first_name: 'Changed')
    end

    it 'clears the Rails cache when the disabled flag changes' do
      admin, = UserSupport.create_admin
      expect(Rails.cache).to receive(:clear)
      admin.update!(disabled: true)
    end
  end

  describe 'a standard AdminHandler model' do
    it 'still clears the Rails cache on every save' do
      expect(Rails.cache).to receive(:clear).at_least(:once)
      Classification::GeneralSelection.create! item_type: 'player_contacts_type', name: 'Cache Test',
                                               value: 'cache_test', current_admin: @admin
    end
  end
end
