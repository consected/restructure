# frozen_string_literal: true

# Issue #1481 (phase 2): the template state slot key (Dynamic::VersionHandler#template_version_token) is an
# identity. For a definition that uses the current version and references config libraries it is a hash,
# so it is not monotonic and cannot be compared to decide which of two live states is newer.
# The client compares Dynamic::TemplateVersionTokens.live_order instead, which must STRICTLY INCREASE
# whenever a live definition's effective config changes: editing the definition, editing a referenced
# library, removing a library reference, or removing every library reference. These specs check that
# each of those changes raises the live order, that it is stable while nothing changes, and that it is
# an integer that JavaScript can compare exactly (below 2^53).
require 'rails_helper'

RSpec.describe 'Dynamic template live order', type: :model do
  include ModelSupport

  before :all do
    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    create_admin

    @table_name = 'test_live_order_recs'
    @category = "live_order_#{SecureRandom.hex(4)}"
    @library_a = create_library('lib_a', 'one')
    @library_b = create_library('lib_b', 'two')

    DynamicModel.active.where(table_name: @table_name).find_each { |definition| definition.disable!(@admin) }
    @dynamic_model = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Live Order Recs',
      table_name: @table_name,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'value',
      options: definition_options(library_names: %w[lib_a lib_b])
    )
  end

  after :all do
    @dynamic_model&.disable!(@admin)
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  def create_library(name, text)
    Admin::ConfigLibrary.create!(
      current_admin: @admin, category: @category, name:, format: 'yaml',
      options: "_definitions_lib:\n  message: &message_#{name} '#{text}'\n"
    )
  end

  def definition_options(library_names:, caption: 'Caption')
    references = library_names.map { |name| "# @library #{@category} #{name}\n" }.join
    <<~YAML
      #{references}_configurations:
        use_current_version: true
      default:
        caption_before:
          value: #{caption}
        fields:
          - value
    YAML
  end

  def live_order
    @dynamic_model.refresh_current_def_version!
    Dynamic::TemplateVersionTokens.live_order(@dynamic_model)
  end

  def edit_definition(**args)
    @dynamic_model.current_admin = @admin
    @dynamic_model.update!(options: definition_options(**args))
  end

  def expect_increase_after
    before_order = live_order
    yield
    after_order = live_order
    expect(after_order).to be > before_order
  end

  it 'is a stable integer that JavaScript can compare exactly' do
    order = live_order

    expect(order).to be_a(Integer)
    expect(order).to be < 2**53
    expect(live_order).to eq(order)
  end

  it 'increases when a referenced library is edited' do
    expect_increase_after do
      @library_a.current_admin = @admin
      @library_a.update!(options: "_definitions_lib:\n  message: &message_lib_a 'one edited'\n")
    end
  end

  it 'increases when the definition is edited' do
    expect_increase_after { edit_definition(library_names: %w[lib_a lib_b], caption: 'Edited caption') }
  end

  it 'increases when a library reference is removed from the definition' do
    edit_definition(library_names: %w[lib_a lib_b], caption: 'Before removal')

    expect_increase_after { edit_definition(library_names: %w[lib_a], caption: 'Before removal') }
  end

  it 'increases when a definition goes from libraries to none' do
    edit_definition(library_names: %w[lib_a lib_b], caption: 'Before none')

    expect_increase_after { edit_definition(library_names: [], caption: 'Before none') }
  end

  it 'increases when a library is edited after the references were removed and re-added' do
    edit_definition(library_names: [], caption: 'No libraries')
    expect_increase_after { edit_definition(library_names: %w[lib_b], caption: 'No libraries') }
    expect_increase_after do
      @library_b.current_admin = @admin
      @library_b.update!(options: "_definitions_lib:\n  message: &message_lib_b 'two edited'\n")
    end
  end

  it 'has no live order for a historical definition version' do
    historical_definition = @dynamic_model.all_versions.last

    expect(Dynamic::TemplateVersionTokens.live_order(historical_definition)).to be_nil
    expect(Dynamic::TemplateVersionTokens.live_order(nil)).to be_nil
  end
end
