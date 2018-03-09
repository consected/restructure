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
  # If belonging to a master record, the to_record_type must be specified
  def self.find_references from_item_or_master, to_record_type: nil

    if to_record_type
      to_record_type = to_record_type.camelize

      # unless to_record_type.start_with? 'DynamicModel::'
        trtc = to_record_type.constantize
        # if trtc.name
        to_record_type = trtc.name
        # end
      # end
    end

    if from_item_or_master.is_a? Master
      res = ModelReference.find_records_in_master to_record_type: to_record_type, master: from_item_or_master
    else
      cond = {from_record_type: from_item_or_master.class.name, from_record_id: from_item_or_master.id}
      cond[:to_record_type] = to_record_type if to_record_type
      res = ModelReference.where cond
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
    self.current_user.has_access_to? :access, :table, to_record_type_us.pluralize
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
    self.current_user.has_access_to? :access, :table, from_record_type_us.pluralize
  end

  def to_record_data    
    to_record.data if to_record_viewable
  end

  def to_record
    return @to_record if @to_record
    rec_class = self.to_record_type.constantize
    @to_record = rec_class.find(self.to_record_id)
  end

  def to_record= rec
    @to_record = rec
  end

  def self.find_records_in_master master: nil, to_record_type: nil
    rec_class = to_record_type.camelize.constantize
    res = []
    rec_class.where(master: master).each do |i|
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

    extras[:methods] << :to_record_data

    extras[:methods] << :from_record_type_us
    extras[:methods] << :from_record_short_type_us
    extras[:methods] << :from_record_viewable

    # Don't return the full referenced object
    super(extras)
  end
end
