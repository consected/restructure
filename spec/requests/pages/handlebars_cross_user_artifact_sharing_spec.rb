# frozen_string_literal: true

# Request spec (issue #1362 Stage 1) - proves the content-addressed compiled Handlebars
# artifact cache correctly ISOLATES and SHARES the compiled 'master_main_inner' partial
# across a realistic sequence of different real users hitting the SAME page
# (/pages/test/template), within a single stable generation (no server_cache_version or
# dynamic-definition change between requests).
#
# This closes a gap identified during Stage 1 review: existing coverage
# (spec/system/user/app_type_switch_master_tabs_spec.rb,
# spec/system/page_layout/resource_type_rendering_spec.rb,
# spec/models/prewarm/content_addressing_safety_spec.rb, and the
# "#write_handlebars_template content addressing sharing/isolation" unit specs in
# spec/helpers/handlebars_precompiler_helper_spec.rb) proves DOM-level isolation and
# unit-level digest behaviour, but nothing exercises the ACTUAL on-disk compiled files
# across a real HTTP request sequence for more than one user, and nothing proves that
# users who SHOULD share an artifact actually converge on the SAME file rather than each
# getting their own (which would silently defeat Stage 1's whole sharing goal while every
# other existing test still passed).
#
# Scenario: User A and User C have IDENTICAL resource access (so their rendered
# master_main_inner source is byte-identical); User B has DIFFERENT, disjoint access.
# Sequence: A, then B, then C, then A again - proving:
#   1. A and B (different access) are correctly ISOLATED - never share a file.
#   2. B's request never modifies or evicts A's already-compiled file.
#   3. C (same access as A) REUSES A's file - no new compile, no third file created.
#   4. A's second visit, after B and C, still resolves to its ORIGINAL unmodified file.
# Assertions are made directly against the compiled files on disk (existence, count,
# byte content), not the HTTP response/DOM, since only file-level assertions can tell
# "one shared file" apart from "two coincidentally-identical files".

require 'rails_helper'

