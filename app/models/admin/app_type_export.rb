# frozen_string_literal: true

require_dependency 'zip'

module Admin::AppTypeExport
  extend ActiveSupport::Concern

  AppExportDirSuffix = 'app-export'
  ZipTempFilePrefix = 'app-type-app-export'

  included do
    attr_accessor :import_results
  end

  #
  # Export the configuration as json or yaml
  # Only export if option configs are valid
  # If in the development environment, also export migrations
  # to allow a complete build of an environment to be completed
  def export_config(format: :json)
    force_validations!

    export_migrations if Settings::AllowDynamicMigrations

    case format
    when :json
      JSON.pretty_generate(JSON.parse(to_json))
    when :yaml
      YAML.dump(JSON.parse(to_json))
    end
  end

  # Export the full application definition as JSON
  # if options is set to main_components: true, only the main components
  # are returned (to support the admin panel display)
  def as_json(options = {})
    if options[:main_components]
      main_components = true
      options.delete :main_components
    end

    options[:root] = true
    options[:methods] ||= []
    options[:include] ||= {}

    options[:methods] << :app_configurations
    options[:methods] << :valid_user_access_controls unless main_components
    options[:methods] << :valid_associated_activity_logs
    options[:methods] << :associated_dynamic_models
    options[:methods] << :associated_external_identifiers
    options[:methods] << :associated_reports
    options[:methods] << :associated_general_selections unless main_components
    options[:methods] << :page_layouts
    options[:methods] << :user_roles unless main_components
    options[:methods] << :role_descriptions
    options[:methods] << :associated_message_templates
    options[:methods] << :associated_config_libraries
    options[:methods] << :associated_protocols
    options[:methods] << :associated_sub_processes unless main_components
    options[:methods] << :associated_protocol_events unless main_components
    options[:methods] << :associated_item_flag_names
    options[:methods] << :nfs_store_filters

    super(options)
  end

  # Create a zip file of "<app>--app-export" migration files
  # @return [TempFile] zip file object
  def zip_app_export_migrations
    temp_file = Tempfile.new([ZipTempFilePrefix, '.zip'])
    # This is the tricky part
    # Initialize the temp file as a zip file
    Zip::OutputStream.open(temp_file) { |zos| }

    # Add files to the zip file as usual
    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
      Dir.glob("#{app_export_dir}/*.rb").each do |path|
        filename = path.split('/').last
        zip.add(filename, path)
      end
    end
    temp_file
  end

  #
  # Export migrations to a specific --app-export directory
  # The order of exports is important, since it activity logs
  # can reference other items
  # @return [<Type>] <description>
  def export_migrations
    clean_export_dir
    migration_generator = Admin::MigrationGenerator.new(default_schema_name)
    migration_generator.app_type_name = name
    migration_generator.add_schema AppExportDirSuffix

    associated_dynamic_models.each do |dynamic_def|
      export_migration dynamic_def
    end

    associated_external_identifiers.each do |dynamic_def|
      export_migration dynamic_def
    end

    valid_associated_activity_logs.each do |dynamic_def|
      export_migration dynamic_def
    end
  end

  protected

  #
  # Export an individual dynamic type migration, clearing the
  # export directory if needed
  # @param [DynamicModel | ActivityLog | ExternalIdentifier] dynamic_def
  # @param [String] dir_suffix
  def export_migration(dynamic_def)
    dir_suffix = AppExportDirSuffix
    dynamic_def.current_admin ||= current_admin
    dynamic_def.write_create_or_update_migration dir_suffix, name
  end

  def app_export_dir
    dir_suffix = AppExportDirSuffix
    migration_generator = Admin::MigrationGenerator.new(default_schema_name)
    migration_generator.app_type_name = name
    migration_generator.db_migration_dirname(dir_suffix)
  end

  def clean_export_dir
    @exported_dirnames ||= []

    dir = app_export_dir
    return if dir.in? @exported_dirnames

    # Clean the export directory
    FileUtils.rm_rf dir
    @exported_dirnames << dir
  end

  #
  # Check dynamic types and raise exceptions if there are issues
  def force_validations!
    valid_associated_activity_logs.each(&:force_option_config_parse)
    associated_dynamic_models.each(&:force_option_config_parse)
    associated_external_identifiers.each(&:force_option_config_parse)
  end
end
