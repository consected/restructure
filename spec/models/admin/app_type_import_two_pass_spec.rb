# frozen_string_literal: true

require 'rails_helper'

# Covers dependent dynamic definitions, genuine failures, and retry behavior during app type imports.
RSpec.describe Admin::AppTypeImport, type: :model do
  include ModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    @failed_migration_files_before = Dir.glob(Rails.root.join(Admin::MigrationConnection.db_migration_failed_dirname, '*.rb'))
    Seeds.setup
    create_admin
    connection = ActiveRecord::Base.connection
    @original_search_path = connection.schema_search_path
    @schema_names = Array.new(6) { "two_pass_#{SecureRandom.hex(4)}" }
    @generated_schema_names = @schema_names.dup
    @generated_schema_names.each { |schema_name| connection.execute("CREATE SCHEMA #{schema_name}") }
    connection.schema_search_path = [*@generated_schema_names, @original_search_path].join(',')
  end

  after :all do
    SetupHelper.cleanup_migrations(*@generated_schema_names)
    failed_migration_files = Dir.glob(Rails.root.join(Admin::MigrationConnection.db_migration_failed_dirname, '*.rb'))
    FileUtils.rm_f(failed_migration_files - @failed_migration_files_before)
    connection = ActiveRecord::Base.connection
    connection.schema_search_path = @original_search_path
    @generated_schema_names.each { |schema_name| connection.execute("DROP SCHEMA IF EXISTS #{schema_name} CASCADE") }
    change_setting('AllowDynamicMigrations', false)
  end

  before do
    @schema_name = @schema_names.shift
    connection = ActiveRecord::Base.connection
    connection.schema_search_path = [@schema_name, *@generated_schema_names.reject { |name| name == @schema_name }, @original_search_path].join(',')
  end

  # These examples make generated migrations fail on purpose. In specs, migrations run inline on the pinned
  # connection, where a failure aborts the transaction before Rails can release its session-level migration
  # advisory lock. Release it so later migrations on other connections are not blocked.
  after do
    ActiveRecord::Base.connection.execute('SELECT pg_advisory_unlock_all()')
  end

  it 'imports a dynamic model view in one import when its activity log is defined later' do
    suffix = "t#{SecureRandom.hex(4)}"
    app_name = new_app_name
    activity_log = activity_log_definition(process_name: "view_source_#{suffix}")
    view_table = "two_pass_view_#{suffix}s"
    dynamic_model = dynamic_model_definition(
      table_name: view_table,
      options: view_options(activity_log_table_name(activity_log[:process_name]))
    )

    app_type, results = import_definitions(
      app_name,
      dynamic_models: [dynamic_model],
      activity_logs: [activity_log],
      skip_fail: false,
      force_update: nil
    )

    expect(app_type).to be_a(Admin::AppType)
    expect(results).to be_a(Hash)
    expect(results).not_to have_key('failures')
    expect(relation_exists?(activity_log_table_name(activity_log[:process_name]))).to be(true)
    expect(relation_exists?(view_table)).to be(true)

    imported_model = DynamicModel.find_by!(table_name: view_table)
    expect(DynamicModel.const_defined?(imported_model.model_class_name, false)).to be(true)
  end

  it 'retries a chain of dynamic model views until their dependencies are ready' do
    suffix = "t#{SecureRandom.hex(4)}"
    app_name = new_app_name
    activity_log = activity_log_definition(
      process_name: "chain_source_#{suffix}",
      updated_at: '2024-01-03T00:00:00Z'
    )
    model_a_table = "two_pass_chain_a_#{suffix}s"
    model_b_table = "two_pass_chain_b_#{suffix}s"
    model_a = dynamic_model_definition(
      table_name: model_a_table,
      options: view_options(model_b_table),
      updated_at: '2024-01-01T00:00:00Z'
    )
    model_b = dynamic_model_definition(
      table_name: model_b_table,
      options: view_options(activity_log_table_name(activity_log[:process_name])),
      updated_at: '2024-01-02T00:00:00Z'
    )

    app_type, results = import_definitions(
      app_name,
      dynamic_models: [model_a, model_b],
      activity_logs: [activity_log],
      skip_fail: false,
      force_update: nil
    )

    expect(app_type).to be_a(Admin::AppType)
    expect(results).not_to have_key('failures')
    expect(relation_exists?(activity_log_table_name(activity_log[:process_name]))).to be(true)
    expect(relation_exists?(model_b_table)).to be(true)
    expect(relation_exists?(model_a_table)).to be(true)
  end

  it 'creates reference views for earlier activity logs after later referenced logs are imported' do
    suffix = "t#{SecureRandom.hex(4)}"
    app_name = new_app_name
    target_process = "reference_target_#{suffix}"
    source_process = "reference_source_#{suffix}"
    target_resource = "activity_log__#{ActivityLog.item_type_name('player_contact', target_process, nil)}"
    source = activity_log_definition(
      process_name: source_process,
      updated_at: '2024-01-01T00:00:00Z',
      extra_log_types: <<~YAML
        event:
          label: Source event
          fields:
            - notes
          references:
            #{target_resource}:
              from: this
              add: many
      YAML
    )
    target = activity_log_definition(
      process_name: target_process,
      updated_at: '2024-01-02T00:00:00Z'
    )

    app_type, results = import_definitions(
      app_name,
      activity_logs: [source, target],
      skip_fail: false,
      force_update: nil
    )

    expect(app_type).to be_a(Admin::AppType)
    expect(results).not_to have_key('failures')
    activity_log_entries = results.dig('updates / creations', 'valid_associated_activity_logs')
    activity_log_ids = activity_log_entries.map { |entry| entry.respond_to?(:id) ? entry.id : entry['id'] }.compact
    expect(activity_log_ids.uniq).to eq(activity_log_ids)

    reference_view = Admin::MigrationGenerator.reference_view_name(
      activity_log_table_name(source_process),
      activity_log_table_name(target_process)
    )
    expect(relation_exists?(reference_view)).to be(true)
  end

  it 'raises on a genuine definition error in both passes and rolls back other definitions' do
    suffix = "t#{SecureRandom.hex(4)}"
    app_name = new_app_name
    invalid_process = "invalid_item_#{suffix}"
    valid_process = "rollback_valid_#{suffix}"
    invalid_item_type = "missing_item_#{suffix}"
    invalid_log = activity_log_definition(
      process_name: invalid_process,
      item_type: invalid_item_type,
      updated_at: '2024-01-01T00:00:00Z'
    )
    valid_log = activity_log_definition(
      process_name: valid_process,
      updated_at: '2024-01-02T00:00:00Z'
    )

    result, error = import_definitions(
      app_name,
      activity_logs: [invalid_log, valid_log],
      skip_fail: false,
      force_update: nil
    )

    expect(result).to be_a(Admin::AppTypeImport)
    expect(error).to be_a(StandardError)
    expect(error.message).to include(invalid_item_type)
    expect(ActivityLog.exists?(process_name: invalid_process)).to be(false)
    expect(ActivityLog.exists?(process_name: valid_process)).to be(false)
  end

  it 'reports a genuine failure once when skip_fail is enabled and imports other definitions' do
    suffix = "t#{SecureRandom.hex(4)}"
    app_name = new_app_name
    invalid_process = "skip_fail_invalid_#{suffix}"
    valid_process = "skip_fail_valid_#{suffix}"
    invalid_log = activity_log_definition(
      process_name: invalid_process,
      item_type: "missing_item_#{suffix}",
      updated_at: '2024-01-01T00:00:00Z'
    )
    valid_log = activity_log_definition(
      process_name: valid_process,
      updated_at: '2024-01-02T00:00:00Z'
    )

    app_type, results = import_definitions(
      app_name,
      activity_logs: [invalid_log, valid_log],
      skip_fail: true,
      force_update: nil
    )

    expect(app_type).to be_a(Admin::AppType), results.inspect
    failures = results.dig('failures', 'valid_associated_activity_logs')
    expect(failures).to contain_exactly(include('exception!'))
    expect(ActivityLog.exists?(process_name: valid_process)).to be(true)
    expect(ActivityLog.exists?(process_name: invalid_process)).to be(false)
  end

  it 'does not retry unchanged definitions on a subsequent import or duplicate result entries' do
    suffix = "t#{SecureRandom.hex(4)}"
    app_name = new_app_name
    activity_log = activity_log_definition(process_name: "unchanged_source_#{suffix}")
    view_table = "two_pass_unchanged_#{suffix}s"
    dynamic_model = dynamic_model_definition(
      table_name: view_table,
      options: view_options(activity_log_table_name(activity_log[:process_name]))
    )
    config = definitions_config(app_name, dynamic_models: [dynamic_model], activity_logs: [activity_log])

    first_app_type, first_results = Admin::AppTypeImport.import_config(
      config, @admin, format: :raw, skip_fail: false, force_update: nil
    )
    expect(first_app_type).to be_a(Admin::AppType)

    retry_calls = []
    allow_any_instance_of(Admin::AppTypeImport).to receive(:create_or_update).and_wrap_original do |original, *args, **kwargs|
      retry_calls << original.receiver.current_key if original.receiver.dynamic_definition_retries&.pass == :retry
      original.call(*args, **kwargs)
    end

    second_app_type, second_results = Admin::AppTypeImport.import_config(
      config, @admin, format: :raw, skip_fail: false, force_update: nil
    )

    expect(second_app_type.id).to eq(first_app_type.id)
    expect(retry_calls).to be_empty
    %w[associated_dynamic_models valid_associated_activity_logs].each do |key|
      entries = second_results.fetch('updates / creations').fetch(key)
      expect(entries).to be_empty
      ids = entries.map { |entry| entry['id'] }
      expect(ids.uniq).to eq(ids)
      entries = first_results.fetch('updates / creations').fetch(key)
      ids = entries.map { |entry| entry['id'] }
      expect(ids.uniq).to eq(ids)
    end
  end

  def new_app_name
    "import_two_pass_#{SecureRandom.hex(5)}"
  end

  def import_definitions(app_name, dynamic_models: [], activity_logs: [], **)
    config = definitions_config(app_name, dynamic_models:, activity_logs:)
    Admin::AppTypeImport.import_config(config, @admin, format: :raw, **)
  end

  def definitions_config(app_name, dynamic_models:, activity_logs:)
    {
      app_type: {
        name: app_name,
        label: app_name.humanize,
        default_schema_name: @schema_name,
        associated_dynamic_models: dynamic_models,
        valid_associated_activity_logs: activity_logs
      }
    }
  end

  def dynamic_model_definition(table_name:, options:, updated_at: '2024-01-01T00:00:00Z')
    {
      name: table_name.humanize,
      table_name:,
      schema_name: @schema_name,
      primary_key_name: 'id',
      foreign_key_name: 'master_id',
      field_list: 'master_id',
      category: 'test',
      options:,
      updated_at:
    }
  end

  def activity_log_definition(process_name:, item_type: 'player_contact', updated_at: '2024-01-01T00:00:00Z', extra_log_types: nil)
    {
      name: "Two pass #{process_name.humanize}",
      item_type:,
      process_name:,
      schema_name: @schema_name,
      category: 'test',
      action_when_attribute: 'created_at',
      extra_log_types: extra_log_types || <<~YAML,
        event:
          label: Test event
          fields:
            - notes
      YAML
      updated_at:
    }
  end

  def activity_log_table_name(process_name)
    ActivityLog.new(item_type: 'player_contact', process_name:).generate_table_name
  end

  def view_options(source_table)
    <<~YAML
      _configurations:
        view_sql: |
          SELECT id, master_id, created_at
          FROM #{@schema_name}.#{source_table}
    YAML
  end

  def relation_exists?(table_name)
    connection = ActiveRecord::Base.connection
    connection.select_value("SELECT to_regclass(#{connection.quote("#{@schema_name}.#{table_name}")}) IS NOT NULL")
  end
end
