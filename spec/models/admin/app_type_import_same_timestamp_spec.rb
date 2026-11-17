# frozen_string_literal: true

# Verifies app type imports skip unchanged items at equal timestamps without ignoring meaningful config changes.
require 'rails_helper'

RSpec.describe Admin::AppTypeImport, type: :model do
  include ModelSupport

  before do
    Seeds.setup
    create_admin
    @app_name = "same_timestamp_#{SecureRandom.hex(5)}"
    @config_timestamp = Time.utc(2024, 1, 2, 3, 4, 5)
  end

  def app_config(value: 'configured value', updated_at: @config_timestamp)
    {
      app_type: {
        name: @app_name,
        label: @app_name.humanize,
        default_schema_name: 'ml_app',
        app_configurations: [
          {
            name: 'create master with',
            value:,
            updated_at: updated_at.iso8601
          }
        ]
      }
    }
  end

  def import(config, force_update: nil)
    described_class.import_config(config, @admin, format: :raw, force_update:)
  end

  it 'does not update unchanged items after a true force update' do
    config = app_config
    import(config)
    import(config, force_update: true)
    item = Admin::AppConfiguration.find_by!(app_type: Admin::AppType.find_by!(name: @app_name))
    expect(item.updated_at.to_i).to eq(@config_timestamp.to_i)
    previous_updated_at = item.updated_at

    expect_any_instance_of(described_class).not_to receive(:update_app_type_item)
    import(config)

    expect(item.reload.updated_at).to eq(previous_updated_at)
  end

  it 'applies a hand-edited value when the item timestamp still equals the config timestamp' do
    config = app_config
    import(config)
    import(config, force_update: true)
    item = Admin::AppConfiguration.find_by!(app_type: Admin::AppType.find_by!(name: @app_name))
    item.update_column(:value, 'hand edited')

    import(config)

    expect(item.reload.value).to eq('configured value')
  end

  it 'keeps newer items and applies newer config timestamps' do
    config = app_config
    import(config)
    item = Admin::AppConfiguration.find_by!(app_type: Admin::AppType.find_by!(name: @app_name))

    import(app_config(value: 'older config'))
    expect(item.reload.value).to eq('configured value')

    newer_timestamp = Time.current + 1.hour
    import(app_config(value: 'newer config', updated_at: newer_timestamp))

    expect(item.reload.value).to eq('newer config')
    expect(item.updated_at.to_i).to eq(newer_timestamp.to_i)
  end

  it 'still updates when force_update is :force or :changed' do
    config = app_config
    import(config)
    item = Admin::AppConfiguration.find_by!(app_type: Admin::AppType.find_by!(name: @app_name))

    import(app_config(value: 'changed by :force'), force_update: :force)
    expect(item.reload.value).to eq('changed by :force')

    import(app_config(value: 'changed by :changed'), force_update: :changed)
    expect(item.reload.value).to eq('changed by :changed')
  end

  it 'compares user associations and the effective disabled value using real users' do
    existing_user, = create_user("same-timestamp-existing-#{SecureRandom.hex(3)}")
    other_user, = create_user("same-timestamp-other-#{SecureRandom.hex(3)}")
    app_type = create_app_type(name: "#{@app_name}_user_config", label: @app_name)
    item = Admin::AppConfiguration.create!(
      app_type:, user: existing_user, name: 'create master with', value: 'configured value', disabled: false,
      current_admin: @admin
    )
    importer = described_class.new({}, @admin, format: :raw, force_update: nil)
    values = { user: existing_user, 'disabled' => true, 'value' => 'configured value', current_admin: @admin }
    original_values = values.dup

    expect(importer.send(:config_matches_existing_item?, item, values)).to be(true)
    expect(item.changed?).to be(false)
    expect(item.user_id).to eq(existing_user.id)
    expect(values).to eq(original_values)

    values[:user] = other_user
    expect(importer.send(:config_matches_existing_item?, item, values)).to be(false)
    expect(item.changed?).to be(true)
    expect(item.user_id).to eq(other_user.id)
  end

  it 'does not resave an unchanged item when a different admin imports it' do
    config = app_config
    import(config)
    import(config, force_update: true)
    item = Admin::AppConfiguration.find_by!(app_type: Admin::AppType.find_by!(name: @app_name))
    original_admin_id = item.admin_id
    other_admin, = UserSupport.create_admin("same-timestamp-importer-#{SecureRandom.hex(3)}")

    expect_any_instance_of(described_class).not_to receive(:update_app_type_item)
    described_class.import_config(config, other_admin, format: :raw, force_update: nil)

    expect(item.reload.admin_id).to eq(original_admin_id)
    expect(item.updated_at.to_i).to eq(@config_timestamp.to_i)
  end

  it 'skips dynamic definition saves when option config differs only by CRLF line endings' do
    stored_options = "default:\n  fields:\n    - item\n"
    config_options = stored_options.gsub("\n", "\r\n")
    item = DynamicModel.new(options: stored_options, disabled: false, updated_at: @config_timestamp)
    item.clear_changes_information
    importer = described_class.new({}, @admin, format: :raw, force_update: nil)
    importer.config_item = { 'updated_at' => @config_timestamp.iso8601 }
    allow(importer).to receive(:dyn_def_db_not_defined).with(item, include_reference_views: false).and_return(false)

    expect(importer).not_to receive(:update_app_type_item)
    expect(importer.create_or_update(item, { 'options' => config_options })).to eq([item, nil])
  end

  it 'still saves dynamic definition option content changes when timestamps are equal' do
    stored_options = "default:\n  fields:\n    - item\n"
    config_options = "default:\r\n  fields:\r\n    - changed\r\n"
    item = DynamicModel.new(options: stored_options, disabled: false, updated_at: @config_timestamp)
    item.clear_changes_information
    importer = described_class.new({}, @admin, format: :raw, force_update: nil)
    importer.config_item = { 'updated_at' => @config_timestamp.iso8601 }
    allow(importer).to receive(:dyn_def_db_not_defined).with(item, include_reference_views: false).and_return(false)
    allow(importer).to receive(:update_app_type_item)
      .with(item, hash_including('options' => config_options))
      .and_return(:updated)

    expect(importer.create_or_update(item, { 'options' => config_options })).to eq([item, :updated])
  end

  it 'skips a subprocess save when its protocol name is unchanged at an equal timestamp' do
    protocol = Classification::Protocol.create!(
      name: "same-timestamp-protocol-#{SecureRandom.hex(3)}", position: rand(100_000), current_admin: @admin
    )
    item = protocol.sub_processes.create!(name: "sub-process-#{SecureRandom.hex(3)}", current_admin: @admin)
    item.update!(updated_at: @config_timestamp)
    importer = described_class.new({}, @admin, format: :raw, force_update: nil)
    importer.config_item = { 'updated_at' => @config_timestamp.iso8601 }

    expect(importer).not_to receive(:update_app_type_item)
    expect(importer.create_or_update(item, { 'protocol_name' => protocol.name })).to eq([item, nil])
    expect(item.changed?).to be(false)
    expect(item.protocol_id).to eq(protocol.id)
  end

  it 'resaves a subprocess when its configured protocol name changes at an equal timestamp' do
    existing_protocol = Classification::Protocol.create!(
      name: "same-timestamp-existing-protocol-#{SecureRandom.hex(3)}", position: rand(100_000), current_admin: @admin
    )
    configured_protocol = Classification::Protocol.create!(
      name: "same-timestamp-configured-protocol-#{SecureRandom.hex(3)}", position: rand(100_000), current_admin: @admin
    )
    item = existing_protocol.sub_processes.create!(
      name: "sub-process-#{SecureRandom.hex(3)}", current_admin: @admin
    )
    item.update!(updated_at: @config_timestamp)
    importer = described_class.new({}, @admin, format: :raw, force_update: nil)
    importer.config_item = { 'updated_at' => @config_timestamp.iso8601 }
    importer.found_with_conditions = {}
    values = { 'protocol_name' => configured_protocol.name }

    expect(importer).to receive(:update_app_type_item).and_call_original
    expect(importer.create_or_update(item, values).first).to eq(item)
    expect(item.reload.protocol_id).to eq(configured_protocol.id)
  end

  it 'updates a dynamic definition when its backing table is missing at an equal timestamp' do
    item = instance_double(DynamicModel, updated_at: @config_timestamp, disabled: false)
    importer = described_class.new({}, @admin, format: :raw, force_update: nil)
    importer.config_item = { 'updated_at' => @config_timestamp.iso8601 }
    allow(importer).to receive(:dyn_def_db_not_defined).with(item, include_reference_views: false).and_return(true)
    allow(importer).to receive(:update_app_type_item) do |_existing_item, new_values|
      expect(new_values['updated_at']).to be_a(DateTime)
      :updated
    end

    expect(importer.create_or_update(item, { 'name' => 'changed' })).to eq([item, :updated])
  end
end
