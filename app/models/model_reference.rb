class ModelReference < ActiveRecord::Base

  belongs_to :user

  validates :from_record_id, presence: true
  validates :from_record_master_id, presence: true
  validates :from_record_type, presence: true
  validates :to_record_id, presence: true
  validates :to_record_master_id, presence: true
  validates :to_record_type, presence: true
  validates :user_id, presence: true

  attr_accessor :current_user

  # TODO consider if there is a significant race condition that we should be concerned about
  def self.create_with from_item, to_item
    m = ModelReference.where from_record_type: from_item.class.name, from_record_id: from_item.id, from_record_master_id: from_item.master_id,
                            to_record_type: to_item.class.name, to_record_id: to_item.id, to_record_master_id: to_item.master_id

    if m.limit(1).length == 0
      ModelReference.create! from_record_type: from_item.class.name, from_record_id: from_item.id, from_record_master_id: from_item.master_id,
                            to_record_type: to_item.class.name, to_record_id: to_item.id, to_record_master_id: to_item.master_id,
                            user: to_item.master_user
    end
  end

  def self.find_referenced_items from_item_or_master, record_type: nil
    mrs = self.find_references from_item_or_master, record_type: record_type
    res = []
    mrs.each do |m|
      rec = m.to_record
      rec.master.current_user = from_item_or_master.master_user
      res << rec
    end
    res
  end

  # Find referenced items belonging to either an item or a master record
  # If belonging to an item, the results may be further limited to those with a to_record_type
  # If belonging to a master record, the to_record_type must be specified.
  # These can be further limited by a filter_by condition on the to_record,
  # allowing for specific records to be selected from the master (such as a specific 'type' of referenced record)
  def self.find_references from_item_or_master, to_record_type: nil, filter_by: nil

    if to_record_type
      to_record_type = to_record_class_for_type(to_record_type).name
    end

    if from_item_or_master.is_a? Master
      res = ModelReference.find_records_in_master to_record_type: to_record_type, master: from_item_or_master, filter_by: filter_by
    else
      cond = {from_record_type: from_item_or_master.class.name, from_record_id: from_item_or_master.id}
      cond[:to_record_type] = to_record_type if to_record_type
      res = ModelReference.where cond
      # Handle the filter_by clause
      res = res.select {|mr| filter_by.all? { |k, v| mr.to_record.attributes[k.to_s] == v }   } if filter_by
    end

    # Set the current user, so that access controls can be correctly applied
    res.each do |r|
      if from_item_or_master.respond_to? :master_user
        mu = from_item_or_master.master_user
      else
        mu = from_item_or_master.current_user
      end
      r.current_user = mu
    end
    res
  end

  # Find which items reference this item
  def self.find_where_referenced_from to_item
    cond = {to_record_type: to_item.class.name, to_record_id: to_item.id}
    res = ModelReference.where cond
    # Set the current user, so that access controls can be correctly applied
    res.each do |r|
      if to_item.respond_to? :master_user
        mu = to_item.master_user
      else
        mu = to_item.current_user
      end
      r.current_user = mu
    end
    res
  end

  def self.to_record_class_for_type rec_type
    begin
      rec_type.ns_camelize.constantize
    rescue NameError
      Rails.logger.error "Attempt to get to_record_class_for_type #{rec_type} failed as the type does not exist"
      nil
    end
  end

  def self.record_type_to_ns_table_name rt
    if rt.is_a?(String) || rt.is_a?(Symbol)
      rt.to_s.sub('dynamic_model__', '')
    else
      rt.name.ns_underscore.sub('dynamic_model__', '')
    end
  end

  def self.record_type_to_table_name rt
    record_type_to_ns_table_name(rt).gsub('__', '_')
  end


  def to_record_class
    to_record_type.camelize.constantize
  end

  def to_record_label
    to_record.human_name
  end

  def to_record_type_us
    to_record_type.ns_underscore
  end

  def to_record_short_type_us
    to_record_type.split('::').last.ns_underscore
  end


  def to_record_viewable
    !!self.current_user.has_access_to?(:access, :table, to_record_type_us.pluralize)
  end

  def to_record_editable
    !!self.current_user.has_access_to?(:edit, :table, to_record_type_us.pluralize)
  end

  def from_record_type_us
    return unless from_record_type
    from_record_type.ns_underscore
  end

  def from_record_short_type_us
    return unless from_record_type
    from_record_type.split('::').last.ns_underscore
  end

  def from_record_viewable
    return unless from_record_type_us
    !!self.current_user.has_access_to?(:access, :table, from_record_type_us.pluralize)
  end

  def from_record
    return unless from_record_type && from_record_id
    from_record_type.ns_constantize.find(from_record_id)
  end

  def to_record_data
    to_record.data if to_record_viewable
  end

  def to_record
    return @to_record if @to_record
    @to_record = self.to_record_class.find(self.to_record_id)
  end

  def to_record_result_key
    if to_record.respond_to? :extra_log_type
      return "#{to_record_type_us}_#{to_record.extra_log_type}"
    end
    return to_record_type_us
  end

  def to_record_template
    if to_record.respond_to? :extra_log_type
      return "#{to_record_type_us}_#{to_record.extra_log_type}"
    end
    return to_record_short_type_us
  end

  def to_record_assoc
    to_record_class.assoc_inverse
  end

  def to_record= rec
    @to_record = rec
  end


  def to_record_options_config
    if from_record && from_record.respond_to?(:option_type_config)
      res = from_record.option_type_config.model_reference_config self
      return unless res
      res[to_record_assoc.to_s.singularize.to_sym]
    end
  end

  def self.find_records_in_master master: nil, to_record_type: nil, filter_by: nil
    res = []
    cond = {master: master}
    cond.merge! filter_by if filter_by

    to_record_class_for_type(to_record_type).where(cond).each do |i|
      # Instantiate temporary model reference objects to hold the results
      # They cannot be accidentally persisted, since the validations will fail
      rec = ModelReference.new from_record_master_id: master.id, to_record_type: to_record_type, to_record_id: i.id, to_record_master_id: i.master_id
      rec.to_record = i
      res << rec
    end

    res
  end

  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :to_record_id
    extras[:methods] << :to_record_master_id
    extras[:methods] << :to_record_type
    extras[:methods] << :to_record_type_us
    extras[:methods] << :to_record_short_type_us
    extras[:methods] << :to_record_label
    extras[:methods] << :to_record_viewable
    extras[:methods] << :to_record_editable

    extras[:methods] << :to_record_data

    extras[:methods] << :to_record_options_config if from_record.respond_to? :option_type_config
    extras[:methods] << :from_record_type_us
    extras[:methods] << :from_record_short_type_us
    extras[:methods] << :from_record_viewable
    extras[:methods] << :to_record_result_key
    extras[:methods] << :to_record_template

    # Don't return the full referenced object
    super(extras)
  end
end
