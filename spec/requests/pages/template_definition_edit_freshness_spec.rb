# frozen_string_literal: true

# Regression specs for issue #1525: page templates must use fresh dynamic
# definition options after direct edits and cross-process updates.
require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe 'Pages template freshness after dynamic definition edits', type: :request do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport

  def dynamic_model_table_name
    'issue1525_template_recs'
  end

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    @prev_disable_vdef = Settings::DisableVDef
    change_setting('AllowDynamicMigrations', true)
    change_setting('DisableVDef', false)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
    change_setting('DisableVDef', @prev_disable_vdef)
  end

  before do
    @admin, = create_admin
    @user, = create_user
    @master = create_master(@user)
    sign_in @user

    unless Admin::MigrationGenerator.table_exists?(dynamic_model_table_name)
      TableGenerators.dynamic_models_table(dynamic_model_table_name, :create_do, 'test1', 'test2')
    end
  end

  after do
    if @dm&.persisted?
      @dm.reload
      @dm.disable!(@admin) unless @dm.disabled?
    end

    if @lib&.persisted?
      @lib.reload
      @lib.disable!(@admin) unless @lib.disabled?
    end
  end

  def create_dynamic_model(options)
    DynamicModel.active.where(table_name: dynamic_model_table_name).reload.each do |old_definition|
      old_definition.current_admin = @admin
      old_definition.disable!(@admin)
    end

    class_name = dynamic_model_table_name.singularize.ns_camelize
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    definition = DynamicModel.create!(
      current_admin: @admin,
      name: "Issue1525 template #{SecureRandom.hex(4)}",
      table_name: dynamic_model_table_name,
      schema_name: 'dynamic_test',
      category: :test,
      options:
    )
    definition.current_admin = @admin
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    setup_access :dynamic_model__issue1525_template_recs, user: @user
    DynamicModel.reset_active_model_configurations!
    @dm = definition
  end

  def caption_options(caption)
    <<~YAML
      default:
        fields:
          - test1
          - test2
        caption_before:
          test1: #{caption}
    YAML
  end

  def page_template_text
    HandlebarsPrecompiler.cleanup_compiled_output
    get '/pages/test/template'
    expect(response).to have_http_status(:ok)

    text = +response.body
    response.body.scan(%r{/handlebars-test/gen-(\w+)/multi/([\w.-]+\.js)}).uniq.each do |key, filename|
      path = HandlebarsPrecompiler.multi_dir(key).join(filename)
      text << "\n" << File.read(path) if File.exist?(path)
    end
    text
  end

  it 'renders the current caption after an options-only save without a manual refresh' do
    definition = create_dynamic_model(caption_options('ProbeOne'))
    expect(page_template_text).to include('ProbeOne')

    change_setting('AllowDynamicMigrations', false)
    begin
      definition = DynamicModel.active.find(definition.id)
      definition.current_admin = @admin
      definition.options = caption_options('ProbeTwo')
      definition.save!
    ensure
      change_setting('AllowDynamicMigrations', true)
    end

    text = page_template_text
    expect(text).to include('ProbeTwo')
    expect(text).not_to include('ProbeOne')
  end

  it 'renders an updated config-library caption (regression guard: this path already worked)' do
    suffix = SecureRandom.hex(4)
    category = "issue1525cat#{suffix}"
    name = "issue1525lib#{suffix}"
    @lib = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name:,
      category:,
      format: 'yaml',
      options: "_definitions_lib:\n  cap: &cap LibOne\n"
    )
    create_dynamic_model(<<~YAML)
      # @library #{category} #{name}
      default:
        fields: [test1, test2]
        caption_before:
          test1: *cap
    YAML

    page_template_text

    sleep 2
    @lib.current_admin = @admin
    @lib.options = "_definitions_lib:\n  cap: &cap LibTwo\n"
    @lib.save!

    text = page_template_text
    expect(text).to include('LibTwo')
    expect(text).not_to include('LibOne')
  end

  it 'refreshes definitions before rendering a cross-process options update' do
    definition = create_dynamic_model(caption_options('WorkerOne'))
    expect(page_template_text).to include('WorkerOne')

    sleep 2
    definition.update_columns(options: caption_options('WorkerTwo'), updated_at: Time.now)

    text = page_template_text
    expect(text).to include('WorkerTwo')
    expect(text).not_to include('WorkerOne')
  end

  it 'does not refresh dynamic definitions when revalidating a matching template etag' do
    token = begin
      get '/masters/search'
      expect(response).to have_http_status(:ok)
      match = response.body.match(/_fpa\.state\.template_version\s*=\s*'([a-f0-9]{64})'/)
      expect(match).to be_present
      match[1]
    end

    get "/pages/#{token}/template"
    expect(response).to have_http_status(:ok)
    etag = response.headers['ETag']
    expect(etag).to be_present

    expect(Application).not_to receive(:refresh_dynamic_defs)
    get "/pages/#{token}/template", headers: { 'HTTP_IF_NONE_MATCH' => etag }
    expect(response).to have_http_status(:not_modified)
  end
end
