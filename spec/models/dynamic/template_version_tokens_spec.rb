# frozen_string_literal: true

# Verifies panel/chrome version tokens track current PageLayout and AppConfiguration history.
require 'rails_helper'

RSpec.describe 'Dynamic template version tokens', type: :model do
  include ModelSupport

  before do
    @admin, = create_admin
    @user, = create_user
  end

  def create_page_layout
    Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: @user.app_type_id,
      layout_name: 'master',
      panel_name: "template-token-#{SecureRandom.hex(4)}",
      panel_label: 'Template Token Panel',
      panel_position: 300,
      options: "contains:\n  resources:\n    - player_contacts\n"
    )
  end

  def create_app_configuration
    Admin::AppConfiguration.create!(
      current_admin: @admin,
      app_type_id: @user.app_type_id,
      user_id: @user.id,
      name: 'notes field format',
      value: 'markdown'
    )
  end

  it 'returns zero for an object without a template version token' do
    expect(Dynamic::TemplateVersionTokens.resource_token(Object.new)).to eq(0)
  end

  it 'changes the panel token on add, edit, disable, and enable' do
    token = Dynamic::TemplateVersionTokens.panel_chrome_token
    layout = create_page_layout

    created_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(created_token).not_to eq(token)

    layout.update!(panel_label: 'Updated Template Token Panel', current_admin: @admin)
    edited_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(edited_token).not_to eq(created_token)

    layout.disable!(@admin)
    disabled_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(disabled_token).not_to eq(edited_token)

    layout.update!(disabled: false, current_admin: @admin)
    enabled_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(enabled_token).not_to eq(disabled_token)
  end

  it 'changes the panel token on app-configuration add, edit, disable, and enable' do
    token = Dynamic::TemplateVersionTokens.panel_chrome_token
    configuration = create_app_configuration

    created_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(created_token).not_to eq(token)

    configuration.update!(value: 'plain', current_admin: @admin)
    edited_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(edited_token).not_to eq(created_token)

    configuration.disable!(@admin)
    disabled_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(disabled_token).not_to eq(edited_token)

    configuration.update!(disabled: false, current_admin: @admin)
    enabled_token = Dynamic::TemplateVersionTokens.panel_chrome_token
    expect(enabled_token).not_to eq(disabled_token)
  end

  it 'tracks nested YAML libraries only for live definitions' do
    category = "template-token-#{SecureRandom.hex(4)}"
    leaf = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      category:,
      name: 'leaf',
      format: 'yaml',
      options: "definitions:\n  caption: NestedOne\n"
    )
    Admin::ConfigLibrary.create!(
      current_admin: @admin,
      category:,
      name: 'root',
      format: 'yaml',
      options: "# @library #{category} leaf\ndefault:\n  fields: [test1]\n"
    )
    definition = double(
      id: 1,
      def_version: nil,
      updated_at: Time.current,
      uses_current_definition_version?: true,
      options_text: "# @library #{category} root\ndefault:\n  fields: [test1]\n"
    )

    initial_tokens = Dynamic::TemplateVersionTokens.live_config_library_tokens([definition])
    expect(initial_tokens.map { |token| token.first(2) }).to contain_exactly([category, 'root'], [category, 'leaf'])

    leaf.update_columns(updated_at: Time.current + 3.seconds)
    expect(Dynamic::TemplateVersionTokens.live_config_library_tokens([definition])).not_to eq(initial_tokens)

    allow(definition).to receive(:uses_current_definition_version?).and_return(false)
    expect(Dynamic::TemplateVersionTokens.live_config_library_tokens([definition])).to eq([])
  end

  it 'resolves library token metadata through the same active-library lookup as rendering' do
    category = "template-token-#{SecureRandom.hex(4)}"
    library = double(id: 1, updated_at: Time.current)
    definition = double(
      id: 2,
      def_version: nil,
      updated_at: Time.current,
      uses_current_definition_version?: true,
      options_text: "# @library #{category} canonical-library\ndefault:\n  fields: [test1]\n"
    )
    expect(OptionConfigs::ExtraOptions).to receive(:requested_libraries)
      .and_return([{ category:, name: 'canonical-library' }])
    allow(Admin::ConfigLibrary).to receive(:find_active_library!)
      .with(category, 'canonical-library', format: 'yaml').and_return(library)
    allow(Admin::ConfigLibrary).to receive(:find_by).and_return(nil)

    token = Dynamic::TemplateVersionTokens.live_config_library_tokens([definition]).first

    expect(token).to eq([category, 'canonical-library', library.id, library.updated_at.to_f])
  end
end
