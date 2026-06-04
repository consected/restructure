# frozen_string_literal: true

require 'rails_helper'

# Tests for ActivityLog::Perspectives::Runner.
#
# Verifies that the runner correctly applies each backend type (where, report,
# conditional_calculation), enforces column-name whitelisting on the where backend
# and on order/limit clauses, raises on configuration errors (so the caller surfaces
# the problem rather than silently showing unfiltered records), and returns nil only
# when a backend legitimately produces no results.
#
# NOTE: report-backend perspectives intentionally bypass per-report UAC because
# the perspective is admin-gated via the page layout and results are always
# re-scoped to @master.id by the final where() clause. A missing UAC entry on the
# backing report must NOT silently bypass the filter.

RSpec.describe ActivityLog::Perspectives::Runner, type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :each do
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @master = @player_contact.master
    @master.current_user = @user

    # Set up access for activity log and create two records for filtering tests
    al_class = ActivityLog::PlayerContactPhone
    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user

    @al1 = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'to player', select_who: 'user', extra_log_type: 'primary', master: @master
    )
    @al2 = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'to staff', select_who: 'user', extra_log_type: 'primary', master: @master
    )
    @al_class = al_class
  end

  # Helper to build a runner with the given config hash
  def build_runner(config)
    ActivityLog::Perspectives::Runner.new(config, @al_class, @user, master: @master)
  end

  describe 'where backend' do
    it 'returns records matching a valid where condition' do
      config = { where: { select_call_direction: 'to player' } }
      result = build_runner(config).run
      expect(result).to be_a ActiveRecord::Relation
      ids = result.pluck(:id)
      expect(ids).to include @al1.id
      expect(ids).not_to include @al2.id
    end

    it 'raises FphsException for where keys that are not valid column names' do
      config = { where: { 'drop table masters;--' => 'x', select_call_direction: 'to staff' } }
      expect { build_runner(config).run }.to raise_error(FphsException, /not a valid column/)
    end

    it 'returns all master records when where hash is empty' do
      config = { where: {} }
      result = build_runner(config).run
      expect(result.pluck(:id)).to include @al1.id, @al2.id
    end

    it 'resolves {{current_user_email}} substitution in a where value' do
      # Store the current user's email on one of the records so a substitution-based
      # where filter can match it.
      @al1.update_column(:select_who, @user.email)
      config = { where: { select_who: '{{current_user_email}}' } }
      result = build_runner(config).run
      expect(result).to be_a ActiveRecord::Relation
      ids = result.pluck(:id)
      expect(ids).to include @al1.id
      expect(ids).not_to include @al2.id
    end
  end

  describe 'no-backend (all) perspective' do
    it 'returns all records for the master when no backend is specified' do
      config = {}
      result = build_runner(config).run
      expect(result).to be_a ActiveRecord::Relation
      expect(result.pluck(:id)).to include @al1.id, @al2.id
    end
  end

  describe 'order modifier' do
    it 'applies a valid order clause' do
      config = { order: { id: 'desc' } }
      result = build_runner(config).run
      ids = result.pluck(:id)
      expect(ids).to eq ids.sort.reverse
    end

    it 'raises FphsException for invalid column names in the order clause' do
      config = { where: {}, order: { 'invalid_column' => 'asc' } }
      expect { build_runner(config).run }.to raise_error(FphsException, /not a valid column/)
    end

    it 'raises FphsException for invalid directions in the order clause' do
      config = { where: {}, order: { id: 'RANDOM()' } }
      expect { build_runner(config).run }.to raise_error(FphsException, /not valid.*use 'asc' or 'desc'/)
    end
  end

  describe 'default ordering (action_when_attribute)' do
    # Make @al1 (smaller id) more recent than @al2 so that action_when_attribute DESC
    # puts al1 first — deliberately opposing the class default_scope "id DESC" (which
    # would put al2 first).  This lets us distinguish the two orderings.
    before :each do
      awa = @al_class.action_when_attribute
      @al1.update_column(awa, 1.day.ago)
      @al2.update_column(awa, 2.days.ago)
    end

    it 'orders by action_when_attribute desc when no order: is configured on a where backend' do
      config = { where: {} }
      result = build_runner(config).run
      ordered_ids = result.pluck(:id)
      # al1 has more-recent action_when_attribute so should appear before al2
      expect(ordered_ids.index(@al1.id)).to be < ordered_ids.index(@al2.id)
    end

    it 'orders by action_when_attribute desc when no order: is configured on the no-backend (all) perspective' do
      config = {}
      result = build_runner(config).run
      ordered_ids = result.pluck(:id)
      expect(ordered_ids.index(@al1.id)).to be < ordered_ids.index(@al2.id)
    end

    it 'orders by action_when_attribute desc when no order: is configured on a conditional_calculation backend' do
      # Both records have select_who: 'user' so this returns both and lets us check ordering.
      calc_conf = {
        @al_class.resource_name.to_s => {
          select_who: 'user',
          return: 'return_all_results'
        }
      }
      config = { conditional_calculation: calc_conf }
      result = build_runner(config).run
      ordered_ids = result.pluck(:id)
      expect(ordered_ids.index(@al1.id)).to be < ordered_ids.index(@al2.id)
    end

    it 'respects an explicit order: that overrides the action_when_attribute default' do
      # order by id ASC — al1 (smaller id, more recent awa) should come first by id too,
      # so use id DESC here to conflict with awa DESC and prove explicit order wins
      config = { where: {}, order: { id: 'desc' } }
      result = build_runner(config).run
      ordered_ids = result.pluck(:id)
      expect(ordered_ids.first).to eq [@al1.id, @al2.id].max
    end
  end

  describe 'limit modifier' do
    it 'applies a positive limit' do
      config = { limit: 1 }
      result = build_runner(config).run
      expect(result.count).to eq 1
    end

    it 'raises FphsException for a zero or non-positive limit' do
      config = { limit: 0 }
      expect { build_runner(config).run }.to raise_error(FphsException, /not a positive integer/)
    end
  end

  describe 'report backend' do
    before :each do
      create_admin
      # Create a report that selects IDs from the activity log table for this master.
      # No UAC grant is needed — perspective runner bypasses per-report access checks.
      al_table = @al_class.table_name
      @al_report_sql = "SELECT id FROM #{al_table} WHERE master_id = :master_id AND select_call_direction = 'to player'"
      @al_report = Report.create!(
        current_admin: @admin,
        name: "Perspective test report #{SecureRandom.hex}",
        sql: @al_report_sql,
        search_attrs: "master_id:\n  integer:\n",
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false
      )
    end

    it 'returns records identified by a report that the user can access' do
      config = { report: { resource_name: @al_report.alt_resource_name } }
      result = build_runner(config).run
      expect(result).to be_a ActiveRecord::Relation
      expect(result.pluck(:id)).to include @al1.id
      expect(result.pluck(:id)).not_to include @al2.id
    end

    it 'returns filtered records when the report SQL has no named params and search_attrs is empty' do
      # This covers the case where the admin writes a plain SQL report (no :master_id bind
      # variable, no search_attrs definition). Previously, run_report_backend always merged
      # master_id: @master.id into defaults, which search_attrs_prep would silently strip
      # (since master_id is not declared), potentially leaving :master_id unbound and causing
      # sanitize_sql_for_conditions to raise PreparedStatementInvalid → the filter was skipped.
      # With the fix, master_id is only injected when search_attrs declares it; the final
      # @al_class.where(master_id:, id:) scope always restricts to the correct master.
      al_table = @al_class.table_name
      plain_sql = "SELECT id FROM #{al_table} WHERE select_call_direction = 'to player'"
      plain_report = Report.create!(
        current_admin: @admin,
        name: "Plain perspective report #{SecureRandom.hex}",
        sql: plain_sql,
        search_attrs: '',
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false
      )
      config = { report: { resource_name: plain_report.alt_resource_name } }
      result = build_runner(config).run
      expect(result).to be_a ActiveRecord::Relation
      expect(result.pluck(:id)).to include @al1.id
      expect(result.pluck(:id)).not_to include @al2.id
    end

    it 'raises when the report does not exist' do
      config = { report: { resource_name: 'nonexistent_perspective_report' } }
      expect { build_runner(config).run }.to raise_error(FphsException)
    end

    it 'still runs successfully even when the user has no explicit UAC grant on the report' do
      # Perspectives bypass per-report access checks: the perspective itself is
      # admin-gated via the page layout and results are always re-scoped to @master.id.
      # A missing UAC entry must NOT silently bypass the filter.
      config = { report: { resource_name: @al_report.alt_resource_name } }
      result = build_runner(config).run
      expect(result).to be_a ActiveRecord::Relation
      expect(result.pluck(:id)).to include @al1.id
    end

    it 'preserves the SQL row order from the report when no order: is configured' do
      # Write a report that returns records ORDER BY id ASC.
      # @al1.id < @al2.id, so ASC order puts al1 first.
      # The class default_scope is "id DESC" (al2 first), so if the runner applies
      # the report's order, al1 must appear before al2.
      al_table = @al_class.table_name
      ordered_sql = "SELECT id FROM #{al_table} WHERE master_id = :master_id ORDER BY id ASC"
      ordered_report = Report.create!(
        current_admin: @admin,
        name: "Ordered perspective report #{SecureRandom.hex}",
        sql: ordered_sql,
        search_attrs: "master_id:\n  integer:\n",
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false
      )
      config = { report: { resource_name: ordered_report.alt_resource_name } }
      result = build_runner(config).run
      ordered_ids = result.pluck(:id)
      expect(ordered_ids.index(@al1.id)).to be < ordered_ids.index(@al2.id)
    end

    it 'explicit order: overrides the report SQL ordering' do
      al_table = @al_class.table_name
      asc_sql = "SELECT id FROM #{al_table} WHERE master_id = :master_id ORDER BY id ASC"
      asc_report = Report.create!(
        current_admin: @admin,
        name: "Asc perspective report #{SecureRandom.hex}",
        sql: asc_sql,
        search_attrs: "master_id:\n  integer:\n",
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false
      )
      # Explicit order: DESC should override the report's ASC
      config = { report: { resource_name: asc_report.alt_resource_name }, order: { id: 'desc' } }
      result = build_runner(config).run
      ordered_ids = result.pluck(:id)
      expect(ordered_ids.index(@al2.id)).to be < ordered_ids.index(@al1.id)
    end

    it 'excludes IDs returned by the report that belong to a different master' do
      # Save the original master before create_item overwrites @player_contact / @master
      original_master = @master

      # Create a second master + player contact and an activity log record on it
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      other_master = @player_contact.master
      other_master.current_user = @user
      al_other = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'to player', select_who: 'user', extra_log_type: 'primary', master: other_master
      )

      # Build a report that returns all "to player" records regardless of master
      al_table = @al_class.table_name
      broad_sql = "SELECT id FROM #{al_table} WHERE select_call_direction = 'to player'"
      broad_report = Report.create!(
        current_admin: @admin,
        name: "Broad perspective test report #{SecureRandom.hex}",
        sql: broad_sql,
        search_attrs: '',
        disabled: false,
        report_type: 'regular_report',
        auto: false,
        searchable: false
      )
      config = { report: { resource_name: broad_report.alt_resource_name } }
      # Run against the original master — only @al1 should be returned
      result = ActivityLog::Perspectives::Runner.new(config, @al_class, @user, master: original_master).run
      # @al1 is on @master — should be included
      expect(result.pluck(:id)).to include @al1.id
      # al_other is on a different master — must NOT be included
      expect(result.pluck(:id)).not_to include al_other.id
    end
  end

  describe 'conditional_calculation backend' do
    # Build a ConditionalActions-compatible config that uses return_all_results
    # to return activity log records where select_call_direction matches direction.
    # Uses the field: value (simple equality) format with return: 'return_all_results'
    # as the return-mode directive at the table level.
    def calc_config_for(direction)
      {
        @al_class.resource_name.to_s => {
          select_call_direction: direction,
          return: 'return_all_results'
        }
      }
    end

    it 'returns records matching the conditional calculation' do
      config = { conditional_calculation: calc_config_for('to player') }
      result = build_runner(config).run
      expect(result).to be_a ActiveRecord::Relation
      expect(result.pluck(:id)).to include @al1.id
      expect(result.pluck(:id)).not_to include @al2.id
    end

    it 'returns only the other record when condition matches the other direction' do
      config = { conditional_calculation: calc_config_for('to staff') }
      result = build_runner(config).run
      expect(result.pluck(:id)).to include @al2.id
      expect(result.pluck(:id)).not_to include @al1.id
    end

    it 'returns nil when no records match (this_val not set)' do
      config = { conditional_calculation: calc_config_for('no such direction') }
      result = build_runner(config).run
      expect(result).to be_nil
    end

    it 'raises on a malformed config' do
      # Pass something that ConditionalActions will fail on without a valid condition
      config = { conditional_calculation: { completely_invalid_table!: { id: { not_a_condition: true } } } }
      expect { build_runner(config).run }.to raise_error(StandardError)
    end

    it 'excludes records belonging to a different master' do
      original_master = @master

      # Create a second master and activity log record on it
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      other_master = @player_contact.master
      other_master.current_user = @user
      al_other = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'to player', select_who: 'user', extra_log_type: 'primary', master: other_master
      )

      # Condition matches 'to player' on any master, but runner must scope to original_master
      config = { conditional_calculation: calc_config_for('to player') }
      result = ActivityLog::Perspectives::Runner.new(config, @al_class, @user, master: original_master).run
      expect(result.pluck(:id)).to include @al1.id
      expect(result.pluck(:id)).not_to include al_other.id
    end
  end
end
