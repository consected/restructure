# frozen_string_literal: true

module Reports
  # A Report List allows users to check and uncheck items they wish to select from a regular report.
  # The list storing the user's selections is a model having specific fields (and may be a dynamic model):
  #
  # - Primary key: id
  # - Foreign key: master_id (optional)
  # - Source model name representing data being selected from: record_type
  # - Record ID in model selecting from: record_id
  # - List ID: an integer associating the request back to a specific user activity, grouping
  #            all related selections: (for example data_request_id)
  # - Flag indicating the user has unselected the item: disabled
  # - other fields that match the table being selected from (for example: variable_name)
  #
  #
  # In order to set up the list to be used, the report viewing the source data being selected must add some
  # formatted column names and values in its results, which points the UI to the appropriate report list to update.
  #
  # For example, if the table `q2_datadic` is the *source* table and `data_requests_selected_attribs` is the
  # record list table storing the *selections* made by a user, the following report SQL is required:
  #
  # select distinct
  #   source.id,
  #   -- define the checkbox field, passing the
  #   '{"field_name": "update_list[items][]",' ||
  #   '"value": {"list_id": "' || :list_id || '",' ||
  #     '"type":"q2_datadic",' ||
  #     '"id": ' || source.id || ',' ||
  #     '"from_master_id":-1,
  #     '"init_value": ' ||
  #       case when coalesce(selections.id, 0) = 0 then 'false' else 'true' end
  #     || '} }'
  #     "select items: update list: data_requests_selected_attribs",
  #   -- a matching variable_name field appears in the selections record list too and will be stored with this value
  #   source.variable_name,
  #   -- other visible fields
  #   source.field_label,
  #   case when coalesce(selections.id, 0) = 0 then 'false' else 'true' end "selected"
  # from q2_datadic source
  # -- left join the selections report list table, so a new query shows the selections already made
  # left join data_requests_selected_attribs selections
  # on selections.record_id = source.id
  #   and  selections.record_type = 'q2_datadic'
  #   and not coalesce(selections.disabled, false)
  # -- Only return values for the data_request_id which represents an activity log ID for this user's request
  # -- The list_id is passed in as a parameter, and must be set up as a number, with option to hide it in the form.
  #   and :list_id = data_request_id
  # where
  # -- the where conditions may be edited as needed to allow the appropriate search on the source data
  # -- these do not affect the report list in any way.
  #   (
  #     (
  #       :name_or_label_contains is NULL
  #       OR source.variable_name ~* :name_or_label_contains
  #       OR source.field_label ~* :name_or_label_contains
  #     )
  #     OR selections.id IS NOT NULL
  #   )
  # order by
  # -- show the stored selections at the top of the list
  # selected desc, source.id;
  #
  #
  # The most complex part of this is the formatted "selected items" column, which tells the UI what has been selected
  # and how to store new selections in the selections record list. Otherwise this is mostly standard SQL
  class ReportList
    attr_accessor :list_name, :list_id, :source_type, :full_source_type_name,
                  :item_ids_in_list, :items,
                  :new_item_ids, :removed_item_ids,
                  :current_user, :current_admin,
                  :list_on_attr

    def self.setup(list_name, items_text, current_user, current_admin = nil)
      obj = new
      obj.setup list_name, items_text, current_user, current_admin
      obj
    end

    #
    # Used to set up a report list for processing new user selections, in preparation to
    # add to list, update list or remove items from list
    # @param [String] list_name - model name for list of user selections
    # @param [String] items_text - JSON text array of items to be processed for the list
    # @param [User] current_user
    # @param [Admin] current_admin (optional) - allows access to all admins
    # @return [Reports::ReportList] returns self
    def setup(list_name, items_text, current_user, current_admin = nil)
      self.current_user = current_user
      self.current_admin = current_admin
      self.list_name = list_name
      return unless authorized? == true

      raise(FphsGeneralError, 'no items selected') if items_text.blank? || items_text.empty?

      # Parse the items_text to get an array of hashes, each item representing a user selection change
      # This follows the JSON represented in the complex report column value, formatted as
      # {"list_id": "<list_id>",
      #  "type":"q2_datadic",
      #  "id": <source.id>,
      #  "from_master_id": -1,
      #  "init_value": true | false }
      self.items = items_text.map { |i| JSON.parse(i) }
      item_ids = items.map { |i| i['id'] }

      # Ensure there is only a single type being represented in the list
      source_types = items.map { |i| i['type'] }.uniq
      self.source_type = source_types.first
      raise(FphsGeneralError, 'source type not specified') unless source_types.length == 1 && source_type

      # Ensure there is only a single list ID being represented in the list
      list_ids = items.map { |i| i['list_id'] }.uniq
      self.list_id = list_ids.first
      raise(FphsGeneralError, 'list id not specified') unless list_ids.length == 1 && list_id

      # Use the optional *on_attr:* value to specify an alternative field to check the list against.
      # For example, this allows master_id to be specified, tying lists to master records rather than
      # dynamic definition records. By default we assume the id field will be used.
      self.list_on_attr = items.first['on_attr'] || 'id'

      check_authorizations!
      check_valid_list_id!

      items_in_list_record_ids = items_in_list.pluck(:record_id)
      items_in_list_ids = items_in_list.pluck(:id)

      self.item_ids_in_list = item_ids & items_in_list_ids
      self.new_item_ids = item_ids - items_in_list_record_ids
      self.removed_item_ids = items_in_list_record_ids - item_ids

      self
    end

    def add_items_to_list
      raise(FphsGeneralError, 'all items already in the list') if new_item_ids.empty?

      list_class.transaction do
        all_recs = setup_list_items

        list_class.import all_recs, validate: false
      end

      new_item_ids.length
    end

    def update_items_in_list
      list_class.transaction do
        all_recs = setup_list_items

        items_to_disable = list_class.where(record_id: removed_item_ids,
                                            assoc_attr => list_id,
                                            record_type: full_source_type_name)
        items_to_disable.each do |item|
          item.disable! current_user: current_user
        end

        list_class.import all_recs, validate: false
      end

      new_item_ids.length + removed_item_ids.length
    end

    def remove_items_from_list
      raise(FphsGeneralError, 'no items in the list can be removed') if item_ids_in_list.empty?

      list_class.transaction do
        item_ids_in_list.each do |id|
          item = list_class.find(id)

          item.disable! current_user: current_user
        end
      end

      item_ids_in_list
    end

    #
    # User must have user access control to create records in the list table
    # @return [Boolean]
    def can_create_in_list?
      current_user.has_access_to?(:create, :table, list_name) ||
        current_user.has_access_to?(:create, :table, "dynamic_model__#{list_name}")
    end

    #
    # User must have user access control to access records in the table the list
    # is associated with
    # @return [Boolean]
    def can_access_associated_table?
      current_user.has_access_to?(:access, :table, assoc_name) ||
        current_user.has_access_to?(:access, :table, "dynamic_model__#{assoc_name}")
    end

    def can_access_source_type?
      current_user.has_access_to?(:access, :table, source_type) ||
        current_user.has_access_to?(:access, :table, "dynamic_model__#{source_type}")
    end

    protected

    def authorized?
      return true if current_admin
      return true if current_user.can?(:view_report_not_list) || current_user.can?(:view_reports)

      raise FphsException, 'not authorized'
    end

    # Set the master the record is from, (just assume it is the only one in the list)
    def from_master_id
      return if list_class.no_master_association

      @from_master_id ||= items.map { |i| i['from_master_id'] }.first
      raise(FphsGeneralError, 'master id not specified') unless @from_master_id

      @from_master_id
    end

    def from_master
      return @from_master if @from_master

      @from_master = Master.find(from_master_id)
      @from_master.current_user = current_user
      @from_master
    end

    #
    # We don't enforce the use of record_type within the report list
    # model. Simply check if we need it.
    # @return [Boolean]
    def uses_record_type?
      list_class.attribute_names.include?('record_type')
    end

    #
    # Raise an exception unless the user hass access to the:
    # - master record
    # - source model
    # - model the list is associated with
    def check_authorizations!
      raise FphsNotAuthorized unless can_create_in_list?

      unless list_class.no_master_association || from_master.allows_user_access
        raise FphsNotAuthorized, 'Master does not allow user access'
      end

      raise FphsNotAuthorized, "No access to #{source_type}" unless can_access_source_type?

      raise FphsNotAuthorized, "No access to #{assoc_name}" unless can_access_associated_table?
    end

    #
    # Raise an error if the list id is not found within the class the selections model is associated with
    def check_valid_list_id!
      assoc_class = ModelReference.to_record_class_for_type assoc_name.singularize
      assoc_item = assoc_class.where(list_on_attr => list_id).first
      return if assoc_item

      raise FphsGeneralError, "list id does not represent an associated list: #{list_id} for #{assoc_class}"
    end

    def general_error(msg)
      raise FphsGeneralError, msg
    end

    def list_class
      @list_class ||= ModelReference.to_record_class_for_type list_name.singularize
    end

    #
    # Get the attribute name for the table the list is associated with
    # by picking the first attribute name that is an id field, and isn't one
    # of the standard fields we'd expect to find in the table
    # @return [String] association attribute
    def assoc_attr
      return @assoc_attr if @assoc_attr

      aa = list_class.attribute_names.select { |a| a.end_with?('_id') }
      aa -= %w[id master_id record_id user_id]
      @assoc_attr = aa.first
    end

    #
    # The association name is the association attribute name, without the
    # _id suffix, pluralized
    # @return [String] association name
    def assoc_name
      @assoc_name ||= assoc_attr.gsub(/_id$/, '').pluralize
    end

    def source_class
      return @source_class if @source_class

      self.full_source_type_name = source_type.singularize
      @source_class = ModelReference.to_record_class_for_type full_source_type_name
      return @source_class if @source_class

      self.full_source_type_name = "dynamic_model/#{source_type.singularize}"
      @source_class = ModelReference.to_record_class_for_type full_source_type_name

      raise FphsException, "Full item type name not found: #{full_source_type_name}" unless source_class
    end

    def items_in_list
      return @items_in_list if @items_in_list

      @items_in_list = list_class.active.where(assoc_attr => list_id)
      # Refine results to include just the ids for this record type, if the record_type is used & available

      if source_class && full_source_type_name.present? && uses_record_type?
        @items_in_list = @items_in_list.where(record_type: full_source_type_name)
      end

      @items_in_list
    end

    #
    # Set up new list items (using the list_class) with specific
    # attribute values pulled from the items with new_item_ids
    # @return [Array] new list items
    def setup_list_items
      all_recs = []

      item_attribs = source_class.permitted_params
      list_attribs = list_class.permitted_params

      matching_attribs = (list_attribs & item_attribs).map(&:to_s)
      raise(FphsGeneralError, 'no matching attributes') if matching_attribs.empty?

      source_class.where(id: new_item_ids).each do |item|
        id = item.id
        if item.attribute_names.include? 'master_id'
          master = item.master
          master.current_user = current_user
        end
        matched_vals = item.attributes.slice(*matching_attribs)
        matched_vals[:record_id] = id
        matched_vals[:record_type] = full_source_type_name
        matched_vals[:master_id] = from_master_id unless list_class.no_master_association
        matched_vals[assoc_attr] = list_id
        new_list_instance = list_class.new(matched_vals)
        new_list_instance.send :write_attribute, :user_id, current_user.id
        all_recs << new_list_instance
      end
      all_recs
    end
  end
end
