# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemFlag, type: :model do
  include ModelSupport
  include DynamicModelSupport
  include ItemFlagSupport

  before(:example) do
    # seed_database
    create_user

    create_items
  end

  describe '.enable_active_configurations' do
    it 'adds master associations for active dynamic model item flags' do
      suffix = SecureRandom.alphanumeric(6).downcase.gsub(/[^a-z]/, '')
      table_name = "test_item_flag_enable_#{suffix}_recs"
      unless Admin::MigrationGenerator.table_exists?(table_name)
        TableGenerators.dynamic_models_table(table_name, :create_do, 'test1', 'test2', 'created_by_user_id')
      end

      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test_item_flag_enable_#{suffix}",
        table_name:,
        primary_key_name: :id,
        foreign_key_name: :master_id,
        category: :test
      )
      dm.current_admin = @admin
      dm.update_tracker_events

      flag_name = Classification::ItemFlagName.create!(
        name: "dm-flag-#{SecureRandom.hex(6)}",
        item_type: dm.item_type_name,
        current_admin: @admin
      )
      assoc_name = :"#{flag_name.item_type.pluralize}_item_flags"

      expect(ItemFlag.active_class_names).to include(dm.item_type_name.ns_underscore)
      expect(Master.reflect_on_all_associations(:has_many).map(&:name)).to include(assoc_name)

      ItemFlag.enable_active_configurations

      expect(Master.reflect_on_all_associations(:has_many).map(&:name)).to include(assoc_name)
    end

    it 'keeps the generated model item-flag association available after regeneration' do
      suffix = SecureRandom.alphanumeric(6).downcase.gsub(/[^a-z]/, '')
      table_name = "test_item_flag_regen_#{suffix}_recs"
      unless Admin::MigrationGenerator.table_exists?(table_name)
        TableGenerators.dynamic_models_table(table_name, :create_do, 'test1', 'test2', 'created_by_user_id')
      end

      dm = DynamicModel.create!(
        current_admin: @admin,
        name: "test_item_flag_regen_#{suffix}",
        table_name:,
        primary_key_name: :id,
        foreign_key_name: :master_id,
        category: :test
      )
      dm.current_admin = @admin
      dm.update_tracker_events

      flag_name = Classification::ItemFlagName.create!(
        name: "dm-regen-flag-#{SecureRandom.hex(6)}",
        item_type: dm.item_type_name,
        current_admin: @admin
      )
      assoc_name = :"#{flag_name.item_type.pluralize}_item_flags"

      expect(ItemFlag.active_class_names).to include(dm.item_type_name.ns_underscore)
      expect(Master.reflect_on_all_associations(:has_many).map(&:name)).to include(assoc_name)

      dm.other_regenerate_actions

      expect(Master.reflect_on_all_associations(:has_many).map(&:name)).to include(assoc_name)
    end
  end
end
