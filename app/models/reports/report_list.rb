module Reports
  class ReportList

    attr_accessor :list_class, :list_id, :item_type, :item_ids, :from_master_id, :item_class, :items_in_list, :item_ids_in_list,
                  :item_attribs, :assoc_attr, :list_attribs, :new_item_ids,
                  :current_user, :current_admin

    def self.setup atl_params, current_user, current_admin=nil

      obj = self.new
      obj.setup atl_params, current_user, current_admin
      return obj

    end

    def setup atl_params, current_user, current_admin=nil
      self.current_user = current_user
      self.current_admin = current_admin
      list_name = atl_params[:list_name]
      items_text = atl_params[:items]

      return unless authorized? == true

      ok = current_user.has_access_to?(:create, :table, list_name) || current_user.has_access_to?(:create, :table, "dynamic_model__#{list_name}")
      return not_authorized unless ok

      return general_error("no items selected") if items_text.blank? || items_text.length == 0

      items = items_text.map {|i| JSON.parse(i)}
      item_types = items.map {|i| i["type"]}.uniq
      return general_error("item type not specified") unless item_types.length == 1 && item_types.first
      self.item_type = item_types.first

      list_ids = items.map {|i| i["list_id"]}.uniq
      self.list_id = list_ids.first
      return general_error("list id not specified") unless list_ids.length == 1 && list_id

      self.from_master_id = items.map {|i| i["from_master_id"]}.first
      return general_error("master id not specified") unless from_master_id
      from_master = Master.find(from_master_id)
      from_master.current_user = current_user
      return not_authorized unless from_master.allows_user_access

      ok = current_user.has_access_to?(:access, :table, item_type) || current_user.has_access_to?(:access, :table, "dynamic_model__#{item_type}")
      return not_authorized unless ok

      self.item_ids = items.map {|i| i["id"]}

      self.item_class = ModelReference.to_record_class_for_type item_type.singularize
      self.item_attribs = item_class.permitted_params

      self.list_class = ModelReference.to_record_class_for_type list_name.singularize
      self.list_attribs = list_class.permitted_params
      self.assoc_attr = (list_class.attribute_names.select {|a| a.end_with?('_id')} - ['id', 'master_id', 'record_id', 'user_id']).first

      assoc_name = assoc_attr.gsub(/_id$/, '').pluralize
      ok = current_user.has_access_to?(:access, :table, assoc_name) || current_user.has_access_to?(:access, :table, "dynamic_model__#{assoc_name}")
      return not_authorized unless ok

      assoc_class = ModelReference.to_record_class_for_type assoc_name.singularize
      assoc_item = assoc_class.where(id: list_id).first
      return general_error("list id does not represent an associated list: #{list_id}") unless assoc_item

      self.items_in_list = list_class.where(disabled: false, assoc_attr => list_id)
      items_in_list_record_ids = self.items_in_list.pluck(:record_id)
      items_in_list_ids = self.items_in_list.pluck(:id)
      self.item_ids_in_list = item_ids & items_in_list_ids
      self.new_item_ids = item_ids - items_in_list_record_ids

      return self
    end

    def add_items_to_list

      return general_error("all items already in the list") if new_item_ids.length == 0

      matching_attribs = (list_attribs & item_attribs).map(&:to_s)
      return general_error("no matching attributes") if matching_attribs.length == 0

      list_class.transaction do
        all_recs = []

        new_item_ids.each do |id|
          item = item_class.find(id)
          master = item.master
          master.current_user = current_user
          matched_vals = item.attributes.slice(*matching_attribs)
          matched_vals[:record_id] = id
          matched_vals[:record_type] = item_type.singularize
          matched_vals[:master_id] = from_master_id
          matched_vals[assoc_attr] = list_id
          matched_vals.send :write_attribute, :user_id, current_user.id
          all_recs << list_class.new(matched_vals)
        end

        list_class.import all_recs, validate: false
      end

      n = new_item_ids.length
    end

    def remove_items_from_list

      return general_error("no items in the list can be removed") if self.item_ids_in_list.length == 0

      list_class.transaction do
        item_ids_in_list.each do |id|
          item = list_class.find(id)

          item.disable! current_user: current_user
        end
      end

      return item_ids_in_list
    end

    protected
      def authorized?
        return true if current_admin
        return true if current_user.can? :view_reports

        raise FphsException.new('not authorized')
      end

      def general_error msg
        raise FphsGeneralError.new msg
      end

  end
end
