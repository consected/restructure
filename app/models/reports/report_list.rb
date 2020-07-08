# frozen_string_literal: true

module Reports
  class ReportList
    attr_accessor :list_class, :list_id, :item_type, :full_item_type_name, :item_ids, :from_master_id, :item_class, :items_in_list, :item_ids_in_list,
                  :item_attribs, :assoc_attr, :list_attribs, :new_item_ids, :removed_item_ids,
                  :current_user, :current_admin

    def self.setup(atl_params, current_user, current_admin = nil)
      obj = new
      obj.setup atl_params, current_user, current_admin
      obj
    end

    def setup(atl_params, current_user, current_admin = nil)
      self.current_user = current_user
      self.current_admin = current_admin
      list_name = atl_params[:list_name]
      items_text = atl_params[:items]
      return unless authorized? == true

      ok = current_user.has_access_to?(:create, :table, list_name) || current_user.has_access_to?(:create, :table, "dynamic_model__#{list_name}")
      raise FphsNotAuthorized unless ok

      return general_error('no items selected') if items_text.blank? || items_text.empty?

      items = items_text.map { |i| JSON.parse(i) }
      item_types = items.map { |i| i['type'] }.uniq
      return general_error('item type not specified') unless item_types.length == 1 && item_types.first

      self.item_type = item_types.first

      list_ids = items.map { |i| i['list_id'] }.uniq
      self.list_id = list_ids.first
      return general_error('list id not specified') unless list_ids.length == 1 && list_id

      self.from_master_id = items.map { |i| i['from_master_id'] }.first
      return general_error('master id not specified') unless from_master_id

      from_master = Master.find(from_master_id)
      from_master.current_user = current_user
      raise FphsNotAuthorized, 'Master does not allow user access' unless from_master.allows_user_access

      ok = current_user.has_access_to?(:access, :table, item_type) || current_user.has_access_to?(:access, :table, "dynamic_model__#{item_type}")
      raise FphsNotAuthorized, "No access to #{item_type}" unless ok

      self.item_ids = items.map { |i| i['id'] }

      self.full_item_type_name = item_type.singularize
      self.item_class = ModelReference.to_record_class_for_type full_item_type_name
      self.full_item_type_name = "dynamic_model/#{item_type.singularize}" unless item_class
      self.item_class = ModelReference.to_record_class_for_type full_item_type_name

      raise FphsException, "Full item type name not found: #{full_item_type_name}" unless item_class

      self.item_attribs = item_class.permitted_params

      self.list_class = ModelReference.to_record_class_for_type list_name.singularize
      self.list_attribs = list_class.permitted_params
      self.assoc_attr = (list_class.attribute_names.select { |a| a.end_with?('_id') } - ['id', 'master_id', 'record_id', 'user_id']).first

      assoc_name = assoc_attr.gsub(/_id$/, '').pluralize
      ok = current_user.has_access_to?(:access, :table, assoc_name) || current_user.has_access_to?(:access, :table, "dynamic_model__#{assoc_name}")
      raise FphsNotAuthorized, "No access to #{assoc_name}" unless ok

      assoc_class = ModelReference.to_record_class_for_type assoc_name.singularize
      assoc_item = assoc_class.where(id: list_id).first
      return general_error("list id does not represent an associated list: #{list_id}") unless assoc_item

      self.items_in_list = list_class.active.where(assoc_attr => list_id)
      items_in_list_record_ids = items_in_list.pluck(:record_id)
      items_in_list_ids = items_in_list.pluck(:id)
      self.item_ids_in_list = item_ids & items_in_list_ids
      self.new_item_ids = item_ids - items_in_list_record_ids
      self.removed_item_ids = items_in_list_record_ids - item_ids

      self
    end

    def add_items_to_list
      return general_error('all items already in the list') if new_item_ids.empty?

      matching_attribs = (list_attribs & item_attribs).map(&:to_s)
      return general_error('no matching attributes') if matching_attribs.empty?

      list_class.transaction do
        all_recs = []

        item_class.where(id: new_item_ids).each do |item|
          id = item.id
          if item.attribute_names.include? 'master_id'
            master = item.master
            master.current_user = current_user
          end
          matched_vals = item.attributes.slice(*matching_attribs)
          matched_vals[:record_id] = id
          matched_vals[:record_type] = full_item_type_name
          matched_vals[:master_id] = from_master_id
          matched_vals[assoc_attr] = list_id
          o = list_class.new(matched_vals)
          o.send :write_attribute, :user_id, current_user.id
          all_recs << o
        end

        list_class.import all_recs, validate: false
      end

      new_item_ids.length
    end

    def update_items_in_list
      # return general_error('all items already in the list') if new_item_ids.empty?
      matching_attribs = (list_attribs & item_attribs).map(&:to_s)
      return general_error('no matching attributes') if matching_attribs.empty?

      list_class.transaction do
        all_recs = []
        item_class.where(id: new_item_ids).each do |item|
          id = item.id
          if item.attribute_names.include? 'master_id'
            master = item.master
            master.current_user = current_user
          end
          matched_vals = item.attributes.slice(*matching_attribs)
          matched_vals[:record_id] = id
          matched_vals[:record_type] = full_item_type_name
          matched_vals[:master_id] = from_master_id
          matched_vals[assoc_attr] = list_id
          o = list_class.new(matched_vals)
          o.send :write_attribute, :user_id, current_user.id
          all_recs << o
        end

        list_class.where(record_id: removed_item_ids, assoc_attr => list_id, record_type: full_item_type_name).each do |item|
          item.disable! current_user: current_user
        end

        list_class.import all_recs, validate: false
      end

      new_item_ids.length + removed_item_ids.length
    end

    def remove_items_from_list
      return general_error('no items in the list can be removed') if item_ids_in_list.empty?

      list_class.transaction do
        item_ids_in_list.each do |id|
          item = list_class.find(id)

          item.disable! current_user: current_user
        end
      end

      item_ids_in_list
    end

    protected

    def authorized?
      return true if current_admin
      return true if current_user.can? :view_reports

      raise FphsException, 'not authorized'
    end

    def general_error(msg)
      raise FphsGeneralError, msg
    end
  end
end
