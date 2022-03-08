# frozen_string_literal: true

class Classification::GeneralSelection < ActiveRecord::Base
  # Handle general selection functionality, typically for looking up drop-down values from cache

  self.table_name = 'general_selections'

  include AdminHandler
  include SelectorCache
  BasicItemTypes = %i[player_infos_source
                      player_contacts_type player_contacts_source player_contacts_rank
                      addresses_type addresses_source addresses_rank].freeze

  default_scope { order Arel.sql('item_type asc, coalesce(disabled, false) asc, coalesce(position, 0) asc, name asc') }

  before_validation :prevent_value_change, on: :update
  before_validation :downcase_value
  validates :name, presence: true
  validates :value, presence: true
  validate :not_duplicated

  def self.item_types(refresh: false)
    if refresh
      Rails.cache.delete('Classification::GeneralSelection.item_types')
      Classification::SelectionOptionsHandler.reset!
    end
    Rails.cache.fetch('Classification::GeneralSelection.item_types') do
      BasicItemTypes +
        Report.item_types(refresh: refresh) +
        ActivityLog.item_types(refresh: refresh) +
        DynamicModel.item_types(refresh: refresh) +
        ExternalIdentifier.item_types(refresh: refresh)
    end
  end

  # Format the item type source string for looking up different selection types from the general_selections table
  def self.item_type_source_for(record, type = :source)
    record = record.new unless record.respond_to?(:class) && record.class != Class
    "#{prefix_name(record)}_#{type}"
  end

  # Get an array of name value pairs for a particular record, and the type of attribute it corresponds to
  def self.item_type_name_value_pair(record, type = :source)
    src = item_type_source_for record, type
    selector_name_value_pair(item_type: src)
  end

  # Quickly lookup the name for a general_selection record with a specific value, corresponding to a 'record',
  # with the type of attribute it corresponds to
  def self.name_for(record, value, type = :source)
    res = item_type_name_value_pair record, type

    resn = res.select { |l| l.last.to_s == value.to_s }
    return resn.first.first if resn.length >= 1

    nil
  end

  # Prefix name for a form field in a record
  # @param record [UserBase] a standard user record, typically a form_object_instance
  # @return [String]
  def self.prefix_name(record)
    if record.model_data_type == :activity_log
      record.item_type_us
    elsif record.model_data_type == :report
      "report_#{record.definition.name.id_underscore}"
    else
      record.item_type_us.pluralize
    end
  end

  # Quick check if a field in a record is a general selection type
  # @param record [UserBase] a standard UserBase instance, typically a form_object_instance in a view
  # @param field_name [String | Symbol] field name to check
  # @return [Boolean]
  def self.exists_for?(record, field_name)
    item_types.include?("#{prefix_name(record)}_#{field_name}".to_sym)
  end

  #
  # Check if an attribute can have general selection entries added
  # This is based on the attribute names
  # @param [String] attr is the attribute name
  # @return [Boolean]
  def self.use_with_attribute?(attr)
    !attr.in?(%w[disabled user_id created_at updated_at]) && (
      attr.start_with?('select_') ||
      attr.start_with?('multi_') ||
      attr.start_with?('tag_select_') ||
      attr.end_with?('_selection') ||
      attr.in?(%w[source rec_type rank])
    )
  end

  #
  # @see Classification::SelectionOptionsHandler.selector_with_config_overrides
  # This pass through method has been kept, to enable the DefinitionsController to work
  def self.selector_with_config_overrides(conditions = nil)
    Classification::SelectionOptionsHandler.selector_with_config_overrides(conditions)
  end

  protected

  def prevent_value_change
    if value_changed? && persisted?
      errors.add(:value, 'change not allowed!')
      # throw(:abort)

    end
    if item_type_changed? && persisted?
      errors.add(:item_type, 'change not allowed!')
      # throw(:abort)
    end
  end

  private

  def not_duplicated
    return true if disabled?

    if already_taken(:item_type, :value)
      errors.add :duplicated, "existing general selection with item type #{item_type} and value #{value}"
    end

    true
  end

  def downcase_value
    self.value = value&.downcase
  end
end
