# frozen_string_literal: true

require 'rails_helper'

# Tests for the DynamicModel and ExternalIdentifier admin panel enhancements:
# - UAC summary display in details panel
# - in_current_app_type filtering
# - in_app_type? instance method
# - ids_in_app_type class method
RSpec.describe 'Dynamic Definition Admin UAC Features', type: :model do
  include ModelSupport
  include DynamicModelSupport

  describe 'DynamicModel.ids_in_app_type' do
    before :all do
      create_admin
      create_user
      @app_type = create_app_type(name: "uac_test_app_#{rand(100_000)}", label: 'UAC Test App')

      # Find or create a dynamic model for testing
      @dm = DynamicModel.active.where(table_name: 'test_created_by_recs').first
      unless @dm
        disabled_dm = DynamicModel.where(table_name: 'test_created_by_recs', disabled: true).first
        if disabled_dm
          disabled_dm.current_admin = @admin
          disabled_dm.update!(disabled: false)
          @dm = disabled_dm
        else
          generate_test_dynamic_model
          @dm = DynamicModel.active.where(table_name: 'test_created_by_recs').first
        end
      end
      raise 'Test dynamic model not created' unless @dm

      # Add UAC for the dynamic model to associate it with the app type
      Admin::UserAccessControl.create!(
        app_type: @app_type,
        resource_type: :table,
        resource_name: @dm.resource_name.pluralize,
        access: :read,
        current_admin: @admin
      )
    end

    after :all do
      @app_type&.update!(disabled: true, current_admin: @admin)
    end

    it 'returns IDs of dynamic models associated with an app type' do
      ids = DynamicModel.ids_in_app_type(@app_type)
      expect(ids).to include(@dm.id)
    end

    it 'returns empty array for app type with no dynamic models' do
      empty_app_type = create_app_type(name: "empty_app_#{rand(100_000)}", label: 'Empty App')
      ids = DynamicModel.ids_in_app_type(empty_app_type)
      expect(ids).to be_empty
      empty_app_type.update!(disabled: true, current_admin: @admin)
    end

    it 'accepts app type ID as integer' do
      ids = DynamicModel.ids_in_app_type(@app_type.id)
      expect(ids).to include(@dm.id)
    end
  end

  describe 'DynamicModel#in_app_type?' do
    before :all do
      create_admin
      create_user
      @app_type = create_app_type(name: "in_app_test_#{rand(100_000)}", label: 'In App Test')

      # Reuse existing dynamic model or re-enable a disabled one
      @dm = DynamicModel.active.where(table_name: 'test_created_by_recs').first
      unless @dm
        disabled_dm = DynamicModel.where(table_name: 'test_created_by_recs', disabled: true).first
        if disabled_dm
          disabled_dm.current_admin = @admin
          disabled_dm.update!(disabled: false)
          @dm = disabled_dm
        else
          generate_test_dynamic_model
          @dm = DynamicModel.active.where(table_name: 'test_created_by_recs').first
        end
      end
      raise 'Test dynamic model not found' unless @dm

      # Add UAC for the dynamic model
      Admin::UserAccessControl.create!(
        app_type: @app_type,
        resource_type: :table,
        resource_name: @dm.resource_name.pluralize,
        access: :read,
        current_admin: @admin
      )
    end

    after :all do
      @app_type&.update!(disabled: true, current_admin: @admin)
    end

    it 'returns true when dynamic model is in the app type' do
      expect(@dm.in_app_type?(@app_type)).to be true
    end

    it 'returns false when dynamic model is not in the app type' do
      other_app_type = create_app_type(name: "other_app_#{rand(100_000)}", label: 'Other App')
      expect(@dm.in_app_type?(other_app_type)).to be false
      other_app_type.update!(disabled: true, current_admin: @admin)
    end
  end

  describe 'ExternalIdentifier.ids_in_app_type' do
    before :all do
      create_admin

      @app_type = create_app_type(name: "ext_id_test_#{rand(100_000)}", label: 'Ext ID Test')

      # Find an existing external identifier to test with
      @ext_id = ExternalIdentifier.active.first
      next unless @ext_id

      # Add UAC for the external identifier to associate it with the app type
      Admin::UserAccessControl.create!(
        app_type: @app_type,
        resource_type: :table,
        resource_name: @ext_id.name,
        access: :read,
        current_admin: @admin
      )
    end

    after :all do
      @app_type&.update!(disabled: true, current_admin: @admin)
    end

    it 'returns IDs of external identifiers associated with an app type', if: -> { ExternalIdentifier.active.any? } do
      next unless @ext_id

      ids = ExternalIdentifier.ids_in_app_type(@app_type)
      expect(ids).to include(@ext_id.id)
    end

    it 'returns empty array for app type with no external identifiers' do
      empty_app_type = create_app_type(name: "empty_ext_#{rand(100_000)}", label: 'Empty Ext')
      ids = ExternalIdentifier.ids_in_app_type(empty_app_type)
      expect(ids).to be_empty
      empty_app_type.update!(disabled: true, current_admin: @admin)
    end
  end

  describe 'ExternalIdentifier#in_app_type?' do
    before :all do
      create_admin

      @app_type = create_app_type(name: "ext_in_app_#{rand(100_000)}", label: 'Ext In App')

      @ext_id = ExternalIdentifier.active.first
      next unless @ext_id

      Admin::UserAccessControl.create!(
        app_type: @app_type,
        resource_type: :table,
        resource_name: @ext_id.name,
        access: :read,
        current_admin: @admin
      )
    end

    after :all do
      @app_type&.update!(disabled: true, current_admin: @admin)
    end

    it 'returns true when external identifier is in the app type', if: -> { ExternalIdentifier.active.any? } do
      next unless @ext_id

      expect(@ext_id.in_app_type?(@app_type)).to be true
    end

    it 'returns false when external identifier is not in the app type', if: -> { ExternalIdentifier.active.any? } do
      next unless @ext_id

      other_app_type = create_app_type(name: "other_ext_#{rand(100_000)}", label: 'Other Ext')
      expect(@ext_id.in_app_type?(other_app_type)).to be false
      other_app_type.update!(disabled: true, current_admin: @admin)
    end
  end
end
