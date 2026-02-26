# frozen_string_literal: true

# Admin::MasterRecord is a read-only presenter that represents one of the standard
# Rails models associated with the masters table (PlayerInfo, ProInfo, etc.).
#
# It is used by the "Master Records" admin page under the Definitions section
# (issue #930) to enumerate, describe and display the core subject models that
# are driven by Settings::Default*TableName constants.
#
# This class is intentionally NOT an ActiveRecord model — it is a plain Ruby
# presenter that wraps an existing AR model class with the metadata needed for
# the admin panel views.
class Admin::MasterRecord
  include ActiveModel::Model
  include ActiveModel::Conversion

  attr_accessor :id, :table_name, :name, :resource_name, :model_class, :description

  # ---------------------------------------------------------------------
  # Class interface
  # ---------------------------------------------------------------------

  # The ordered list including masters table and standard master-associated models.
  # The masters table is first (id: 1), followed by the associated models.
  # The first four associated models are driven by Settings constants so they can be
  # overridden in individual app deployments.
  MASTER_MODEL_TABLE_NAMES = [
    -> { 'masters' },                                 # masters table itself
    -> { Settings::DefaultSubjectInfoTableName },     # player_infos
    -> { Settings::DefaultSecondaryInfoTableName },   # pro_infos
    -> { Settings::DefaultContactInfoTableName },     # player_contacts
    -> { Settings::DefaultAddressInfoTableName },     # addresses
    -> { 'trackers' },
    -> { 'tracker_histories' }
  ].freeze

  MASTER_MODEL_DESCRIPTIONS = [
    'Master records (subjects)',
    'Primary subject information',
    'Secondary subject information',
    'Contact information',
    'Addresses',
    'Trackers / case workflow',
    'Tracker history records'
  ].freeze

  # @return [Array<Admin::MasterRecord>]
  def self.all
    MASTER_MODEL_TABLE_NAMES.each_with_index.map do |table_name_proc, idx|
      table_name = table_name_proc.call
      new(
        id: idx + 1,
        table_name: table_name,
        description: MASTER_MODEL_DESCRIPTIONS[idx]
      )
    end
  end

  # @param id [Integer, String] 1-based position in the list
  # @return [Admin::MasterRecord]
  # @raise [ActiveRecord::RecordNotFound] if id is out of range
  def self.find(id)
    record = all.find { |r| r.id == id.to_i }
    raise ActiveRecord::RecordNotFound, "Master record model #{id} not found" unless record

    record
  end

  # ---------------------------------------------------------------------
  # Instance interface
  # ---------------------------------------------------------------------

  def initialize(attrs = {})
    super
    # Derive name, model_class and resource_name from table_name if not supplied
    @name         ||= @table_name&.humanize&.titleize
    @model_class  ||= derive_model_class
    @resource_name ||= @table_name
  end

  # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
  def fields
    model_class&.columns || []
  end

  # Required by ActiveModel::Conversion so Rails URL helpers treat the object
  # as if it is already persisted (enabling route generation via to_param).
  def persisted?
    true
  end

  def new_record?
    false
  end

  # Used by the UAC and sample form panels to check if the model is available.
  def enabled?
    model_class.present?
  end

  # Return the Rails schema name for the table (from the AR model if available).
  def schema_name
    return nil unless model_class
    return nil unless model_class.respond_to?(:table_name)

    # Standard models live in the ml_app schema in production but AR reports
    # them without schema prefix in most environments — return 'ml_app' as default.
    'ml_app'
  end

  # Shorthand for checking whether model_class is usable.
  def implementation_class_defined?
    model_class.present? && model_class.table_exists?
  rescue StandardError
    false
  end

  # Check if the table/view is ready for API operations.
  # For standard models, this is always true if the model class exists.
  def table_or_view_ready?
    implementation_class_defined?
  end

  # Return the table columns for API field listings.
  # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
  def table_columns
    fields
  end

  # Generate the base route segments for API endpoints.
  # Standard models are nested under /masters/:master_id/
  # @return [String] route segment (e.g., "player_infos")
  def base_route_segments
    table_name
  end

  # Standard models always use master_id as the foreign key.
  # @return [String]
  def foreign_key_name
    'master_id'
  end

  # Get an estimated record count for this model.
  # @return [Integer, nil]
  def est_record_count
    return nil unless model_class&.table_exists?

    model_class.count
  rescue StandardError => e
    Rails.logger.warn "Unable to get count for #{table_name}: #{e.message}"
    nil
  end

  private

  # Derive the Rails AR model class from the table name using Rails conventions.
  # e.g. 'player_infos' → PlayerInfo, 'tracker_histories' → TrackerHistory
  def derive_model_class
    class_name = table_name.to_s.classify
    class_name.constantize
  rescue NameError
    nil
  end
end
