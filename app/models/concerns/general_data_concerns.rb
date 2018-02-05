# Primary class from which UserHandler and ActivityLog handler inherit
# It provides the appropriate construction of data structures and JSON results
# to satisfy the requirements of the front end
module GeneralDataConcerns

  # Prevent user from being set directly, to avoid accidental or malicious changes to the recorded user in records
  def user= u
    raise "can not set user="
  end

  def user_id= u
    raise "can not set user_id="
  end


  def check_status
    @was_created = id_changed? ? 'created' : false
    @was_updated = updated_at_changed? ? 'updated' : false
  end

  def can_edit?
    true
  end

  def _created
    @was_created
  end

  def _updated
    @was_updated
  end

  def multiple_results
    @multiple_results ||= []
  end

  def multiple_results=mr
    @multiple_results = mr
  end

  def has_multiple_results
    @multiple_results && @multiple_results.length > 0
  end

  def update_action
    @update_action
  end

  def user_name
    return nil unless self.user
    self.user.email
  end

  def rank_name
    return nil unless respond_to? :rank

    self.class.get_rank_name self.rank
  end

  def source_name
    return nil unless respond_to? :source

    self.class.get_source_name self.source
  end

  # look up the tracker_history items that corresponds
  def tracker_histories
    # Check for the existence of tracker_histories in the super class. If it
    # already exists, it is an association that we should not be overriding
    if defined?(super)
      super
    else
      TrackerHistory.where(item_id: self.id, item_type: self.class.name)
    end
  end

  # look up the tracker_history item that corresponds to the latest tracker entry linked to this item
  def tracker_history
    TrackerHistory.where(item_id: self.id, item_type: self.class.name).order(id: :desc).first
  end

  def tracker_history_id
    th = tracker_history
    return unless th && th.id
    th.id
  end

  def updated_at_ts
    self.updated_at.to_i if self.updated_at
  end

  def created_at_ts
    self.created_at.to_i if self.created_at
  end

  def as_json extras={}

    extras[:include] ||= {}
    extras[:methods] ||= []
    extras[:methods] << :item_id if respond_to? :item_id
    extras[:methods] << :item_type if respond_to? :item_type
    extras[:methods] << :full_item_type if respond_to? :full_item_type
    extras[:methods] << :updated_at_ts if respond_to? :updated_at
    extras[:methods] << :created_at_ts  if respond_to? :created_at
    extras[:methods] << :data if respond_to? :data
    extras[:methods] << :rank_name if respond_to? :rank
    extras[:methods] << :state_name if respond_to? :state
    extras[:methods] << :country_name if respond_to? :country
    extras[:methods] << :source_name if respond_to? :source
    extras[:methods] << :protocol_name if respond_to? :protocol
    extras[:methods] << :sub_process_name if respond_to? :sub_process
    extras[:methods] << :protocol_event_name if respond_to? :protocol_event
    if !self.is_a?(Tracker) && !self.is_a?(TrackerHistory) && (respond_to?(:tracker_history_id) || respond_to?(:tracker_history))
      extras[:methods] << :tracker_history_id
      extras[:methods] << :tracker_histories if respond_to? :tracker_histories
    end
    extras[:methods] << :accuracy_score_name if respond_to? :accuracy_score
    extras[:methods] << :user_name if respond_to? :user_name
    # update_action can be used by requestor to identify whether the record was just updated (saved) or not
    extras[:methods] << :update_action if respond_to? :update_action
    extras[:methods] << :_created if respond_to? :_created
    extras[:methods] << :_updated if respond_to? :_updated

    extras[:include][self.class.parent_type] = {methods: [:rank_name, :data]} if self.class.respond_to? :parent_type
    extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]} if self.class.respond_to?(:uses_item_flags?) && self.class.uses_item_flags?

    super(extras)
  end

end