RSpec.describe 'Cross-user Handlebars compiled artifact sharing and isolation (issue #1362)',
               type: :request do
  include ModelSupport
  include MasterSupport
  include DynamicModelSupport

  def panel_a
    'xu-panel-a'
  end

  def panel_b
    'xu-panel-b'
  end

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @admin, = create_admin
    @user_a, = create_user
    @app_type = @user_a.app_type
    create_master(@user_a)
    @user_b, = create_user(app_type: @app_type)
    @user_c, = create_user(app_type: @app_type)

    setup_dm_resource('xu_a_recs', 'XU A Rec')
    setup_dm_resource('xu_b_recs', 'XU B Rec')

    create_resource_panel(panel_name: panel_a, panel_label: 'XU Panel A',
                          resources: ['dynamic_model__xu_a_recs'])
    create_resource_panel(panel_name: panel_b, panel_label: 'XU Panel B',
                          resources: ['dynamic_model__xu_b_recs'])

    setup_access :dynamic_model__xu_a_recs, user: @user_a
    setup_access :dynamic_model__xu_b_recs, user: @user_b
    # User C is granted the SAME access as user A, to prove sharing (not just isolation).
    setup_access :dynamic_model__xu_a_recs, user: @user_c

    Rails.application.routes_reloader.reload!

    # Start fully cold, then hold the generation key stable for the whole example below -
    # nothing else in item_update_classes (DynamicModel/Admin::PageLayout/etc) is touched
    # after this point, so gen-<key> never rotates mid-sequence.
    HandlebarsPrecompiler.cleanup_compiled_output
    HandlebarsPrecompiler.cleanup_tmp_dir
  end

  after(:all) do
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name: [panel_a, panel_b]).each do |pl|
      pl.disable!(@admin)
    end
    Rails.application.routes_reloader.reload!
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  def setup_dm_resource(table_name, label)
    class_name = table_name.singularize.camelize.to_sym
    DynamicModel.active.where(table_name:).reload.each { |dm| dm.disable!(@admin) }
    DynamicModel.send(:remove_const, class_name) if DynamicModel.const_defined?(class_name, false)

    DynamicModel.create!(
      current_admin: @admin,
      name: label,
      schema_name: 'dynamic_test',
      table_name:,
      category: :details,
      field_list: 'description',
      primary_key_name: 'id',
      foreign_key_name: 'master_id'
    )
  end

  def create_resource_panel(panel_name:, panel_label:, resources:)
    Admin::PageLayout.active.where(app_type_id: @app_type.id, panel_name:).each { |pl| pl.disable!(@admin) }
    resource_list = resources.map { |r| "    - #{r}" }.join("\n")
    Admin::PageLayout.create!(
      current_admin: @admin,
      app_type_id: @app_type.id,
      layout_name: 'master',
      panel_name:,
      panel_label:,
      panel_position: 200,
      options: <<~YAML
        contains:
          resources:
        #{resource_list}
      YAML
    )
  end

  # Clears Rails.cache (busting the OUTER per-user page-fragment cache - see
  # ApplicationHelper#partial_cache_key - so every request below genuinely re-executes
  # the view and re-exercises write_handlebars_template, rather than serving a fragment
  # cached from an earlier step) while preserving server_cache_version, so the
  # Handlebars generation key - and therefore gen-<key>/ - never rotates mid-sequence.
  def bust_page_fragment_cache!
    scv = Rails.cache.read('server_cache_version')
    Rails.cache.clear
    Rails.cache.write('server_cache_version', scv) if scv
  end

  # Signs in as +user+, requests the app template page, and returns [all compiled
  # master_main_inner partial files, files newly written by THIS request]. "Newly
  # written" is computed as a set difference against +known+ (the caller's own record of
  # what existed before), not by mtime, so it is exact regardless of timing/filesystem
  # mtime resolution.
  def request_as(user, known)
    sign_out(:user) if @signed_in
    bust_page_fragment_cache!
    sign_in user
    @signed_in = true

    get '/pages/test/template'
    expect(response).to have_http_status(:ok)

    all_files = Dir.glob(HandlebarsPrecompiler.partials_compiled_dir.join('master_main_inner-*.js'))
    [all_files, all_files - known]
  end

  it 'isolates different-access users, shares identical-access users, and survives a later return visit' do
    all_a, new_a = request_as(@user_a, [])
    expect(all_a.size).to eq(1)
    expect(new_a.size).to eq(1)
    file_a = new_a.first
    content_a = File.read(file_a)
    expect(content_a).to include(panel_a)
    expect(content_a).not_to include(panel_b)

    all_b, new_b = request_as(@user_b, all_a)
    expect(new_b.size).to eq(1),
                          "Expected user B's different access to produce a SECOND compiled file, got: #{all_b}"
    file_b = new_b.first
    content_b = File.read(file_b)
    expect(content_b).to include(panel_b)
    expect(content_b).not_to include(panel_a)
    # B's request must not have touched A's already-compiled file.
    expect(File.exist?(file_a)).to be true
    expect(File.read(file_a)).to eq(content_a)

    all_c, new_c = request_as(@user_c, all_b)
    expect(new_c).to be_empty,
                     "Expected user C (same access as A) to REUSE A's compiled file, not create a third: #{all_c}"
    expect(all_c).to match_array(all_b)

    all_a2, new_a2 = request_as(@user_a, all_c)
    expect(new_a2).to be_empty,
                      "Expected user A's return visit to reuse its original file, not create a third: #{all_a2}"
    expect(all_a2).to match_array(all_c)
    # A's original file is still exactly what it was before B and C's requests.
    expect(File.read(file_a)).to eq(content_a)
    expect(File.read(file_a)).not_to include(panel_b)
  end
end
