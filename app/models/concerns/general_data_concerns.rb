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

  def hide_tracker_panel
    return @hide_tracker_panel if @hide_tracker_panel

    val = Admin::AppConfiguration.value_for(:hide_tracker_panel, current_user)
    @hide_tracker_panel = !val.blank? && val != 'false'
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

  def _created=(val)
    @was_created = val
  end

  def _updated=(val)
    @was_updated = val
  end

  def _disabled=(val)
    @was_disabled = val
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
    return unless respond_to?(:user_id) && user_id

    User.emails_by_id[user_id]
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

  def master_created_by_user_email
    master_created_by_user&.email
  end

  def master_created_by_user
    return unless respond_to?(:master) && master.respond_to?(:master_created_by_user)

    master.master_created_by_user
  end

  def rank_name
    return nil unless respond_to? :rank

    self.class.get_rank_name rank
  end

  def source_name
    return super if defined?(super) && !respond_to?(:source)
    return nil unless respond_to? :source

    self.class.get_source_name source
  end

  # look up the tracker_history items that correspond to the item
  # we would use the master tracker_histories association as a base, but it doesn't serialize as_json correctly :(
  def tracker_histories
    return @memo_tracker_histories if @memo_tracker_histories

    return unless respond_to?(:master_id) && !allow_no_master_and_not_set?

    # Check for the existence of tracker_histories in the super class. If it
    # already exists, it is an association that we should not be overriding
    @memo_tracker_histories = if defined?(super)
                                super
                              else
                                TrackerHistory
                                  .eager_load(:user)
                                  .where(item_id: id,
                                         item_type: self.class.name,
                                         master_id:)
                                  .order(id: :asc)
                              end
  end

  # look up the tracker_history item that corresponds to the latest tracker entry linked to this item
  def tracker_history
    tracker_histories&.last
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

  #
  # Embed the user preference for the last user to update the record
  # @return [UserPreference]
  def user_preference
    user&.user_preference
  end

  #
  # Return a definition version string prefixed with a v
  # If not version definition is provided (the version is current)
  # or the templates don't use a version definition, just return 'v'
  # @return [String]
  def vdef_version
    "v#{def_version}"
  end

  #
  # Returns a simple hash alternative ids accessible by the current user
  # @return [Hash]
  def ids
    master&.alternative_ids
  end

  #
  # Return a set of selection list data in the _general_selections entry
  # since this will be picked up by the front end to be used to translate
  # specific field values to human names. Since the select_from_... fields
  # may be tied through a master association to the current instance,
  # it is not possible to cache the results directly based on a dynamic definition
  # and it must be handled at the time of the request.
  # The result format matches what is expected by the front end, for example:
  # { "title": {
  #      "66": { "name": "Project Viva Analysis Plan Presentation_Template-widescreen.pptx" },
  #      "67": {"name": "policies-for-using-our-data.pdf" }
  # } }
  # @return [Hash{<field_name:>{<field_value>: {name: <display result>}}}]
  def _general_selections
    return @add_show_attribs if @add_show_attribs

    @add_show_attribs = {}
    otc = option_type_config

    elt = extra_log_type if respond_to? :extra_log_type
    mid = master_id if respond_to? :master_id

    rn = self.class.resource_name
    allselects = Classification::SelectionOptionsHandler.selector_with_config_overrides(
      item_type: rn,
      extra_log_type: elt,
      master_id: mid
    )
    return unless allselects&.present?

    prefix = rn.singularize

    attribute_names.each do |an|
      ansym = an.to_sym
      opt = otc.field_options[ansym] if otc
      edit_as = opt[:edit_as] if opt
      edit_as ||= {}
      alt_fn = (edit_as[:field_type] || an).to_s
      alt_gs = edit_as[:general_selection]
      next unless alt_gs ||
                  alt_fn.index(/^(redcap_)?(tag_)?select/) ||
                  alt_fn.index(/^redcap_radio/) ||
                  alt_fn.in?(['rank', 'source', 'rec_type'])

      vals = attributes[an]
      vals = [vals] unless vals.is_a? Array
      vals = vals.map(&:to_s)
      entries =
        allselects
        .select { |f| f[:field_name] == ansym && f[:base_item_type].singularize == prefix && f[:value].to_s&.in?(vals) }
        .map { |e| [e[:value].to_s, { name: e[:name] }] }
      @add_show_attribs[an] = entries.to_h
    end

    @add_show_attribs
  end

  def as_json(extras = {})
    self.current_user ||= extras[:current_user] if extras[:current_user]
    if extras[:force_plain_json]
      extras = {}
    elsif allows_current_user_access_to?(:access)

      extras[:include] ||= {}
      extras[:methods] ||= []
      extras[:methods] << :master_id if respond_to? :master_id
      extras[:methods] << :item_id if respond_to? :item_id
      extras[:methods] << :item_type if respond_to? :item_type
      extras[:methods] << :full_item_type if respond_to? :full_item_type
      extras[:methods] << :resource_name if respond_to? :resource_name
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
      if !hide_tracker_panel && !is_a?(Tracker) && !is_a?(TrackerHistory) && (respond_to?(:tracker_histories) || respond_to?(:tracker_history))
        extras[:methods] << :tracker_history_id
        extras[:methods] << :tracker_histories if respond_to? :tracker_histories
      end
      extras[:methods] << :accuracy_score_name if respond_to? :accuracy_score_name
      extras[:methods] << :subject_age if respond_to? :subject_age
      extras[:methods] << :user_name if respond_to? :user_name
      extras[:methods] << :user_email if respond_to? :user_email
      extras[:methods] << :created_by_user if respond_to? :created_by_user
      extras[:methods] << :created_by_user_name if respond_to? :created_by_user_name
      extras[:methods] << :created_by_user_email if respond_to? :created_by_user_email

      extras[:methods] << :master_created_by_user if respond_to? :master_created_by_user
      extras[:methods] << :master_created_by_user_email if respond_to? :master_created_by_user_email

      # update_action can be used by requestor to identify whether the record was just updated (saved) or not
      extras[:methods] << :update_action if respond_to? :update_action
      extras[:methods] << :_created if respond_to? :_created
      extras[:methods] << :_updated if respond_to? :_updated
      extras[:methods] << :human_name if respond_to? :human_name

      extras[:methods] << :model_data_type if respond_to? :model_data_type

      @config_order_model_references = true
      extras[:methods] << :model_references if respond_to? :model_references
      extras[:methods] << :creatable_model_references if respond_to? :creatable_model_references
      extras[:methods] << :referenced_from if respond_to? :referenced_from
      extras[:methods] << :embedded_item if respond_to? :embedded_item
      extras[:methods] << :embedded_items if respond_to? :embedded_items

      # extras[:methods] << :creatables if respond_to? :creatables
      extras[:methods] << :prevent_edit if respond_to? :prevent_edit
      extras[:methods] << :prevent_add_reference if respond_to? :prevent_add_reference
      extras[:methods] << :can_download? if respond_to? :can_download?
      extras[:methods] << :option_type if respond_to? :option_type
      extras[:methods] << :alt_order if respond_to? :alt_order
      extras[:methods] << :user_preference if respond_to? :user_preference

      extras[:include][self.class.parent_type] = { methods: %i[rank_name data] } if self.class.respond_to? :parent_type
      if self.class.respond_to?(:uses_item_flags?) && self.class.uses_item_flags?(master_user)
        extras[:include][:item_flags] = { include: [:item_flag_name], methods: %i[method_id item_type_us] }
      end

      extras[:methods] << :def_version
      extras[:methods] << :vdef_version

      if respond_to?(:master) && !allow_no_master_and_not_set? && !is_a?(TrackerHistory) && !is_a?(Tracker)
        extras[:methods] << :ids
      end

      extras[:methods] << :_general_selections
    elsif allows_current_user_access_to?(:see_presence_or_access)

      extras[:include] ||= {}
      extras[:methods] ||= []
      extras[:only] = [:id]

      extras[:methods] << :item_id if respond_to? :item_id
      extras[:methods] << :item_type if respond_to? :item_type
      extras[:methods] << :full_item_type if respond_to? :full_item_type
      extras[:methods] << :resource_name if respond_to? :resource_name
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
