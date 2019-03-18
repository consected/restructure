class Classification::GeneralSelection < ActiveRecord::Base
  # Handle general selection functionality, typically for looking up drop-down values from cache

  self.table_name = 'general_selections'

  include AdminHandler
  include SelectorCache
  BasicItemTypes = [:player_infos_source, :player_contacts_type, :player_contacts_source, :addresses_type, :addresses_source, :addresses_rank, :player_contacts_rank]

  default_scope {order  item_type: :asc, disabled: :asc, position: :asc}

  before_validation :prevent_value_change,  on: :update
  validates :name, presence: true
  validates :value, presence: true


  def self.item_types
    BasicItemTypes + Report.item_types + ActivityLog.item_types + DynamicModel.item_types + ExternalIdentifier.item_types
  end

  # Format the item type source string for looking up different selection types from the general_selections table
  def self.item_type_source_for record, type=:source
    unless record.respond_to?(:class) && record.class != Class
      record = record.new
    end
    "#{prefix_name(record)}_#{type}"
  end

  # Get an array of name value pairs for a particular record, and the type of attribute it corresponds to
  def self.item_type_name_value_pair record, type=:source
    src = item_type_source_for record, type
    selector_name_value_pair(item_type: src)
  end

  # Quickly lookup the name for a general_selection record with a specific value, corresponding to a 'record',
  # with the type of attribute it corresponds to
  def self.name_for record, value, type=:source
    res = item_type_name_value_pair record, type

    resn = res.select {|l| l.last.to_s == value.to_s}
    if resn.length >= 1
      return resn.first.first
    end
    return
  end

  # Prefix name for a form field in a record
  # @param record [UserBase] a standard user record, typically a form_object_instance
  # @return [String]
  def self.prefix_name record
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
  def self.exists_for? record, field_name
    item_types.include?("#{prefix_name(record)}_#{field_name}".to_sym)
  end

  def self.selector_with_config_overrides conditions=nil
    res = selector_collection(conditions)
    res = res.to_ary

    implementation_classes = ActivityLog.implementation_classes + DynamicModel.implementation_classes
    implementation_classes.each do |itc|
      next unless itc.definition.ready?

      # if itc == DynamicModel::IpaAdlInformantScreener
      #   byebug
      # end
      ito = itc.new

      it = prefix_name(ito)
      oo = option_overrides ito
      if oo


        oo.each do |fn, fo|
          n = fn
          gsit = "#{it}_#{n}"

          res.reject! {|r| r[:item_type] == gsit}

          o = fo[:edit_as][:alt_options]


          unless o.is_a? Hash
            newo = {}
            o.each do |oi|
              newo[oi] = oi
            end

            o = newo
          end

          o.each do |k, v|

            res << {
              id: nil,
              item_type: gsit,
              name: k,
              value: v,
              create_with: nil,
              edit_if_set: nil,
              edit_always: true,
              lock: nil
            }
          end
        end
      end
    end


    res
  end


  def self.option_overrides item_type_object


    if item_type_object.model_data_type.in?([:activity_log, :dynamic_model])
      fndefs = item_type_object.option_type_config.field_options.select {|fn, f| f[:edit_as] && f[:edit_as][:alt_options] }
      return unless fndefs.length > 0
      return fndefs
    end

    return
  end

  protected

    def prevent_value_change
      if value_changed? && self.persisted?
        errors.add(:value, "change not allowed!")
      end
      if item_type_changed? && self.persisted?
        errors.add(:item_type, "change not allowed!")
      end
    end

end
