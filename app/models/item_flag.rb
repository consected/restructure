# frozen_string_literal: true

class ItemFlag < UserBase
  include WorksWithItem

  belongs_to :item, polymorphic: true, inverse_of: :item_flags
  belongs_to :item_flag_name, class_name: 'Classification::ItemFlagName'
  belongs_to :user

  before_validation :prevent_item_change, on: :update

  # We must have a user set to save a record
  # Since we don't include the UserHandler module, it is necessary for users of this class
  # to explicitly set the user.
  # In future we can consider incorporating this into the UserHandler structure, but currently
  # all UserHandler classes belong directly to a master, and flags only belong to a master indirectly
  # through an item.
  # Since an item_flag entry is only created or deleted (not updated), setting the user explicitly on
  # create is reasonable.

  validates :item, presence: true

  # The Item Flag Name validations should not be seen in normal operation
  # These indicate that ItemFlag records have been entered into the database
  # through an external process with item_flag_name NULL.
  # In January 2021 a database constrain was added to prevent records
  # with NULL values being inserted / updated.
  validates :item_flag_name_id, presence: true
  validates :item_flag_name, presence: true

  default_scope -> { where disabled: [nil, false] }

  def user_name
    return nil unless user

    user.email
  end

  # Is this class_name one of the possible classes ItemFlag can work with, independent of whether
  # the admin configuration is actually created or enabled for it
  def self.works_with(class_name)
    # Get the value from the array and return it, so we can return a value that is not
    # the original passed in (failing Brakeman test otherwise)
    pos = use_with_class_names.index(class_name.ns_underscore)
    if pos
      use_with_class_names[pos.to_i].ns_camelize
    else
      logger.warn "Expected #{class_name.ns_underscore} to match an item in #{use_with_class_names}"
      nil
    end
  end

  # The full list of model names that ItemFlag can work with.
  # The result is simply downcased for simple models and fully module/class qualified
  # for namespaced models
  # For example activity_log__player_contact_phone for ActivityLog::PlayerContactPhone
  # @return [Array{String}]
  def self.use_with_class_names
    all_assocs = Master.reflect_on_all_associations(:has_many)
    # Be sure to reject the association on item_flag, since it can't flag itself
    filtered_assocs = all_assocs.reject { |v| v.options[:source] == :item_flags }
    # Return a sorted list
    filtered_assocs.collect { |v| v.class_name.ns_underscore }.sort
  end

  # Get only the list of active class names (based on admin item flag name configurations) that
  # are also genuine class names that ItemFlag reports as working with
  def self.active_class_names
    Classification::ItemFlagName.active.map(&:item_type).uniq & use_with_class_names
  end

  def self.active_resource_names
    active_class_names.map { |ifcs| "#{ifcs.pluralize}_item_flags" }
  end

  def self.active_for?(class_or_class_name)
    return unless class_or_class_name

    class_name = if class_or_class_name.is_a? Class
                   class_or_class_name.name.ns_underscore
                 else
                   class_or_class_name
                 end
    active_class_names.include? class_name.ns_underscore
  end

  # Create and remove flags for the underlying item.
  # Returns true if flags were added or removed
  def self.set_flags(flag_list, item, current_user, force_save: nil)
    current_flags = item.item_flags.map(&:item_flag_name_id).uniq
    added_flags = flag_list - current_flags
    removed_flags = current_flags - flag_list

    logger.info "Current flags #{current_flags} in #{item}"
    logger.info "Removing flags #{removed_flags} from #{item}"
    logger.info "Adding flags #{added_flags} to #{item}"

    item.item_flags.where(item_flag_name_id: removed_flags).each do |i|
      i.force_save! if force_save
      i.disabled = true
      i.save!
    end

    added_flags.each do |f|
      next if f.blank?

      i = item.item_flags.build item_flag_name_id: f, user: current_user
      i.force_save! if force_save
      logger.info "Added flag #{f} to #{item}"
      i.save!
    end

    # Reload the association to have it register the changes
    item.item_flags.reload
    item.master.current_user = current_user

    logger.info "Remaining flags in #{item} for #{item.master_user}: #{item.item_flags.map(&:id)}"
    if !added_flags.empty? || !removed_flags.empty?
      track_flag_updates item, added_flags, removed_flags
      update_action = true
    end

    update_action
  end

  def as_json(options = {})
    options[:methods] ||= []
    options[:methods] += %i[method_id item_type_us]
    options[:include] ||= []
    options[:include] << :item_flag_name
    options[:done] = true
    super(options)
  end

  def self.enable_active_configurations
    active_class_names.each do |ifc|
      add_master_association ifc
    end
  end

  def self.add_master_association(ifc)
    raise "Invalid item flag type. No class exists for #{ifc}" unless active_class_names.include? ifc

    ifcs = ifc.pluralize
    # This association is provided to allow generic search on flagged associated object
    Master.has_many "#{ifcs}_item_flags".to_sym, through: ifcs, source: :item_flags
  end

  def self.track_flag_updates(item, added_flags, removed_flags)
    logger.info "Track record update for added item_flags #{added_flags} and removed #{removed_flags}"
    Tracker.track_flag_update item, added_flags, removed_flags
  end

  protected

  def prevent_item_change
    errors.add :item_flag_name_id, 'can not be changed' if item_flag_name_id_changed?
  end
end
