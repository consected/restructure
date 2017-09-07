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
    logger.debug "Getting username for #{self.user}"
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


  def as_json extras={}

    extras[:include] ||= {}
    extras[:methods] ||= []
    extras[:methods] << :item_id
    extras[:methods] << :item_type
    extras[:methods] << :rank_name if respond_to? :rank
    extras[:methods] << :state_name if respond_to? :state
    extras[:methods] << :country_name if respond_to? :country
    extras[:methods] << :source_name if respond_to? :source
    extras[:methods] << :accuracy_score_name if respond_to? :accuracy_score
    extras[:methods] << :user_name
    # update_action can be used by requestor to identify whether the record was just updated (saved) or not
    extras[:methods] << :update_action
    extras[:methods] << :_created
    extras[:methods] << :_updated

    extras[:include][self.class.parent_type] = {methods: [:rank_name]} if self.class.respond_to? :parent_type
    extras[:include][:item_flags] = {include: [:item_flag_name], methods: [:method_id, :item_type_us]} if self.class.respond_to?(:uses_item_flags?) && self.class.uses_item_flags?

    super(extras)
  end

end
