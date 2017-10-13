  class ItemFlag < ActiveRecord::Base

  include WorksWithItem

  belongs_to :item, polymorphic: true, inverse_of: :item_flags
  belongs_to :item_flag_name
  belongs_to :user

  before_validation :prevent_item_change,  on: :update

  # We must have a user set to save a record
  # Since we don't include the UserHandler module, it is necessary for users of this class
  # to explicitly set the user.
  # In future we can consider incorporating this into the UserHandler structure, but currently
  # all UserHandler classes belong directly to a master, and flags only belong to a master indirectly
  # through an item.
  # Since an item_flag entry is only created or deleted (not updated), setting the user explicitly on
  # create is reasonable.

  validates :item, presence: true
  validates :item_flag_name_id, presence: true
  validates :item_flag_name, presence: true

  def user_name
    logger.debug "Getting username for #{self.user} in WorksWithItem"
    return nil unless self.user
    self.user.email
  end

  def self.works_with class_name
    # Get the value from the array and return it, so we can return a value that is not the original passed in (failing Brakeman test otherwise)
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
  # for namespaced models (such as ActivityLog::PlayerContactPhone)
  def self.use_with_class_names
    all_assocs = Master.reflect_on_all_associations(:has_many)
    # Be sure to reject the association on item_flag, since it can't flag itself
    filtered_assocs = all_assocs.select {|v| v.options[:source] != :item_flags}
    # Return a sorted list
    filtered_assocs.collect {|v| v.class_name.ns_underscore}.sort
  end

  # Get only the list of active class names (based on admin item flag name configurations) that
  # are also genuine class names that ItemFlag reports as working with
  def self.active_class_names
    ItemFlagName.active.map(&:item_type).uniq & self.use_with_class_names
  end

  # Create and remove flags for the underlying item.
  # Returns true if flags were added or removed
  def self.set_flags flag_list, item, current_user

    current_flags = item.item_flags.map {|f| f.item_flag_name_id}.uniq
    added_flags = flag_list - current_flags
    removed_flags =  current_flags - flag_list

    logger.info "Current flags #{current_flags} in #{item}"
    logger.info "Removing flags #{removed_flags} from #{item}"
    logger.info "Adding flags #{added_flags} to #{item}"

    item.item_flags.where(item_flag_name_id: removed_flags).each do |i|
        i.disabled = true
        i.save!
    end

    added_flags.each do |f|
      unless f.blank?
        i = item.item_flags.build item_flag_name_id: f, user: current_user
        logger.info "Added flag #{f} to #{item}"
        i.save!
      end
    end

    # Reload the association to have it register the changes
    item.item_flags.reload
    item.master.current_user = current_user

    logger.info "Remaining flags in #{item} for #{item.master_user}: #{item.item_flags.map {|f| f.id}}"
    if added_flags.length > 0 || removed_flags.length > 0
      ItemFlag.track_flag_updates item, added_flags, removed_flags
      update_action = true
    end

    return update_action
  end

  def as_json options={}
    options[:methods] ||= []
    options[:methods] += [:method_id, :item_type_us]
    options[:include] ||=[]
    options[:include] << :item_flag_name
    options[:done] = true
    super(options)
  end

  def self.enable_active_configurations
    active_class_names.each do |ifc|
      add_master_association ifc
    end
  end

  def self.add_master_association ifc
    raise "Invalid item flag type. No class exists for #{ifc}" unless self.active_class_names.include? ifc
    ifcs = ifc.pluralize
    # This association is provided to allow generic search on flagged associated object
    Master.has_many "#{ifcs}_item_flags".to_sym, through: ifcs, source: :item_flags
    logger.debug "Associated master with #{ifcs}_item_flags through #{ifcs} with source :item_flags"
  end

  protected


    def self.track_flag_updates item, added_flags, removed_flags
      logger.info "Track record update for added item_flags #{added_flags} and removed #{removed_flags}"
      Tracker.track_flag_update item, added_flags, removed_flags
    end

    def prevent_item_change
      errors.add :item_flag_name_id, "can not be changed" if item_flag_name_id_changed?
    end

end
