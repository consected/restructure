# Concerns the functionality to support models that work with underlying items,
# such as ItemFlag and the various dynamically generated activity log implementations.
# Generally handles standard naming and user tasks.
# Additionally handles the matching of models to parent items through secondary_key fields,
# which are fields that can be used to join the tables, albeit not necessarily 100% uniquely.
module WorksWithItem

  extend ActiveSupport::Concern

  included do

    validate :works_with
    default_scope -> {where "disabled is null or disabled = false"}

  end

  class_methods do

    def parent_class
      parent_type.to_s.camelize.constantize
    end

    def parent_secondary_key
      parent_class.secondary_key
    end

  end


  def method_id
    self.item.master_id
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
    self.attribute_names.include?(parent_secondary_key.to_s)
  end

  def matching_secondary_key_field
    return parent_secondary_key.to_s if has_matching_secondary_key_field?
  end

  def matching_secondary_key_value
    self.attributes[parent_secondary_key.to_s]
  end

  # Handle the situation where the association with the parent item has not been made
  # through the standard foreign key (e.g. player_contact_id). Instead we allow matching
  # through the secondary_key (if defined on the parent class), enabling a likely match to
  # be made.
  # If the optional current_user is set, then this will be passed the master when found, in preparation
  # for saving the result. If not, it is the caller's responsibility to set the current user in master subsequently.
  # Return: the parent item if a match was made, nil otherwise
  def match_with_parent_secondary_key options={}
    return if self.master || self.item
    # Do we work with parent type? And does the parent_type association return nothing?
    raise "match_with_parent_secondary_key does not work with classes that don't have parent_type" unless self.class.respond_to?(:parent_type) && !self.send(self.class.parent_type)
    # Does the parent class have a defined secondary_key field? And does this current model have a matching field to join on?
    raise "match_with_parent_secondary_key must use a parent class with a matching secondary_key field" unless parent_secondary_key && has_matching_secondary_key_field?
    # Is the value of the matching field in this model set? And is that value unique in the parent class's table (it must exist too)?
    value = matching_secondary_key_value
    if value && parent_class.secondary_key_unique?(value, fail_if_non_existent: true)
      # We can match. So find the underlying item and set the real foreign key appropriately
      self.item_id = parent_class.find_by_secondary_key(value).id
      item.master.current_user = options[:current_user] if options[:current_user]
      return self.item
    end
    return nil
  end


end
