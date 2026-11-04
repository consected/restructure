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
# - DynamicModel, ExternalIdentifier and YAML ConfigLibrary saves avoid the
#   whole-cache clear, while non-YAML libraries and PageLayout retain it.
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
      Admin::MessageTemplate.create! name: 'Cache Test', message_type: :plain, template_type: :content,
                                     template: 'Cache test', current_admin: @admin
    end
  end

  describe 'dynamic definitions and config libraries' do
    it 'does not clear the Rails cache when a DynamicModel is saved' do
      definition = DynamicModel.active.first!
      definition.current_admin = @admin

      expect(Rails.cache).not_to receive(:clear)
      definition.update!(position: definition.position.to_i + 1)
    end

    it 'leaves migration metadata caches alone when a DynamicModel is saved without a migration' do
      definition = DynamicModel.active.first!
      definition.current_admin = @admin
      cache_keys = [
        "db_column_comments-#{Application.version}",
        "db_foreign_keys-#{Application.version}",
        "db_data_dic-#{definition.table_name}-#{Application.version}"
      ]
      cache_keys.each { |key| Rails.cache.write(key, []) }
      previous_allow_migrations = Settings::AllowDynamicMigrations
      change_setting('AllowDynamicMigrations', false)

      definition.update!(position: definition.position.to_i + 1)

      # The column comments may be refreshed (never dropped) when the definition has no _comments yet
      expect(Rails.cache.read(cache_keys.first)).not_to be_nil
      expect(cache_keys.drop(1).map { |key| Rails.cache.read(key) }).to all(eq([]))
    ensure
      change_setting('AllowDynamicMigrations', previous_allow_migrations) unless previous_allow_migrations.nil?
    end

    it 'does not clear the Rails cache when an ExternalIdentifier is saved' do
      definition = ExternalIdentifier.active.first!
      definition.current_admin = @admin

      expect(Rails.cache).not_to receive(:clear)
      definition.update!(label: "#{definition.label} Updated")
    end

    it 'does not clear the Rails cache when a YAML ConfigLibrary is saved' do
      library = Admin::ConfigLibrary.create!(
        current_admin: @admin,
        name: "cache-clear-yaml-#{SecureRandom.hex(4)}",
        category: "cache-clear-#{SecureRandom.hex(4)}",
        format: 'yaml',
        options: "definitions:\n  label: Initial\n"
      )

      expect(Rails.cache).not_to receive(:clear)
      library.update!(options: "definitions:\n  label: Updated\n", current_admin: @admin)
    end

    it 'still clears the Rails cache when a non-YAML ConfigLibrary is saved' do
      library = Admin::ConfigLibrary.create!(
        current_admin: @admin,
        name: "cache-clear-html-#{SecureRandom.hex(4)}",
        category: "cache-clear-#{SecureRandom.hex(4)}",
        format: 'html',
        options: '<p>Initial</p>'
      )

      expect(Rails.cache).to receive(:clear).at_least(:once)
      library.update!(options: '<p>Updated</p>', current_admin: @admin)
    end

    it 'still clears the Rails cache when a PageLayout is saved' do
      layout = Admin::PageLayout.create!(
        current_admin: @admin,
        layout_name: 'master',
        panel_name: "cache-clear-#{SecureRandom.hex(4)}",
        panel_label: 'Cache Clear Test',
        panel_position: 301,
        options: "contains:\n  resources:\n    - player_contacts\n"
      )

      expect(Rails.cache).to receive(:clear).at_least(:once)
      layout.update!(panel_label: 'Updated Cache Clear Test', current_admin: @admin)
    end
  end
end
