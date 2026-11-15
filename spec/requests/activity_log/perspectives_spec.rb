# frozen_string_literal: true

# Tests for the activity log perspectives feature (issue #1194).
# Covers:
# - Perspective filtering intersected with User Access Control
# - report: backend perspectives through the full HTTP controller stack, including:
#   - reports that use :master_id named params with matching search_attrs
#   - plain-SQL reports with empty search_attrs (previously failed silently due to
#     master_id being stripped by search_attrs_prep before SQL sanitization)
# - default activity log perspective app config with plain slugs
# - default activity log perspective app config with {{#is}} substitution blocks
#   evaluated against the current user (role-based conditional defaults)

require 'rails_helper'

RSpec.describe 'ActivityLog Perspectives', type: :request do
  include MasterSupport
  include ModelSupport
  include ActivityLogSupport

  before(:all) do
    change_setting('AllowDynamicMigrations', true)
  end

  after(:all) do
    change_setting('AllowDynamicMigrations', false)
  end

  before(:each) do
    @admin = create_admin.first
    @user = create_user.first
    @master = create_master(@user)
    
    @al_def = generate_test_activity_log
    
    @implementation_class = ActivityLog::PlayerContactEmail

    # Set up basic user access to the specific resources
    setup_access :player_contacts, user: @user
    setup_access :activity_log__player_contact_email__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_email__blank_log, resource_type: :activity_log_type, user: @user
  end

  def login_user(user = nil)
    user ||= @user || create_user.first
    sign_out :user
    user.confirmed_at ||= Time.now
    user.current_admin ||= @admin
    user.save
    get '/users/sign_in'
    expect(response.status).to eq 200
    
    # We must actually sign in via Devise or Warden
    sign_in user
  end

  describe 'perspectives with User Access Controls' do
    before(:each) do
      # Create a player contact so the activity log has an item
      @player_contact = PlayerContact.create!(current_user: @user, master: @master, data: 'test@example.com', rec_type: 'email', rank: 10 )

      # Create some logs
      @al1 = @player_contact.activity_log__player_contact_emails.new(select_who: 'subject', extra_log_type: 'primary')
      @al1.master = @master
      @al1.current_user = @user
      @al1.save!
      
      @al2 = @player_contact.activity_log__player_contact_emails.new(select_who: 'agent', extra_log_type: 'primary')
      @al2.master = @master
      @al2.current_user = @user
      @al2.save!
      
      # We create a third one that belongs to an extra log type or something that falls out of UAC
      @al3 = @player_contact.activity_log__player_contact_emails.new(select_who: 'agent', extra_log_type: 'blank_log')
      @al3.master = @master
      @al3.current_user = @user
      @al3.save!

      # A panel layout configuration for perspectives
      options_yaml = <<~YAML
        view_options:
          perspectives:
            activity_log__player_contact_emails:
              - name: who_is_agent
                label: Is Agent
                where: 
                  select_who: agent
      YAML

      @panel = Admin::PageLayout.create!(
        app_type: @user.app_type,
        layout_name: 'test_layout',
        panel_name: 'test_panel',
        panel_label: 'Test Panel',
        current_admin: @admin,
        options: options_yaml
      )

      ActionController::Base.allow_forgery_protection = true
      login_user(@user)
    end

    after(:each) do
      ActionController::Base.allow_forgery_protection = false
    end

    it 'intersects perspective filters with User Access Control constraints' do
      # When no perspective is applied, they see all 3 items via standard UAC
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json"
      expect(response).to have_http_status(:success)
      
      json = JSON.parse(response.body)
      ids = json['activity_log__player_contact_emails'].map { |i| i['id'] }
      expect(ids).to include(@al1.id, @al2.id, @al3.id)
      
      # With perspective applied, they only see matching items
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json", params: { perspective: 'who_is_agent', panel_name: 'test_panel' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      ids = json['activity_log__player_contact_emails'].map { |i| i['id'] }
      expect(ids).not_to include(@al1.id) # 'subject'
      expect(ids).to include(@al2.id, @al3.id) # Both 'agent'
      
      # Now, we change the user's UAC for this specific action to exclude 'extra_log_type: blank_log'
      Admin::UserAccessControl.where(resource_name: 'activity_log__player_contact_email__primary', app_type: @user.app_type).update_all(disabled: true)
      Admin::UserAccessControl.where(resource_name: 'activity_log__player_contact_email__blank_log', app_type: @user.app_type).update_all(disabled: true)
      
      setup_access :activity_log__player_contact_email__primary, resource_type: :activity_log_type, access: :read, user: @user
      uac = Admin::UserAccessControl.last
      uac.update!(
        current_admin: @admin,
        options: {
          filter_if_condition: { # We will remove this and just let the missing 'blank_log' access block it, since it's an extra log type
            note: 'we do not need it now'
          }
        }
      )
      
      # Reload the index
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json"
      json = JSON.parse(response.body)
      ids = json['activity_log__player_contact_emails'].map { |i| i['id'] }
      
      # UAC alone means @al3 should be missing because it lacks access to extra_log_type 'blank_log'
      expect(ids).to include(@al1.id, @al2.id)
      expect(ids).not_to include(@al3.id)
      
      # FINALLY assert the intersection:
      # Applying perspective AND the filtered UAC
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json", params: { perspective: 'who_is_agent', panel_name: 'test_panel' }
      json = JSON.parse(response.body)
      ids = json['activity_log__player_contact_emails'].map { |i| i['id'] }
      
      # Should ONLY contain @al2 ('agent' AND 'extra_log_type: primary')
      expect(ids).not_to include(@al1.id) # Fails perspective ('subject')
      expect(ids).to include(@al2.id)     # Passes both
      expect(ids).not_to include(@al3.id) # Fails UAC ('blank_log')
    end
  end

  describe 'default activity log perspective app config with {{#is}} substitutions' do
    before(:each) do
      @player_contact = PlayerContact.create!(
        current_user: @user, master: @master,
        data: 'sub@example.com', rec_type: 'email', rank: 10
      )

      @al_subject = @player_contact.activity_log__player_contact_emails.new(
        select_who: 'subject', extra_log_type: 'primary'
      )
      @al_subject.master = @master
      @al_subject.current_user = @user
      @al_subject.save!

      @al_agent = @player_contact.activity_log__player_contact_emails.new(
        select_who: 'agent', extra_log_type: 'primary'
      )
      @al_agent.master = @master
      @al_agent.current_user = @user
      @al_agent.save!

      # Panel with two named perspectives
      options_yaml = <<~YAML
        view_options:
          perspectives:
            activity_log__player_contact_emails:
              - name: only_subject
                label: Subject Only
                where:
                  select_who: subject
              - name: only_agent
                label: Agent Only
                where:
                  select_who: agent
      YAML

      @panel = Admin::PageLayout.create!(
        app_type: @user.app_type,
        layout_name: 'test_layout',
        panel_name: 'role_perspective_panel',
        panel_label: 'Role Perspective Panel',
        current_admin: @admin,
        options: options_yaml
      )

      ActionController::Base.allow_forgery_protection = true
    end

    after(:each) do
      ActionController::Base.allow_forgery_protection = false
      Admin::AppConfiguration.remove_default_config @user.app_type, 'default activity log perspective', @admin
    end

    it 'applies a plain slug default perspective from app config' do
      add_app_config @user.app_type, 'default activity log perspective',
                     "activity_log__player_contact_emails: only_agent\n"

      login_user(@user)
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json",
          params: { panel_name: 'role_perspective_panel' }
      expect(response).to have_http_status(:success)

      ids = JSON.parse(response.body)['activity_log__player_contact_emails'].map { |i| i['id'] }
      expect(ids).not_to include(@al_subject.id)
      expect(ids).to include(@al_agent.id)
    end

    it 'resolves an {{#is}} conditional default perspective against the current user role' do
      # Two users with different roles get different default perspectives
      @user_coordinator = create_user.first
      @user_reviewer    = create_user.first
      create_user_role 'coordinator', user: @user_coordinator
      create_user_role 'reviewer',    user: @user_reviewer

      setup_access :player_contacts,                                          user: @user_coordinator
      setup_access :activity_log__player_contact_emails,                     user: @user_coordinator
      setup_access :activity_log__player_contact_email__primary,
                   resource_type: :activity_log_type, user: @user_coordinator
      setup_access :player_contacts,                                          user: @user_reviewer
      setup_access :activity_log__player_contact_emails,                     user: @user_reviewer
      setup_access :activity_log__player_contact_email__primary,
                   resource_type: :activity_log_type, user: @user_reviewer

      conditional_value = <<~YAML
        {{#is role_name '===' 'coordinator'}}only_subject{{else is role_name '===' 'reviewer'}}only_agent{{/is}}
      YAML

      add_app_config @user_coordinator.app_type, 'default activity log perspective',
                     "activity_log__player_contact_emails: |\n  #{conditional_value.strip}\n"

      # Coordinator → only_subject perspective
      login_user(@user_coordinator)
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json",
          params: { panel_name: 'role_perspective_panel' }
      expect(response).to have_http_status(:success)
      ids = JSON.parse(response.body)['activity_log__player_contact_emails'].map { |i| i['id'] }
      expect(ids).to include(@al_subject.id)
      expect(ids).not_to include(@al_agent.id)

      # Reviewer → only_agent perspective
      login_user(@user_reviewer)
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json",
          params: { panel_name: 'role_perspective_panel' }
      expect(response).to have_http_status(:success)
      ids = JSON.parse(response.body)['activity_log__player_contact_emails'].map { |i| i['id'] }
      expect(ids).to include(@al_agent.id)
      expect(ids).not_to include(@al_subject.id)
    end

    it 'falls back to the full list when no {{#is}} branch matches' do
      unmatched_value = "{{#is role_name '===' 'coordinator'}}only_subject{{/is}}"

      add_app_config @user.app_type, 'default activity log perspective',
                     "activity_log__player_contact_emails: |\n  #{unmatched_value}\n"

      # @user has no roles, so no branch matches → blank slug → full list
      login_user(@user)
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json",
          params: { panel_name: 'role_perspective_panel' }
      expect(response).to have_http_status(:success)
      ids = JSON.parse(response.body)['activity_log__player_contact_emails'].map { |i| i['id'] }
      expect(ids).to include(@al_subject.id, @al_agent.id)
    end
  end

  describe 'report backend perspective via HTTP' do
    # Tests that a perspective configured with `report:` backend correctly filters
    # the activity log index response through the full controller stack.
    # Covers both the case where the report SQL uses a :master_id named parameter
    # (with master_id declared in search_attrs) and the case where it does not
    # (plain SQL, empty search_attrs), which previously failed silently.
    before(:each) do
      @player_contact = PlayerContact.create!(
        current_user: @user, master: @master,
        data: 'rpt@example.com', rec_type: 'email', rank: 10
      )

      @al_subject = @player_contact.activity_log__player_contact_emails.new(
        select_who: 'subject', extra_log_type: 'primary'
      )
      @al_subject.master = @master
      @al_subject.current_user = @user
      @al_subject.save!

      @al_agent = @player_contact.activity_log__player_contact_emails.new(
        select_who: 'agent', extra_log_type: 'primary'
      )
      @al_agent.master = @master
      @al_agent.current_user = @user
      @al_agent.save!

      al_table = ActivityLog::PlayerContactEmail.table_name

      # Report A: uses :master_id named param + matching search_attrs
      @report_with_master_id = Report.create!(
        current_admin: @admin,
        name: "Persp request test master_id #{SecureRandom.hex}",
        sql: "SELECT id FROM #{al_table} WHERE master_id = :master_id AND select_who = 'agent'",
        search_attrs: "master_id:\n  integer:\n",
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false
      )
      Admin::UserAccessControl.create!(
        app_type: @user.app_type, access: :read, resource_type: :report,
        resource_name: @report_with_master_id.alt_resource_name, current_admin: @admin
      )

      # Report B: plain SQL, no named params, empty search_attrs
      @report_plain_sql = Report.create!(
        current_admin: @admin,
        name: "Persp request test plain_sql #{SecureRandom.hex}",
        sql: "SELECT id FROM #{al_table} WHERE select_who = 'agent'",
        search_attrs: '',
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false
      )
      Admin::UserAccessControl.create!(
        app_type: @user.app_type, access: :read, resource_type: :report,
        resource_name: @report_plain_sql.alt_resource_name, current_admin: @admin
      )

      ActionController::Base.allow_forgery_protection = true
      login_user(@user)
    end

    after(:each) do
      ActionController::Base.allow_forgery_protection = false
    end

    shared_examples 'filters to agent records via report backend' do |panel_name_key|
      it 'returns only records matching the report filter' do
        options_yaml = <<~YAML
          view_options:
            perspectives:
              activity_log__player_contact_emails:
                - name: only_agent
                  label: Agent Only
                  report:
                    resource_name: #{report_resource_name}
        YAML
        panel = Admin::PageLayout.create!(
          app_type: @user.app_type,
          layout_name: 'test_layout',
          panel_name: panel_name_key,
          panel_label: 'Report Perspective Panel',
          current_admin: @admin,
          options: options_yaml
        )

        get "/masters/#{@master.id}/activity_log/player_contact_emails.json",
            params: { perspective: 'only_agent', panel_name: panel_name_key }
        expect(response).to have_http_status(:success)

        ids = JSON.parse(response.body)['activity_log__player_contact_emails'].map { |i| i['id'] }
        expect(ids).to include(@al_agent.id)
        expect(ids).not_to include(@al_subject.id)
      ensure
        panel&.update!(current_admin: @admin, disabled: true)
      end
    end

    context 'with a report that uses :master_id named param (search_attrs defines master_id)' do
      let(:report_resource_name) { @report_with_master_id.alt_resource_name }

      include_examples 'filters to agent records via report backend', 'report_persp_panel_named'
    end

    context 'with a plain-SQL report (no named params, empty search_attrs)' do
      let(:report_resource_name) { @report_plain_sql.alt_resource_name }

      include_examples 'filters to agent records via report backend', 'report_persp_panel_plain'
    end
  end

  describe 'showable_if filtering applied to where: perspective results' do
    # Verifies that records returned by a where: perspective that are hidden by
    # showable_if in the extra log type config are excluded from the final response.
    # The where: backend may return records that pass the column filter but should
    # not be visible — showable_if must still be enforced on perspective results.

    before(:each) do
      @player_contact = PlayerContact.create!(
        current_user: @user, master: @master,
        data: 'showable@example.com', rec_type: 'email', rank: 10
      )

      # Both records pass the where: filter (extra_log_type: primary).
      # showable_if will hide the 'agent' one; only the 'subject' one should appear.
      @al_visible = @player_contact.activity_log__player_contact_emails.new(
        select_who: 'subject', extra_log_type: 'primary'
      )
      @al_visible.master = @master
      @al_visible.current_user = @user
      @al_visible.save!

      @al_hidden = @player_contact.activity_log__player_contact_emails.new(
        select_who: 'agent', extra_log_type: 'primary'
      )
      @al_hidden.master = @master
      @al_hidden.current_user = @user
      @al_hidden.save!

      # Configure showable_if on the 'primary' extra log type to hide records
      # where select_who != 'subject'.
      @al_def.extra_log_types = <<~YAML
        primary:
          label: Primary
          fields:
            - select_who
          showable_if:
            all:
              this:
                select_who: subject
        blank_log:
          label: Blank Log
          fields:
            - select_who
      YAML
      @al_def.current_admin = @admin
      @al_def.updated_at = DateTime.now
      @al_def.save!

      @panel = Admin::PageLayout.create!(
        app_type: @user.app_type,
        layout_name: 'test_layout',
        panel_name: 'showable_panel',
        panel_label: 'Showable Panel',
        current_admin: @admin,
        options: <<~YAML
          view_options:
            perspectives:
              activity_log__player_contact_emails:
                - name: all_primary
                  label: All Primary
                  where:
                    extra_log_type: primary
        YAML
      )

      ActionController::Base.allow_forgery_protection = true
      login_user(@user)
    end

    after(:each) do
      ActionController::Base.allow_forgery_protection = false
    end

    it 'excludes records hidden by showable_if even when they pass the where: filter' do
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json",
          params: { perspective: 'all_primary', panel_name: 'showable_panel' }

      expect(response).to have_http_status(:success)
      ids = JSON.parse(response.body)['activity_log__player_contact_emails'].map { |i| i['id'] }

      # @al_visible passes both the where: filter and showable_if → present
      expect(ids).to include(@al_visible.id)
      # @al_hidden passes the where: filter but is blocked by showable_if → absent
      expect(ids).not_to include(@al_hidden.id)
    end

    it 'returns only showable records without a perspective (behaviour is consistent)' do
      # Without a perspective the normal index also applies showable_if, confirming
      # the behaviour is consistent regardless of whether a perspective is active.
      get "/masters/#{@master.id}/activity_log/player_contact_emails.json"

      expect(response).to have_http_status(:success)
      ids = JSON.parse(response.body)['activity_log__player_contact_emails'].map { |i| i['id'] }

      expect(ids).to include(@al_visible.id)
      expect(ids).not_to include(@al_hidden.id)
    end
  end
end
