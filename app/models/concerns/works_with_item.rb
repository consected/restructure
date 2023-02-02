# frozen_string_literal: true

# Concerns the functionality to support models that work with underlying items,
# such as ItemFlag and the various dynamically generated activity log implementations.
# Generally handles standard naming and user tasks.
# Additionally handles the matching of models to parent items through secondary_key fields,
# which are fields that can be used to join the tables, albeit not necessarily 100% uniquely.
module WorksWithItem
  extend ActiveSupport::Concern

  included do
    validate :works_with
  end

  class_methods do
    def parent_class
      parent_type.to_s.camelize.constantize
    rescue StandardError => e
      msg = "Failed to constantize the parent class #{parent_type} in WorksWithItem #{self}\n#{e}"
      puts msg
      puts e
      # puts e.backtrace.join("\n")
      Rails.logger.error msg
      Rails.logger.info e
      Rails.logger.info e.backtrace.join("\n")
      raise e
    end

    def parent_secondary_key
      parent_class.secondary_key
    end

    # The selection of possible class names that generically could be used with
    def use_with_class_names
      (
        DynamicModel.model_names +
        ExternalIdentifier.model_names +
        ActivityLog.model_names +
        Master::PrimaryAssociations
      ).map { |m| m.to_s.singularize }
    end
  end

  def method_id
    item.master_id
  end

  # used for validation to check this activity log type works with the parent item
  def works_with
    self.class.use_with_class_names.include? item_type
  end

  def parent_class
    self.class.parent_class
  end

  def parent_secondary_key
    parent_class.secondary_key
  end

  def has_matching_secondary_key_field?
    attribute_names.include?(parent_secondary_key.to_s)
  end

  def matching_secondary_key_field
    return parent_secondary_key.to_s if has_matching_secondary_key_field?
  end

  def matching_secondary_key_value
    attributes[parent_secondary_key.to_s]
  end

  # Handle the situation where the association with the parent item has not been made
  # through the standard foreign key (e.g. player_contact_id). Instead we allow matching
  # through the secondary_key (if defined on the parent class), enabling a likely match to
  # be made.
  # In the player_contact / activity_log/player_contact_phone example, the secondary key would be
  # the data field.
  # If the optional current_user is set, then this will be passed the master when found, in preparation
  # for saving the result. If not, it is the caller's responsibility to set the current user in master subsequently.
  # Return: the parent item if a match was made, nil if the value was blank
  # Raise an exception if the secondary key was not found, or was a duplicate
  def match_with_parent_secondary_key(options = {})
    value = matching_secondary_key_value
    return if value.blank?
    # Do we work with parent type? And does the parent_type association return nothing?
    unless self.class.respond_to?(:parent_type)
      raise "match_with_parent_secondary_key does not work with classes that don't have parent_type (#{self.class.name})"
    end
    # Does the parent class have a defined secondary_key field? And does this current model have a matching field to join on?
    unless parent_secondary_key && has_matching_secondary_key_field?
      raise 'match_with_parent_secondary_key must use a parent class with a matching secondary_key field'
    end

    # Is the value of the matching field in this model set? And is that value unique in the parent class's table (it must exist too)?
    self.mark_invalid = true
    unique = parent_class.secondary_key_unique?(value, fail_if_non_existent: true)
    secondary_key = parent_class.secondary_key
    if unique
      matched_item = parent_class.find_by_secondary_key(value)
      matched_item_id = matched_item.id
      # if the item is already set, validate the result matches.
      # if there is already an item set and we have matched with an item with a different master we have a problem
      # otherwise if there is already a master set and the matched item belongs to a different master we have a problem
      if item_id && matched_item_id != item_id
        raise FphsException,
              "Value for #{secondary_key} = \"#{value}\" belongs to a different #{parent_class.human_name} than the value already set"
      elsif respond_to?(:master) && master_id && matched_item.master_id != master_id
        raise FphsException,
              "Value for #{secondary_key} = \"#{value}\" belongs to a #{parent_class.human_name} within a different master record than the value already set"
      end

      # We can match. So find the underlying item and set the real foreign key appropriately
      self.item_id = matched_item_id
      self.master = item.master if respond_to?(:master) && !master
      item.master.current_user = options[:current_user] if options[:current_user]
      self.mark_invalid = false
      item
    elsif unique.nil?
      logger.debug "#{secondary_key} for matching was not found: #{value}"
      raise FphsException, "Value for #{secondary_key} could not be found in #{parent_class.human_name}: #{value}"
    else
      logger.debug "#{secondary_key} for matching is not unique: #{value}"
      raise FphsException,
            "Value for #{secondary_key} = \"#{value}\" has been found in more than one #{parent_class.human_name} record. Update one of these records before continuing."
    end
  end
end
