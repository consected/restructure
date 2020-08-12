# frozen_string_literal: true

# Primary class from which UserHandler and ActivityLog handler inherit
# It provides the appropriate construction of data structures and JSON results
# to satisfy the requirements of the front end
module GeneralDataConcerns
  #
  # Prevent user from being set directly, to avoid accidental or malicious changes to the recorded user in records
  def user=(_u)
    raise 'can not set user='
  end

  #
  # Prevent user from being set directly, to avoid accidental or malicious changes to the recorded user in records
  def user_id=(_u)
    raise 'can not set user_id=' if attribute_names.include?('master_id')
  end

  def check_status
    @was_created = respond_to?(:id) && saved_change_to_id? ? 'created' : false

    # If an embedded_item is present and it was updated, allow that to set @was_updated.
    # Just changing the updated_at attribute on self (with #touch) is not registered as a change.
    @was_updated = if respond_to?(:updated_at) &&
                      (saved_change_to_updated_at? || embedded_item&.saved_change_to_updated_at?)
                     'updated'
                   else
                     false
                   end

    @was_disabled = respond_to?(:disabled) && saved_change_to_disabled? && disabled ? 'disabled' : false
  end

  def _created
    @was_created
  end

  def _updated
    @was_updated
  end

  def _disabled
    @was_disabled
  end

  def multiple_results
    @multiple_results ||= []
  end

  def multiple_results=(mr)
    @multiple_results = mr
  end

  def has_multiple_results
    @multiple_results && !@multiple_results.empty?
  end

  def update_action
    @update_action
  end

  def user_name
    return nil unless user

    user.email
  end

  def user_email
    user_name
  end

  def created_by_user_name
    return nil unless respond_to?(:created_by_user)

    created_by_user&.email
  end

  def created_by_user_email
    created_by_user_name
  end

  def rank_name
    return nil unless respond_to? :rank

    self.class.get_rank_name rank
  end

  def source_name
    return nil unless respond_to? :source

    self.class.get_source_name source
  end

  # look up the tracker_history items that correspond to the item
  # we would use the master tracker_histories association as a base, but it doesn't serialize as_json correctly :(
  def tracker_histories
    return @memo_tracker_histories if @memo_tracker_histories

    # Check for the existence of tracker_histories in the super class. If it
    # already exists, it is an association that we should not be overriding
    if defined?(super)
      @memo_tracker_histories = super
    else
      @memo_tracker_histories = TrackerHistory.where(item_id: id, item_type: self.class.name, master_id: master_id).order(id: :asc)
    end
  end

  # look up the tracker_history item that corresponds to the latest tracker entry linked to this item
  def tracker_history
    tracker_histories.last
  end

  def tracker_history_id
    th = tracker_history
    return unless th&.id

    th.id
  end

  def updated_at_ts
    updated_at&.to_i
  end

  def created_at_ts
    created_at&.to_i
  end

  def user_preference
    user&.user_preference&.attributes
  end

  def as_json(extras = {})
    self.current_user ||= extras[:current_user] if extras[:current_user] # if self.class.no_master_association
    if allows_current_user_access_to?(:access)

      extras[:include] ||= {}
      extras[:methods] ||= []
      extras[:methods] << :item_id if respond_to? :item_id
      extras[:methods] << :item_type if respond_to? :item_type
      extras[:methods] << :full_item_type if respond_to? :full_item_type
      extras[:methods] << :updated_at_ts if respond_to? :updated_at
      extras[:methods] << :created_at_ts if respond_to? :created_at
      extras[:methods] << :data if respond_to? :data
      extras[:methods] << :rank_name if respond_to? :rank_name
      extras[:methods] << :state_name if respond_to? :state_name
      extras[:methods] << :country_name if respond_to? :country_name
      extras[:methods] << :source_name if respond_to? :source_name
      extras[:methods] << :protocol_name if respond_to? :protocol_name
      extras[:methods] << :sub_process_name if respond_to? :sub_process_name
      extras[:methods] << :protocol_event_name if respond_to? :protocol_event_name
      if !is_a?(Tracker) && !is_a?(TrackerHistory) && (respond_to?(:tracker_history_id) || respond_to?(:tracker_history))
        extras[:methods] << :tracker_history_id
        extras[:methods] << :tracker_histories if respond_to? :tracker_histories
      end
      extras[:methods] << :accuracy_score_name if respond_to? :accuracy_score_name
      extras[:methods] << :user_name if respond_to? :user_name
      extras[:methods] << :user_email if respond_to? :user_email
      extras[:methods] << :created_by_user_name if respond_to? :created_by_user_name
      extras[:methods] << :created_by_user_email if respond_to? :created_by_user_email

      # update_action can be used by requestor to identify whether the record was just updated (saved) or not
      extras[:methods] << :update_action if respond_to? :update_action
      extras[:methods] << :_created if respond_to? :_created
      extras[:methods] << :_updated if respond_to? :_updated
      extras[:methods] << :human_name if respond_to? :human_name

      extras[:methods] << :model_data_type if respond_to? :model_data_type

      extras[:methods] << :model_references if respond_to? :model_references
      extras[:methods] << :creatable_model_references if respond_to? :creatable_model_references
      extras[:methods] << :referenced_from if respond_to? :referenced_from
      extras[:methods] << :embedded_item if respond_to? :embedded_item

      # extras[:methods] << :creatables if respond_to? :creatables
      extras[:methods] << :prevent_edit if respond_to? :prevent_edit
      extras[:methods] << :prevent_add_reference if respond_to? :prevent_add_reference
      extras[:methods] << :option_type if respond_to? :option_type
      extras[:methods] << :alt_order if respond_to? :alt_order
      extras[:methods] << :user_preference if respond_to? :user_preference

      extras[:include][self.class.parent_type] = { methods: %i[rank_name data] } if self.class.respond_to? :parent_type
      if self.class.respond_to?(:uses_item_flags?) && self.class.uses_item_flags?(master_user)
        extras[:include][:item_flags] = { include: [:item_flag_name], methods: %i[method_id item_type_us] }
      end

    elsif allows_current_user_access_to?(:see_presence_or_access)

      extras[:include] ||= {}
      extras[:methods] ||= []
      extras[:only] = [:id]

      extras[:methods] << :item_id if respond_to? :item_id
      extras[:methods] << :item_type if respond_to? :item_type
      extras[:methods] << :full_item_type if respond_to? :full_item_type
      extras[:methods] << :updated_at_ts if respond_to? :updated_at
      extras[:methods] << :created_at_ts if respond_to? :created_at
      extras[:methods] << :user_name if respond_to? :user_name
      extras[:methods] << :user_email if respond_to? :user_email
      extras[:methods] << :created_by_user_name if respond_to? :created_by_user_name
      extras[:methods] << :created_by_user_email if respond_to? :created_by_user_email

      # update_action can be used by requestor to identify whether the record was just updated (saved) or not
      extras[:methods] << :update_action if respond_to? :update_action
      extras[:methods] << :human_name if respond_to? :human_name
      extras[:methods] << :_created if respond_to? :_created
      extras[:methods] << :_updated if respond_to? :_updated
      extras[:methods] << :_disabled if respond_to? :_disabled
      extras[:methods] << :user_preference if respond_to? :user_preference

    else
      return {}
    end

    super(extras)
  end
end
