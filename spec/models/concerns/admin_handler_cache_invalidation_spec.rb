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
# - The caches that depended on that clear (admin access control resource names, the
#   general selections info block and the select-from-model options) are refreshed
#   by an explicit scoped invalidation when a definition is saved.
# - Other AdminHandler-including models retain the original behaviour of
#   clearing the cache on every save.
# - Item-type caches are isolated by the shared dynamic-definition token, so a
#   worker with incomplete generated classes cannot poison another worker's list.
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

  describe 'item type caches' do
    def item_type_cache_key(class_name, token)
      "#{class_name}.item_types-#{token}"
    end

    it 'does not serve a DynamicModel item-type list written by a worker with incomplete classes' do
      token = Dynamic::DefinitionCacheVersion.token
      Rails.cache.delete('DynamicModel.item_types')
      Rails.cache.delete(item_type_cache_key('DynamicModel', token))
      incomplete_class = double(attribute_names: ['select_incomplete'], model_name: double(to_s: 'CacheTest'))
      complete_class = double(attribute_names: ['select_complete'], model_name: double(to_s: 'CacheTest'))

      allow(DynamicModel).to receive(:implementation_classes).and_return([incomplete_class])
      expect(DynamicModel.item_types.map(&:to_s)).to include(a_string_matching(/select_incomplete\z/))

      Dynamic::DefinitionCacheVersion.rotate!
      allow(DynamicModel).to receive(:implementation_classes).and_return([complete_class])

      expect(DynamicModel.item_types.map(&:to_s)).to include(a_string_matching(/select_complete\z/))
    end

    it 'does not serve a GeneralSelection item-type list written with stale definition availability' do
      token = Dynamic::DefinitionCacheVersion.token
      Rails.cache.delete('Classification::GeneralSelection.item_types')
      Rails.cache.delete(item_type_cache_key('Classification::GeneralSelection', token))
      allow(Report).to receive(:item_types).and_return([])
      allow(ActivityLog).to receive(:item_types).and_return([])
      allow(DynamicModel).to receive(:item_types).and_return([:select_incomplete], [:select_complete])
      allow(ExternalIdentifier).to receive(:item_types).and_return([])

      expect(Classification::GeneralSelection.item_types).to include(:select_incomplete)

      Dynamic::DefinitionCacheVersion.rotate!

      expect(Classification::GeneralSelection.item_types).to include(:select_complete)
    end

    it 'honors explicit refreshes after both item-type caches include the shared token' do
      token = Dynamic::DefinitionCacheVersion.token
      Rails.cache.delete(item_type_cache_key('DynamicModel', token))
      Rails.cache.delete(item_type_cache_key('Classification::GeneralSelection', token))
      before_class = double(attribute_names: ['select_before_refresh'], model_name: double(to_s: 'CacheTest'))
      after_class = double(attribute_names: ['select_after_refresh'], model_name: double(to_s: 'CacheTest'))
      allow(DynamicModel).to receive(:implementation_classes).and_return([before_class], [after_class])

      expect(DynamicModel.item_types.map(&:to_s)).to include(a_string_matching(/select_before_refresh\z/))
      expect(DynamicModel.item_types(refresh: true).map(&:to_s))
        .to include(a_string_matching(/select_after_refresh\z/))

      allow(Report).to receive(:item_types) { [] }
      allow(ActivityLog).to receive(:item_types) { [] }
      allow(DynamicModel).to receive(:item_types).and_return([:select_before_refresh], [:select_after_refresh])
      allow(ExternalIdentifier).to receive(:item_types) { [] }

      expect(Classification::GeneralSelection.item_types).to include(:select_before_refresh)
      expect(Classification::GeneralSelection.item_types(refresh: true)).to include(:select_after_refresh)
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

    it 'does not clear the Rails cache when an ActivityLog is saved' do
      definition = ActivityLog.active.first!
      definition.current_admin = @admin

      expect(Rails.cache).not_to receive(:clear)
      definition.update!(main_log_name: "#{definition.main_log_name} Updated")
    end

    describe 'caches that previously relied on the whole-cache clear' do
      let(:info_block_key) { Classification::GeneralSelection::InfoBlockCacheKey }

      def definition_saves
        {
          'DynamicModel' => lambda {
            definition = DynamicModel.active.first!
            definition.current_admin = @admin
            definition.update!(position: definition.position.to_i + 1)
          },
          'ExternalIdentifier' => lambda {
            definition = ExternalIdentifier.active.first!
            definition.current_admin = @admin
            definition.update!(label: "#{definition.label} Changed")
          },
          'ActivityLog' => lambda {
            definition = ActivityLog.active.first!
            definition.current_admin = @admin
            definition.update!(main_log_name: "#{definition.main_log_name} Changed")
          }
        }
      end

      it 'refreshes the access control resource names key when any dynamic definition is saved' do
        definition_saves.each do |class_name, save_definition|
          key_before = Admin::UserAccessControl.resource_names_cache_key
          instance_exec(&save_definition)

          expect(Admin::UserAccessControl.resource_names_cache_key).not_to eq(key_before),
                                                                           "#{class_name} save left the key stale"
        end
      end

      it 'does not serve cached resource names for a definition that is no longer current' do
        stale_key = Admin::UserAccessControl.resource_names_cache_key
        Rails.cache.write(stale_key, { stale: ['stale_resource_name'] })

        instance_exec(&definition_saves['DynamicModel'])

        expect(Rails.cache.read(Admin::UserAccessControl.resource_names_cache_key)).to be_nil
      end

      it 'keeps the access control resource names key stable when nothing changed' do
        expect(Admin::UserAccessControl.resource_names_cache_key).to eq(Admin::UserAccessControl.resource_names_cache_key)
      end

      it 'rebuilds both item-type lists after any dynamic definition save without clearing the whole cache' do
        expect(Rails.cache).not_to receive(:clear)

        definition_saves.each do |class_name, save_definition|
          definition_class = class_name.constantize
          token_before = Dynamic::DefinitionCacheVersion.token
          incomplete_class = double(attribute_names: ['select_before_save'], model_name: double(to_s: 'CacheTest'))
          complete_class = double(attribute_names: ['select_after_save'], model_name: double(to_s: 'CacheTest'))
          allow(definition_class).to receive(:implementation_classes) do
            Dynamic::DefinitionCacheVersion.token == token_before ? [incomplete_class] : [complete_class]
          end
          Rails.cache.delete("#{class_name}.item_types-#{token_before}")
          Rails.cache.delete("Classification::GeneralSelection.item_types-#{token_before}")

          expect(definition_class.item_types.map(&:to_s)).to include(a_string_matching(/select_before_save\z/))
          expect(Classification::GeneralSelection.item_types.map(&:to_s))
            .to include(a_string_matching(/select_before_save\z/))

          instance_exec(&save_definition)

          expect(Dynamic::DefinitionCacheVersion.token).not_to eq(token_before)
          expect(definition_class.item_types.map(&:to_s)).to include(a_string_matching(/select_after_save\z/))
          expect(Classification::GeneralSelection.item_types.map(&:to_s))
            .to include(a_string_matching(/select_after_save\z/))
        end
      end

      it 'drops the general selections info block fragment when any dynamic definition is saved' do
        definition_saves.each do |class_name, save_definition|
          Rails.cache.write(info_block_key, '<p>stale</p>')
          instance_exec(&save_definition)

          expect(Rails.cache.read(info_block_key)).to be_nil, "#{class_name} save left the info block stale"
        end
      end

      it 'rotates the select-from-model resource name options when a definition is saved' do
        helpers = Object.new.extend(ReportsHelper).extend(ActionView::Helpers::FormOptionsHelper)
        key_before = "select_from_model_resource_name_options-#{Resources::Models.updated_at}-" \
                     "#{Dynamic::DefinitionCacheVersion.token}"
        Rails.cache.write(key_before, 'stale options')

        instance_exec(&definition_saves['DynamicModel'])

        expect(helpers.send(:select_from_model_resource_name_options)).not_to eq('stale options')
      end
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
