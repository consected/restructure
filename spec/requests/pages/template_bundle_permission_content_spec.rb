# frozen_string_literal: true

# Issue #1481 option (b): the Handlebars multi bundle filename is a digest over the ordered compiled
# template file paths, so it moves exactly when the bundled content moves, and the skeleton that
# references it rotates on permission, page layout and app configuration changes.
#
# What a user's permissions bake into the bundle (the per-resource `prevent_create` / `prevent_edit`
# values are NOT in the bundle - they are only in the inline template_config state blobs in the skeleton):
# - masters/_master_panels: master_details_panel renders `prevent_create=<true|false>` literally into the
#   create button of the player_info, address and player_contact blocks, and only includes the blocks
#   for tables the user can access.
# - masters/_search_results_master_tabs: a page layout panel tab disappears when none of its
#   resources are viewable.
# - the per-resource result and list templates only exist for tables the user can access.
#
# These specs prove that a permission change that alters the bundled content produces a new bundle file,
# URL and skeleton containing that content (leaving the old, immutable file unreferenced), that a
# permission change that does not alter the bundled content leaves the URL unchanged, and that page layout
# and app configuration content edits move the bundle too.
require 'rails_helper'

RSpec.describe 'Pages template bundle content and permission changes', type: :request do
  include CacheKeyMemoizationSupport
  include MasterSupport
  include ModelSupport

  # Hash keys are emitted alphabetically by the Handlebars compiler
  let(:contact_create_button) { /"prevent_create":(true|false),"resource":"player_contact"/ }
  let(:contact_result_template) { 'templates["player-contact-result-template"]' }
  let(:contact_sublist) { '"player_contacts-"' }

  before do
    @admin, = create_admin
    @user, = create_user
    @master = create_master(@user)
    sign_in @user
    @previous_caching = Rails.configuration.action_controller.perform_caching
    Rails.configuration.action_controller.perform_caching = true
    @panel_label = "permprobe#{SecureRandom.hex(4)}"
    @layout = Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: @user.app_type_id,
      layout_name: 'master',
      panel_name: "perm-bundle-#{SecureRandom.hex(4)}",
      panel_label: @panel_label,
      panel_position: 303,
      options: "contains:\n  resources:\n    - player_contacts\n"
    )
  end

  after do
    Rails.configuration.action_controller.perform_caching = @previous_caching
    @layout.reload.disable!(@admin) unless @layout.disabled?
  end

  def skeleton_key
    Application.refresh_dynamic_defs
    fresh_master_skeleton_cache_key(@user)
  end

  # Fetch the skeleton and read the bundle file it references.
  # @return [Hash] skeleton HTML, and the bundle url, path and text
  def fetch_template(clean_compiled_output: false)
    HandlebarsPrecompiler.cleanup_compiled_output if clean_compiled_output
    get '/pages/test/template'
    expect(response).to have_http_status(:ok)

    skeleton = response.body.dup
    urls = skeleton.scan(
      %r{#{Regexp.escape(HandlebarsPrecompiler::URL_RELATIVE_PATH)}gen-[\w-]+/multi/[\w.-]+\.js}
    ).uniq
    expect(urls.length).to eq 1

    path = HandlebarsPrecompiler.multi_dir(urls.first[%r{gen-([\w-]+)/}, 1]).join(File.basename(urls.first))
    expect(File.exist?(path)).to be(true), "bundle file #{path} was not written"
    { skeleton:, url: urls.first, path:, text: File.read(path) }
  end

  # Change the access level on player_contacts, moving the access timestamp on by seconds, since
  # the skeleton key tracks the latest access control change to the second
  def change_player_contacts_access(access)
    previous = Admin::UserAccessControl.where(app_type_id: [@user.app_type_id, nil]).maximum(:updated_at)
    uac = setup_access(:player_contacts, access:, user: @user)
    uac.update_columns(updated_at: [previous, Time.current].max + 3.seconds) # rubocop:disable Rails/SkipsModelValidations
  end

  def inline_state_block(skeleton, name)
    skeleton[%r{<script id="fpa_state_config--#{name}--v\d+".*?</script>}m]
  end

  def contact_create_flag(text)
    flags = text.scan(contact_create_button).flatten.uniq
    expect(flags.length).to eq 1
    flags.first
  end

  it 'bakes the create permission into the bundled details panel and rotates the bundle when it changes' do
    initial = fetch_template(clean_compiled_output: true)
    initial_key = skeleton_key

    expect(@user.has_access_to?(:create, :table, :player_contacts)).to be_truthy
    expect(contact_create_flag(initial[:text])).to eq 'false'
    expect(initial[:text]).to include(contact_result_template)
    expect(inline_state_block(initial[:skeleton], 'player_contact')).to include('prevent_create: false')

    change_player_contacts_access(:read)
    expect(@user.has_access_to?(:access, :table, :player_contacts)).to be_truthy
    expect(@user.has_access_to?(:create, :table, :player_contacts)).to be_falsey
    expect(skeleton_key).not_to eq initial_key

    # Not cleaning the compiled output ensures the old bundle still exists and is not what is served
    updated = fetch_template

    expect(updated[:url]).not_to eq initial[:url]
    expect(updated[:path]).not_to eq initial[:path]
    expect(updated[:skeleton]).to include(updated[:url])
    expect(updated[:skeleton]).not_to include(initial[:url])
    expect(updated[:text]).not_to eq initial[:text]
    expect(contact_create_flag(updated[:text])).to eq 'true'
    expect(updated[:text]).to include(contact_result_template)
    expect(inline_state_block(updated[:skeleton], 'player_contact')).to include('prevent_create: true')

    expect(File.exist?(initial[:path])).to be true
    expect(contact_create_flag(File.read(initial[:path]))).to eq 'false'

    # A repeat request is served from the same new bundle
    expect(fetch_template[:url]).to eq updated[:url]
  end

  it 'rotates the bundle when revoking access removes a panel tab, block and templates from the bundled content' do
    initial = fetch_template(clean_compiled_output: true)
    initial_key = skeleton_key
    expect(initial[:text]).to include(@panel_label)
    expect(initial[:text]).to include(contact_sublist)
    expect(initial[:text]).to include(contact_result_template)

    change_player_contacts_access(nil)
    expect(@user.has_access_to?(:access, :table, :player_contacts)).to be_falsey
    expect(skeleton_key).not_to eq initial_key

    updated = fetch_template

    expect(updated[:url]).not_to eq initial[:url]
    expect(updated[:skeleton]).to include(updated[:url])
    expect(updated[:skeleton]).not_to include(initial[:url])
    expect(updated[:text]).not_to include(@panel_label)
    expect(updated[:text]).not_to include(contact_sublist)
    expect(updated[:text]).not_to include(contact_result_template)
    expect(updated[:text]).not_to match(contact_create_button)
    expect(inline_state_block(updated[:skeleton], 'player_contact')).to be_nil

    expect(File.read(initial[:path])).to include(@panel_label)
  end

  it 'keeps the bundle url when a permission change does not alter the bundled content' do
    change_player_contacts_access(:read)
    initial = fetch_template(clean_compiled_output: true)
    initial_key = skeleton_key
    expect(contact_create_flag(initial[:text])).to eq 'true'

    # Both :read and :update prevent creates, so nothing baked into the bundle moves
    change_player_contacts_access(:update)
    expect(@user.has_access_to?(:update, :table, :player_contacts)).to be_truthy
    expect(@user.has_access_to?(:create, :table, :player_contacts)).to be_falsey
    expect(skeleton_key).not_to eq initial_key

    updated = fetch_template

    expect(updated[:url]).to eq initial[:url]
    expect(updated[:text]).to eq initial[:text]
    expect(updated[:skeleton]).to include(initial[:url])
  end

  it 'moves the bundle and the skeleton key when an existing page layout panel label is edited' do
    initial = fetch_template(clean_compiled_output: true)
    initial_key = skeleton_key
    expect(initial[:text]).to include(@panel_label)

    new_label = "permprobechanged#{SecureRandom.hex(4)}"
    @layout.update!(panel_label: new_label, current_admin: @admin)
    expect(skeleton_key).not_to eq initial_key

    updated = fetch_template

    expect(updated[:url]).not_to eq initial[:url]
    expect(updated[:skeleton]).to include(updated[:url])
    expect(updated[:text]).to include(new_label)
    expect(updated[:text]).not_to include(@panel_label)
    expect(File.read(initial[:path])).to include(@panel_label)
  end

  it 'moves the bundle and the skeleton key when app configuration content baked into the chrome is edited' do
    initial = fetch_template(clean_compiled_output: true)
    initial_key = skeleton_key
    expect(initial[:text]).not_to include('permprobe-results-class')

    Admin::AppConfiguration.create!(
      current_admin: @admin,
      app_type_id: @user.app_type_id,
      user_id: @user.id,
      name: 'master results panel css class',
      value: 'permprobe-results-class'
    )
    expect(skeleton_key).not_to eq initial_key

    updated = fetch_template

    expect(updated[:url]).not_to eq initial[:url]
    expect(updated[:skeleton]).to include(updated[:url])
    expect(updated[:text]).to include('permprobe-results-class')
    expect(File.read(initial[:path])).not_to include('permprobe-results-class')
  end
end
