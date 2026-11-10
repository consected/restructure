# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# System (acceptance) tests for issue #1238 — activity log embedded dynamic
# models fail to render in show (read-only) mode after save when the embedded
# dynamic model uses "definition versioning: version at record creation".
#
# Purpose / acceptance criteria (verbatim from the issue):
#   "Acceptance tests must show that embedded dynamic models for versioned and
#    unversioned work correctly and view in edit and show modes."
#   "To avoid regressions, we must also test an activity log activity that has a
#    `references` config with a single entry, so that the item appears embedded,
#    even though it is referenced through model references."
#
# Strategy: AL records and their embedded / referenced DM records are created
# programmatically (in the test thread, visible to the browser via Rails 7
# transactional system tests). The browser then navigates to the master page
# and we verify that the Handlebars client-side templates correctly render
# the embedded DM in show (read-only) mode.  The KEY regression from issue
# #1238 is that the plural resource-name alias in template_config was missing
# the per-version key (e.g. `.v254`), so versioned-DM records at any version
# other than the latest showed nothing.  After the fix the alias is set for
# every version, so old records still render.
#
# Follows the pattern of spec/system/page_layout/initial_show_tab_spec.rb:
# user + master created once in before(:all), login per example, page layout
# created explicitly so the AL panel auto-expands via initial_show.
describe 'Activity log embedded versioned dynamic model show mode (issue 1238)',
         js: true, driver: $browser_driver do # rubocop:disable Style/GlobalVars
  include FeatureSupport
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  # rubocop:disable Lint/ConstantDefinitionInBlock
  AlNameEmbedShow = 'Embed Show 1238'
  AlProcessEmbedShow = 'embed_show'
  AlFkEmbedShow = 'activity_log_player_contact_embed_show_id'

  # Capybara wait (seconds) for asynchronously-rendered embedded show-mode
  # content. After a definition version bump or a cache clear, the browser must
  # fetch the per-version template_config and render the embedded DM show form
  # client-side. Under combined-suite load this can take noticeably longer than
  # the default Capybara wait, so use a generous timeout to avoid flakiness
  # (the assertion still resolves as soon as the content becomes visible).
  EmbeddedShowRenderWait = 60
  # rubocop:enable Lint/ConstantDefinitionInBlock

  def setup_embed_target_models
    al_fk = AlFkEmbedShow
    # Drop and recreate each table to ensure the FK column matches the current
    # AL table name.  (If a previous test run used a different AL process name
    # the table may have an incorrect FK column.)
    %w[show1238_embed_versioned_recs show1238_embed_unversioned_recs].each do |tn|
      TableGenerators.dynamic_models_table(tn, :drop_do)
      TableGenerators.dynamic_models_table(tn, :create_do, 'test1', 'test2', al_fk)
    end
    TableGenerators.dynamic_models_table('show1238_ref_single_recs', :drop_do)
    TableGenerators.dynamic_models_table('show1238_ref_single_recs', :create_do, 'test1', 'test2')

    DynamicModel.active
                .where(table_name: %w[show1238_embed_versioned_recs show1238_embed_unversioned_recs
                                      show1238_ref_single_recs])
                .each { |dm| dm.disable!(@admin) }

    DynamicModel.create!(current_admin: @admin, name: 'show1238 embed versioned recs',
                         table_name: 'show1238_embed_versioned_recs',
                         schema_name: 'dynamic_test', category: :test,
                         options: "default:\n  label: Embed1238V\n  labels:\n    test1: LabelField1V1234\n")
                .update_tracker_events

    DynamicModel.create!(current_admin: @admin, name: 'show1238 embed unversioned recs',
                         table_name: 'show1238_embed_unversioned_recs',
                         schema_name: 'dynamic_test', category: :test,
                         options: "_configurations:\n  use_current_version: true\ndefault:\n  label: Embed1238U\n  labels:\n    test1: LabelField1U1234\n")
                .update_tracker_events

    DynamicModel.create!(current_admin: @admin, name: 'show1238 ref single recs',
                         table_name: 'show1238_ref_single_recs',
                         schema_name: 'dynamic_test', category: :test,
                         options: "default:\n  label: Embed1238R\n")
                .update_tracker_events
  end

  def setup_activity_log
    SetupHelper.setup_al_gen_tests AlNameEmbedShow, AlProcessEmbedShow, 'player_contact'

    al = ActivityLog.active.where(name: AlNameEmbedShow).first
    raise "Activity Log #{AlNameEmbedShow} not set up" if al.nil?

    al.extra_log_types = <<~END_DEF
      versioned_activity:
        label: Versioned activity
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__show1238_embed_versioned_recs

      unversioned_activity:
        label: Unversioned activity
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__show1238_embed_unversioned_recs

      ref_single_activity:
        label: Ref single activity
        fields:
          - select_call_direction
          - select_who
        references:
          - dynamic_model__show1238_ref_single_recs:
              label: Referenced single
              from: this
              add: one_to_this
    END_DEF

    al.current_admin = @admin
    al.save!

    @activity_log = al
    @implementation_class = al.implementation_class
  end

  def setup_access_for_user
    setup_access :player_contacts, user: @user
    setup_access :player_infos, user: @user
    setup_access :activity_log__player_contact_embed_shows, user: @user
    @activity_log.option_configs.each do |c|
      setup_access c.resource_name, resource_type: :activity_log_type, user: @user
    end
    %i[dynamic_model__show1238_embed_versioned_recs
       dynamic_model__show1238_embed_unversioned_recs
       dynamic_model__show1238_ref_single_recs].each do |rn|
      setup_access rn, user: @user
    end
  end

  before :all do
    # AllowDynamicMigrations and TwoFactorAuthDisabledForUser are set globally
    # by config.before(:all, type: :system) in rails_helper.rb.
    @prev_disable_vdef = Settings::DisableVDef
    change_setting('DisableVDef', false)

    SetupHelper.feature_setup

    @admin = create_admin.first
    create_user(create_master: false)
    @app_type = @user.app_type

    setup_embed_target_models
    setup_activity_log
    setup_access_for_user

    # Page layout: auto-expand our AL panel so each test sees it immediately
    # after navigating to the master record (initial_show: true).
    @al_page_layout = Admin::PageLayout.create!(
      layout_name: 'master',
      panel_name: 'show-embeds-1238',
      panel_label: 'Show Embeds 1238',
      panel_position: 99,
      app_type: @app_type,
      current_admin: @admin,
      options: "contains:\n  resources:\n    " \
               "- activity_log__player_contact_embed_shows\n" \
               "view_options:\n  initial_show: true\n"
    )

    @master = Master.create!(current_user: @user)
    @master.current_user = @user
    @master.player_infos.create!(first_name: 'Embed1238', last_name: 'Test', source: 'nflpa')
    @player_contact = @master.player_contacts.create!(
      current_user: @user, data: '(516)262-1291', rec_type: 'phone', rank: 10
    )

    DynamicModel.define_models
    ActivityLog.define_models
    DynamicModel.routes_reload
    Rails.application.routes_reloader.reload!
  end

  after :all do
    change_setting('DisableVDef', @prev_disable_vdef)
    if @al_page_layout
      # History records reference the layout via FK — must be deleted first.
      ActiveRecord::Base.connection.execute(
        "DELETE FROM page_layout_history WHERE page_layout_id = #{@al_page_layout.id}"
      )
      @al_page_layout.destroy
    end

    # Disable the embed_show AL definition so it does not pollute subsequent specs.
    # The activity_logs table is not truncated between spec files for system specs,
    # so this definition persists and can interfere with specs that run after us
    # (e.g. register_call_spec) by being included in Handlebars template compilation.
    ActivityLog.where(name: AlNameEmbedShow).find_each do |al|
      al.update_column(:disabled, true)
    end
    # Rebuild in-memory class definitions to reflect the disabled AL.
    ActivityLog.define_models
  end

  before :each do
    # Clear precompiled Handlebars templates so the page layout created in
    # before(:all) is included in the compiled master template for each example.
    # (Pattern from spec/system/page_layout/initial_show_tab_spec.rb)
    Admin::AppConfiguration.clear_memo!
    HandlebarsPrecompiler.cleanup_tmp_dir
    HandlebarsPrecompiler.cleanup_compiled_output
    Rails.cache.delete('server_cache_version')
    login
    # Each example creates its own records before calling navigate_to_master,
    # so that the browser sees fresh data when the page loads.
  end

  # ===================================================================
  # Programmatic record-creation helpers
  # (Records are created in the test thread; they are visible to the browser
  #  via the shared database transaction in Rails 7 system tests.)
  # ===================================================================

  # Create an AL record for @player_contact / @master.
  def create_al_record(extra_log_type:)
    @implementation_class.create!(
      extra_log_type: extra_log_type,
      select_call_direction: 'to player',
      select_who: 'user',
      player_contact: @player_contact,
      master: @master,
      current_user: @user
    )
  end

  # Create a brand-new master (with a player_info + player_contact) and an AL
  # record of the given type on it.  Used by the cross-master switching test so
  # that two DIFFERENT masters can hold embedded DMs at different definition
  # versions.  Returns [master, al_record].
  def create_master_with_al_record(extra_log_type:, phone:, first_name:)
    master = Master.create!(current_user: @user)
    master.current_user = @user
    master.player_infos.create!(first_name: first_name, last_name: 'Test', source: 'nflpa')
    player_contact = master.player_contacts.create!(
      current_user: @user, data: phone, rec_type: 'phone', rank: 10
    )
    al = @implementation_class.create!(
      extra_log_type: extra_log_type,
      select_call_direction: 'to player',
      select_who: 'user',
      player_contact: player_contact,
      master: master,
      current_user: @user
    )
    [master, al]
  end

  # Return the active implementation class for the given DM table name.
  def dm_class_for(table_name)
    DynamicModel.active.find_by(table_name: table_name).implementation_class
  end

  # Populate test1 on the auto-created embedded DM record (linked via FK) so
  # that a concrete field value is visible in the rendered page.  The embed:
  # config renders DM fields inline (seamless mode) without a label heading,
  # so we assert on field VALUES rather than the DM label.
  def set_embedded_dm_field(table_name, al_record, value)
    dm_class = dm_class_for(table_name)
    dm_rec = dm_class.find_by(AlFkEmbedShow => al_record.id)
    raise "No auto-created DM found for AL #{al_record.id} in #{table_name}" unless dm_rec

    dm_rec.current_user = @user
    dm_rec.test1 = value
    dm_rec.save!
  end

  # ===================================================================
  # NOTE: for embed: config, the system auto-creates an embedded DM record
  # via the link_embedded_item after_create callback when an AL is saved.
  # Do NOT create DM records separately — that would create duplicates.
  # ===================================================================

  # ===================================================================
  # Browser navigation helpers
  # ===================================================================

  # Navigate to the master page and expand the AL panel tab.
  # rubocop:disable Naming/PredicateMethod
  def navigate_and_expand_al_panel
    navigate_to_master(@master.id)
    expand_master_record_tab('activity_log__player_contact_embed_shows')
    # Explicitly wait for the master search-results templates to compile.
    # finish_page_loading exits early when body.sessions is present, so we must
    # wait here to ensure Handlebars has the template_config and labels state
    # before any label-specific assertions run.
    page.has_css?('body.status-compiled', wait: 60)
  end
  # rubocop:enable Naming/PredicateMethod

  # Clear Handlebars caches and re-navigate (needed after definition bumps).
  # Also clears the browser's HTTP cache via CDP so template_config is re-fetched
  # rather than served from the max-age=30 browser cache from the first navigation.
  def clear_caches_and_navigate
    Admin::AppConfiguration.clear_memo!
    HandlebarsPrecompiler.cleanup_tmp_dir
    HandlebarsPrecompiler.cleanup_compiled_output
    Rails.cache.delete('server_cache_version')
    page.driver.browser.execute_cdp('Network.clearBrowserCache')
    navigate_and_expand_al_panel
  end

  # Bump the definition version of the given DM table by saving new options with
  # the supplied label.  Disables dynamic migrations during the save so that the
  # table-comment migration doesn't race with the just-created record; version
  # history is tracked independently of migrations.  After saving it reloads
  # model definitions and restarts the server so the new version is live.
  #
  # The DB trigger inserts a V2 history record within the test transaction.  The
  # server thread uses a separate connection and cannot see uncommitted data, so
  # all_versions_query on that connection would only return [V1].  We pre-populate
  # the class-level all_versions_memo here — using the test-thread connection that
  # CAN see the trigger's insert — so the server thread reads the shared in-process
  # memo value [V2, V1] instead of issuing a fresh DB query.
  def bump_dm_version(table_name, new_label)
    sleep 2 # ensure a distinct created_at timestamp for the new version
    dm = DynamicModel.active.find_by(table_name: table_name)
    change_setting('AllowDynamicMigrations', false)
    dm.current_admin = @admin
    dm.options = "default:\n  label: #{new_label}\n  labels:\n    test1: #{new_label} Field\n"
    dm.save!
    # Pre-populate all_versions_memo via the test-thread connection so the server
    # thread (which cannot see the uncommitted trigger insert) uses the memo.
    dm.all_versions
    change_setting('AllowDynamicMigrations', true)
    DynamicModel.define_models
    Application.refresh_dynamic_defs
    AppControl.restart_server
  end

  # Save a NEW version of the activity log definition, changing the display
  # label of the `select_who` field on the `versioned_activity` extra log type.
  #
  # All three extra log types are re-declared verbatim so the unversioned and
  # references activities used by other examples are unaffected (only the
  # versioned_activity select_who label changes).  Saving creates a new AL
  # definition version — ActivityLog includes Dynamic::VersionHandler — so AL
  # records created afterwards resolve to this version via `versioned_definition`,
  # while records created beforehand keep resolving to the previous version.
  #
  # The change is made inside the example, so (like bump_dm_version) it rolls
  # back with the transactional system-test wrapper after the example finishes.
  def bump_al_field_label(who_label)
    sleep 2 # ensure a distinct created_at timestamp for the new AL version
    change_setting('AllowDynamicMigrations', false)
    @activity_log.extra_log_types = <<~END_DEF
      versioned_activity:
        label: Versioned activity
        fields:
          - select_call_direction
          - select_who
        labels:
          select_who: #{who_label}
        embed: dynamic_model__show1238_embed_versioned_recs

      unversioned_activity:
        label: Unversioned activity
        fields:
          - select_call_direction
          - select_who
        embed: dynamic_model__show1238_embed_unversioned_recs

      ref_single_activity:
        label: Ref single activity
        fields:
          - select_call_direction
          - select_who
        references:
          - dynamic_model__show1238_ref_single_recs:
              label: Referenced single
              from: this
              add: one_to_this
    END_DEF
    @activity_log.current_admin = @admin
    @activity_log.save!
    change_setting('AllowDynamicMigrations', true)
    ActivityLog.define_models
    Application.refresh_dynamic_defs
    AppControl.restart_server
  end

  # ===================================================================
  # Shared examples
  # ===================================================================

  # Verifies that multiple AL instances each automatically show their own
  # embedded DM block in show (read-only) mode.  Creating the AL record is
  # sufficient — the link_embedded_item after_create callback auto-creates
  # one DM record per AL via the FK column.  The `embed:` config then renders
  # that DM form inside the AL show block.
  #
  # `dm_table` is the DM table name (e.g. 'show1238_embed_versioned_recs').
  # The embed: config renders DM fields in seamless mode (inline, no label
  # heading), so we populate test1 on each auto-created DM and assert on
  # the titleized field VALUE appearing in the page.  If the template_config
  # alias is missing (the issue-1238 bug) the entire block is absent and the
  # field values never appear.
  # `dm_label` is the version-specific label for the test1 field (from the DM
  # options `labels:` config).  Its presence proves the correct per-version
  # template is being used to render the embedded DM block.
  shared_examples 'an embedded activity viewable in show mode' do |extra_log_type, dm_table, dm_label|
    it 'shows embedded DM blocks in read-only mode and exposes edit buttons for each AL instance' do
      # Two AL instances of the same type — the system auto-creates one
      # embedded DM per AL via the link_embedded_item after_create callback.
      al1 = create_al_record(extra_log_type: extra_log_type)
      set_embedded_dm_field(dm_table, al1, 'embed item alpha')
      al2 = create_al_record(extra_log_type: extra_log_type)
      set_embedded_dm_field(dm_table, al2, 'embed item beta')

      navigate_and_expand_al_panel

      # Version-specific field label confirms the correct per-version template
      # is rendered.  (Before the fix the block was entirely absent for
      # versioned DMs; neither the label nor the value would appear.)
      expect(page).to have_text(dm_label, wait: EmbeddedShowRenderWait)
      # Both field values must also appear — proves each AL instance's embedded
      # DM block is rendered.
      expect(page).to have_text('Embed Item Alpha')
      expect(page).to have_text('Embed Item Beta')

      # Each AL instance has its own edit button.
      expect(page).to have_css('.edit-entity', minimum: 2, wait: 10)
    end
  end

  # ===================================================================
  # Versioned embedded dynamic model
  # ===================================================================

  describe 'versioned embedded dynamic model' do
    include_examples 'an embedded activity viewable in show mode',
                     :versioned_activity, 'show1238_embed_versioned_recs', 'LabelField1V1234'

    # KEY regression test for issue #1238: after the DM definition version is
    # bumped, a previously saved record is now on an OLDER version.  Without the
    # fix in _search_results_template.html.erb the browser JS logs:
    #   "could not find template_config dynamic_model__..._recs v<n>"
    # and the show-mode form never renders.  With the fix the per-version alias
    # is set on the plural resource-name key, so old records still display.
    it 'still renders the older-version embedded item in show mode after a definition version bump' do
      # Two AL instances at version N — auto-created embedded DMs via after_create.
      # Populate test1 so we can assert on field values in the page.
      al1 = create_al_record(extra_log_type: :versioned_activity)
      set_embedded_dm_field('show1238_embed_versioned_recs', al1, 'pre bump alpha')
      al2 = create_al_record(extra_log_type: :versioned_activity)
      set_embedded_dm_field('show1238_embed_versioned_recs', al2, 'pre bump beta')

      # First navigation: both AL instances show their embedded DM at version N.
      navigate_and_expand_al_panel
      # Version-specific field label confirms the initial version template is rendered.
      expect(page).to have_text('LabelField1V1234', wait: 60)
      expect(page).to have_text('Pre Bump Alpha')
      expect(page).to have_css('.edit-entity', minimum: 2, wait: 10)

      # Bump definition version (uses the bump_dm_version helper).
      bump_dm_version('show1238_embed_versioned_recs', "Versioned v#{SecureRandom.hex(2)}")

      # Re-navigate with fresh template_config (now at version N+1).
      # With the fix the plural alias also carries the v<N> key, so both
      # older-version AL instances must still render their embedded DM —
      # confirmed by the original field label and values still appearing.
      clear_caches_and_navigate
      # Old version-specific label must still appear — proves the pre-bump template
      # is still reachable via the plural alias after the version bump.
      expect(page).to have_text('LabelField1V1234', wait: EmbeddedShowRenderWait)
      expect(page).to have_text('Pre Bump Alpha')
      expect(page).to have_text('Pre Bump Beta')
      expect(page).to have_css('.edit-entity', minimum: 2, wait: 10)
    end

    # Strongest regression test for issue #1238: two AL records on the SAME
    # master page, each with an embedded DM saved at a DIFFERENT definition
    # version.  Both must render their embedded DM content.
    #
    # Without the fix only the current-version alias exists in template_config,
    # so the older record's embed block is silently absent — its field values
    # never appear.  With the fix both version keys exist on the plural alias,
    # so both blocks render and both field values are visible.
    it 'shows each embedded item with its own version-specific content when two versions coexist on the same page' do
      # Step 1: Create AL record 1 at the current version.
      # The link_embedded_item after_create callback auto-creates the embedded DM.
      # Populate test1 with a unique value to assert rendering at this version.
      al_v1 = create_al_record(extra_log_type: :versioned_activity)
      set_embedded_dm_field('show1238_embed_versioned_recs', al_v1, 'version one data')

      # Step 2: Bump the DM definition to a new version.
      bump_dm_version('show1238_embed_versioned_recs', 'Embed1238-Two')

      # Step 3: Create AL record 2 at the new version.
      # Auto-created embedded DM now uses the new definition version.
      al_v2 = create_al_record(extra_log_type: :versioned_activity)
      set_embedded_dm_field('show1238_embed_versioned_recs', al_v2, 'version two data')

      # Step 4: Navigate fresh so the browser loads template_config for both versions.
      clear_caches_and_navigate

      # Both embeds must appear with their own field labels and values visible.
      # al_v1 resolves to version N   → label 'LabelField1V1234', value 'Version One Data'
      #                                  (requires the plural-alias fix)
      # al_v2 resolves to version N+1 → label 'Embed1238-Two Field', value 'Version Two Data'
      expect(page).to have_text('LabelField1V1234', wait: EmbeddedShowRenderWait)
      expect(page).to have_text('Version One Data')
      expect(page).to have_text('Embed1238-Two Field')
      expect(page).to have_text('Version Two Data')
    end

    # Cross-master switching regression for issue #1238 — the specific edge case
    # around WHEN the per-version template_config aliases are created on demand.
    #
    # Scenario:
    #   1. Master 1 holds an AL whose embedded DM was saved at version N (v1).
    #   2. The DM definition is bumped to version N+1 (v2).
    #   3. Master 2 holds an AL whose embedded DM was saved at the new version N+1.
    #   4. A SINGLE search returns BOTH masters (nav_q_id=m1,m2).
    #   5. Expand master 2 FIRST — this loads template_config for the CURRENT
    #      version (v2) and builds the v(N+1) alias in the browser's JS state.
    #   6. WITHOUT reloading or re-searching, expand master 1 — the OLDER
    #      version (v1) alias must now be created/used on top of the existing
    #      template_config state from master 2.
    #
    # This differs from the same-page coexistence test above: there both blocks
    # are produced by one template_config fetch on one master.  Here the aliases
    # are built incrementally across two separate master expansions in the same
    # SPA session.  If the older-version alias is not created when the base
    # template_config object already exists from the current version, master 1's
    # embedded block is silently absent (the original issue-1238 symptom).
    it 'renders each master\'s embedded item at its own version when switching ' \
       'between masters in one session without reloading' do
      # Master 1: AL + auto-embedded DM at the current version (v1).
      al_m1 = create_al_record(extra_log_type: :versioned_activity)
      set_embedded_dm_field('show1238_embed_versioned_recs', al_m1, 'master one data')

      # Bump the DM definition to v2 (new version-specific field label).
      bump_dm_version('show1238_embed_versioned_recs', 'Embed1238-CrossMaster')

      # Master 2 (a different master record): AL + auto-embedded DM at v2.
      master2, al_m2 = create_master_with_al_record(
        extra_log_type: :versioned_activity, phone: '(516)262-9999', first_name: 'Embed1238b'
      )
      set_embedded_dm_field('show1238_embed_versioned_recs', al_m2, 'master two data')

      # One search returns BOTH masters; expanding each is SPA navigation (no reload).
      Admin::AppConfiguration.clear_memo!
      HandlebarsPrecompiler.cleanup_tmp_dir
      HandlebarsPrecompiler.cleanup_compiled_output
      Rails.cache.delete('server_cache_version')
      visit "/masters/search?utf8=%E2%9C%93&nav_q_id=#{@master.id},#{master2.id}"
      dismiss_modal
      finish_page_loading
      expect(page).to have_css('body.status-compiled', wait: 60)

      # Step 1: Expand master 2 (CURRENT version) FIRST — builds the v2 alias.
      expand_master_record(master_id: master2.id)
      expect(page).to have_css("#master-#{master2.id}-main-container.in", wait: 10)
      expand_master_record_tab('activity_log__player_contact_embed_shows', master_id: master2.id)
      within("#master-#{master2.id}-main-container") do
        expect(page).to have_text('Embed1238-CrossMaster Field', wait: EmbeddedShowRenderWait)
        expect(page).to have_text('Master Two Data')
      end

      # Step 2: WITHOUT reloading, expand master 1 (OLDER version).  The v1 alias
      # must be created/used correctly on top of master 2's existing
      # template_config state — this is the issue-1238 cross-master edge case.
      expand_master_record(master_id: @master.id)
      expect(page).to have_css("#master-#{@master.id}-main-container.in", wait: 10)
      expand_master_record_tab('activity_log__player_contact_embed_shows', master_id: @master.id)
      within("#master-#{@master.id}-main-container") do
        expect(page).to have_text('LabelField1V1234', wait: EmbeddedShowRenderWait)
        expect(page).to have_text('Master One Data')
      end
    end
  end

  # ===================================================================
  # Versioned activity log field labels (definition versioning of the AL itself)
  # ===================================================================
  #
  # The #1238 embedded-DM fix patched the dynamic_models global page template to
  # emit historical versions.  An activity log's OWN field labels resolve through
  # a different, pre-existing path: the per-record `template_config` endpoint
  # renders each record via `oi.versioned_definition` (ActivityLog includes
  # Dynamic::VersionHandler).  This block verifies that path so that AL field
  # label changes between definition versions render correctly in show mode —
  # an older AL record keeps its original field label while a newer record shows
  # the updated label, both visible together in one page load.
  describe 'versioned activity log field labels' do
    it 'shows each activity record\'s field label at its own definition version when versions coexist on the same page' do
      # Version A: set the select_who field label, then create an AL record that
      # is pinned to this version via versioned_definition.
      bump_al_field_label('AlWhoLabelV1')
      al_old = create_al_record(extra_log_type: :versioned_activity)
      set_embedded_dm_field('show1238_embed_versioned_recs', al_old, 'al field old')

      # Version B: change the select_who field label, then create a second AL
      # record that resolves to this newer version.
      bump_al_field_label('AlWhoLabelV2')
      al_new = create_al_record(extra_log_type: :versioned_activity)
      set_embedded_dm_field('show1238_embed_versioned_recs', al_new, 'al field new')

      # Navigate fresh so the browser fetches per-record template_config for both
      # AL records (each carrying its own vdef_version).
      clear_caches_and_navigate

      # Both version-specific field labels must appear together:
      #   al_old → version A label 'AlWhoLabelV1'
      #   al_new → version B label 'AlWhoLabelV2'
      # If AL field-label versioning regressed (analogous to issue #1238) the
      # older record would silently show the current-version label only.
      expect(page).to have_text('AlWhoLabelV1', wait: 60)
      expect(page).to have_text('AlWhoLabelV2')
      expect(page).to have_css('.edit-entity', minimum: 2, wait: 10)
    end
  end

  # ===================================================================
  # Unversioned embedded dynamic model
  # ===================================================================

  describe 'unversioned embedded dynamic model' do
    include_examples 'an embedded activity viewable in show mode',
                     :unversioned_activity, 'show1238_embed_unversioned_recs', 'LabelField1U1234'
  end

  # ===================================================================
  # Single-entry references: referenced item appears embedded in show view
  # ===================================================================

  describe 'single-entry references config' do
    it 'shows the referenced DM item embedded in the activity show view for each AL instance' do
      # Two AL instances each with a single referenced DM (mirrors "add: one_to_this").
      # The references: config causes the linked DM to appear automatically embedded
      # within each AL show block.
      al1 = create_al_record(extra_log_type: :ref_single_activity)
      ref_dm1 = dm_class_for('show1238_ref_single_recs').create!(
        test1: 'ref item alpha',
        test2: 'ref data alpha',
        master: @master,
        current_user: @user
      )
      ModelReference.create_with(al1, ref_dm1)

      al2 = create_al_record(extra_log_type: :ref_single_activity)
      ref_dm2 = dm_class_for('show1238_ref_single_recs').create!(
        test1: 'ref item beta',
        test2: 'ref data beta',
        master: @master,
        current_user: @user
      )
      ModelReference.create_with(al2, ref_dm2)

      navigate_and_expand_al_panel

      # Both referenced DM items must be visible — fields render as
      # "field_name Titleized Value" pairs inline in the AL panel.
      expect(page).to have_text('Ref Item Alpha', wait: EmbeddedShowRenderWait)
      expect(page).to have_text('Ref Item Beta')
      expect(page).to have_css('.edit-entity', minimum: 2, wait: 10)
    end
  end
end
